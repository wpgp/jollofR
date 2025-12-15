
#' @title spices: Disaggregates population counts for a single level of demographics
#' (e.g., age groups only or sex group only) with covariates.
#'
#' @description This function disaggregates population estimates by a single demographic (age or sex or religion, etc)
#'
#' @param df A data frame object containing sample data (often partially observed) on age or sex groups population data
#' as well as the estimated overall total counts per administrative unit.
#'
#' @param output_dir This is the directory with the name of the output folder where the
#' disaggregated population proportions and population totals are
#' automatically saved.
#'
#' @param class This are the categories of the variables of interest. For example, for educational level, it could be 'no education', 'primary education', 'secondary education', 'tertiary education'.
#'
#' @param verbose Logical. If TRUE (default), progress messages are displayed during model execution.
#' Set to FALSE to suppress informational messages.
#'
#' @return A list of data frame objects of the output files including the disaggregated population proportions and population totals
#' along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic.
#' In addition, a file containing the model performance/model fit evaluation metrics is also produced.
#'
#'@examples
#'\donttest{
#'if (requireNamespace("INLA", quietly = TRUE)) {
#'  data(toydata)
#'  library(dplyr)
#'  classes <- names(toydata$admin %>% dplyr::select(starts_with("age_")))
#'  result2 <- spices(df = toydata$admin, output_dir = tempdir(), class = classes)
#'}
#'}
#'@export
#'@importFrom dplyr "%>%"
#'@importFrom stats "sd"
#'@importFrom utils "capture.output"
#'@importFrom grDevices "dev.off" "png"
#'@importFrom graphics "abline"
#'@importFrom stats "as.formula" "cor" "plogis"
#'@importFrom utils "write.csv"
#'
spices <-function(df, output_dir, class, verbose = TRUE)# disaggregates by age only - with covariates
{

  # Check if the output directory exists, if not, create it
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message(paste("Directory", output_dir, "created successfully."))
  } else {
    message(paste("Directory", output_dir, "already exists."))
  }

  # Partially observed age data
  #  class <- names(dat1 %>% select(starts_with("age_")))
  cat_df <- df[,class]
  pred_dt <- prop_dt <- cat_df
  pred_dtL <- prop_dtL <- cat_df
  pred_dtU <- prop_dtU <- cat_df


  cat_classes <- names(cat_df)
  # Add the total population to the age data
  cat_df$total <- apply(cat_df, 1, sum)
  cat_df$total[cat_df$total==0] = NA

  cat_df$pop <- df$total
  cat_df$set_typ <- df$set_typ
  cat_df$ID <- 1:nrow(cat_df) # add IID


  # covariates
  covs <- df %>% dplyr::select(starts_with("x"))

  # standardize covariates
  stdize <- function(x)
  {
    stdz <- (x - mean(x, na.rm=TRUE))/sd(x, na.rm=TRUE)
    return(stdz)
  }

  covs <- data.frame(apply(covs, 2, stdize))
  cov_names <- names(covs)# extract covariates names

  cat_df <- cbind(cat_df, covs) # add covariates to the age data


  for(i in 1:length(cat_classes))
  {
    # i = 1
    # 1) Disaggregate by age - estimate missing age group proportion for each admin unit
    prior.prec <- list(prec = list(prior = "pc.prec",
                                   param = c(1, 0.01))) # using PC prior
    if(verbose) message(paste(paste0("(",i,")"),paste0(cat_classes[i], " model is running")))

    cat_df[,colnames(cat_df)[i]] <- round(cat_df[,i])

    form_cat <- as.formula(paste0(colnames(cat_df)[i], " ~ 1 + f(ID, model = 'iid', hyper = prior.prec) +
                                  f(set_typ, model = 'iid', hyper = prior.prec) + ", # settlement type
                                  paste(cov_names, collapse = " + ")))


    if (requireNamespace("INLA", quietly = TRUE)) {
      mod_cat  <- INLA::inla(form_cat,
                             data = cat_df,
                             family = "binomial", Ntrials = total,
                             control.predictor = list(compute = TRUE),
                             control.compute = list(dic = TRUE, cpo = TRUE)
      )

    } else {
      stop("The 'INLA' package is required but not installed. Please install it from https://www.r-inla.org.")
    }
    # Save fixed and random effects estimates for each group
    parameter_dir <- paste0(output_dir, "/fixed_and_random_effects/",cat_classes[i])
    if (!dir.exists(parameter_dir)) {
      dir.create(parameter_dir, recursive = TRUE)
      message(paste("Directory", parameter_dir, "created successfully."))
    }
    else {
      message(paste("Directory", parameter_dir, "already exists."))
    }
    capture.output(summary(mod_cat), file = paste0(parameter_dir, "/posterior_estimates.txt"))


    prop_dt[,i] = round(plogis(mod_cat$summary.linear.predictor$mean),7)
    prop_dtL[,i] = round(plogis(mod_cat$summary.linear.predictor$'0.025quant'),7)
    prop_dtU[,i] = round(plogis(mod_cat$summary.linear.predictor$'0.975quant'),7)

    pred_dt[,i] = round(prop_dt[,i]*cat_df$pop)
    pred_dtL[,i] = round(prop_dtL[,i]*cat_df$pop)
    pred_dtU[,i] = round(prop_dtU[,i]*cat_df$pop)
    # summary(mod_cat)
  }

  ## Rename Columns
  # age combined
  # count
  cat_classes_pop = paste0("pp_",cat_classes)
  colnames(pred_dt) <- cat_classes_pop # predicted population counts
  cat_classes_popL = paste0(cat_classes_pop,"L")
  colnames(pred_dtL) <- cat_classes_popL # lower bound of predicted population counts
  cat_classes_popU = paste0(cat_classes_pop,"U")
  colnames(pred_dtU) <- cat_classes_popU # upper bound of predicted population counts

  # proportion
  cat_classes_prop = paste0("prp_",cat_classes)
  colnames(prop_dt) <- cat_classes_prop # predicted population counts
  cat_classes_propL = paste0(cat_classes_prop,"L")
  colnames(prop_dtL) <- cat_classes_propL # lower bound of predicted population counts
  cat_classes_propU = paste0(cat_classes_prop,"U")
  colnames(prop_dtU) <- cat_classes_propU # upper bound of predicted population counts



  ## predictive ability checksall_prop <- f.prop_dt + m.prop_dt # should be a matrix of 1s only!
  all_pop <- apply(pred_dt, 1, sum)# NO NA

  png(paste0(output_dir,"/model_validation_scatter_plot.png"))
  plot(all_pop, df$total,
       xlab="Observed population", ylab = "Predicted population",
       main= "Scatter plot of \n observed versus predicted")
  abline(0,1, col=2, lwd=2) # should be a straight perfect fit
  dev.off()


  residual = all_pop-df$total
  if(verbose) print(mets <- t(c(MAE = mean(abs(residual), na.rm=TRUE),#MAE
                    MAPE = (1/length(df$total))*sum(abs((df$total-all_pop)/df$total))*100,#MAPE
                    RMSE = sqrt(mean(residual^2, na.rm=TRUE)),
                    corr = cor(df$total[!is.na(df$total)],all_pop[!is.na(df$total)]))))# should be with at least 95% correlation

  write.csv(t(mets), paste0(output_dir,"/fit_metrics.csv"),row.names = FALSE)

  # join all data
  full_dat <- cbind(df,
                    prop_dt, prop_dtL,prop_dtU,
                    pred_dt, pred_dtL,pred_dtU) # everything

  # save the datasets
  write.csv(full_dat, paste0(output_dir,"/full_disaggregated_data.csv"),row.names = FALSE)
  write.csv(pred_dt, paste0(output_dir,"/cat_disaggregated_data.csv"),row.names = FALSE)
  write.csv(prop_dt, paste0(output_dir,"/cat_proportions.csv"),row.names = FALSE)


  # return output as a list
  return(out <- list(cat_pop = pred_dt,
                     cat_popL = pred_dtL,
                     cat_popU = pred_dtU,
                     cat_prop = prop_dt,
                     full_data = full_dat))

}
