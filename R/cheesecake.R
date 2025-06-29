#' @title cheesecake: Population disaggregation by two-level demographic groups (eg., age and sex), with covariates
#'
#' @description Used to disaggregate small area population estimates by age, sex, and
#' other socio-demographic or socio-economic characteristics (e.g., ethnicity, religion, educational level, immigration status, etc).
#'
#' It uses Bayesian hierachical statistical models to predict population proportions and population totals across demographic groups.
#' Primarily designed to support users (e.g., National Statistical Offices) in filling population data gaps across various demographic groups due to outdated or incomplete census/population data.
#'
#' @param df A data frame object containing sample data (often partially observed) on age and sex groups population data, for example,
#' as well as the overall total population counts per administrative unit.
#'
#' @param output_dir This is the directory with the name of the output folder where the
#' disaggregated population proportions and population totals are
#' automatically saved.
#'
#' @return A list of data frame objects of the output files including the disaggregated population proportions and population totals
#' along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic.
#' In addition, a file containing the model performance/model fit evaluation metrics is also produced.
#'
#'@examples
#'data(toydata)
#' result <- cheesecake(df = toydata$admin, output_dir = tempdir())
#'@export
#'@importFrom dplyr "%>%"
#'@importFrom stats "sd"
#'@importFrom utils "capture.output"
#'@importFrom grDevices "dev.off" "png"
#'@importFrom graphics "abline"
#'@importFrom stats "as.formula" "cor" "plogis"
#'@importFrom utils "write.csv"
#'
cheesecake <- function(df, output_dir)# disaggregates by age and sex - no covariates
{

  # Check if the output directory exists, if not, create it
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message(paste("Directory", output_dir, "created successfully."))
  } else {
    message(paste("Directory", output_dir, "already exists."))
  }

  # df = dat1

  # Partially observed age data
  age_df <- df %>% dplyr::select(starts_with("age_"))
  pred_dt <- prop_dt <- age_df
  pred_dtL <- prop_dtL <- age_df
  pred_dtU <- prop_dtU <- age_df


  age_classes <- names(age_df)

  # Add the total population to the age data
  age_df$total <- apply(age_df, 1, sum)
  age_df$total[age_df$total==0] = NA
  age_df$set_typ <- df$set_typ
  age_df$pop <- df$total



  # females age data
  f_dat <- df %>% dplyr::select(starts_with("fage_"))
  fage_classes <- names(f_dat) # age classes for females
  mage_classes <- gsub("f", "m", fage_classes) # age classes for males



  f.pred_dt <- f.prop_dt <-m.pred_dt <- m.prop_dt <- f_dat
  f.pred_dtL <- f.prop_dtL <-m.pred_dtL <- m.prop_dtL <- f_dat
  f.pred_dtU <- f.prop_dtU <-m.pred_dtU <- m.prop_dtU <- f_dat
  f_dat$ID <- 1:nrow(f_dat) # add IID

  age_df$ID <- 1:nrow(age_df) # add IID


  # covariates
  covs <- df %>% dplyr::select(starts_with("x"))

  # standardize covariates
  stdize <- function(x)
  {
    stdz <- (x - mean(x, na.rm=T))/sd(x, na.rm=T)
    return(stdz)
  }

  covs <- data.frame(apply(covs, 2, stdize))
  cov_names <- names(covs)# extract covariates names

  age_df <- cbind(age_df, covs) # add covariates to the age data

  for(i in 1:length(age_classes))
  {

    # 1) Disaggregate by age - estimate missing age group proportion for each admin unit
    prior.prec <- list(prec = list(prior = "pc.prec",
                                   param = c(1, 0.01))) # using PC prior
    print(paste(paste0("(",i,")"),paste0(age_classes[i], " model is running")))

    age_df[,colnames(age_df)[i]] <- round(age_df[,i])

    form_age <- as.formula(paste0(colnames(age_df)[i], " ~ 1 + f(ID, model = 'iid', hyper = prior.prec) +
                                  f(set_typ, model = 'iid', hyper = prior.prec) +", # settlement type
                                  paste(cov_names, collapse = " + ")))

    if (requireNamespace("INLA", quietly = TRUE)) {
      mod_age  <- INLA::inla(form_age,
                             data = age_df,
                             family = "binomial", Ntrials = total,
                             control.predictor = list(link=1, compute = TRUE),
                             control.compute = list(dic = TRUE, cpo = TRUE)
      )

   } else {
      stop("The 'INLA' package is required but not installed. Please install it from https://www.r-inla.org.")
    }

    # Save fixed and random effects estimates for each group
    parameter_dir <- paste0(output_dir, "/fixed_and_random_effects/",age_classes[i])
    if (!dir.exists(parameter_dir)) {
      dir.create(parameter_dir, recursive = TRUE)
      message(paste("Directory", parameter_dir, "created successfully."))
    }
    else {
      message(paste("Directory", parameter_dir, "already exists."))
    }
    capture.output(summary(mod_age), file = paste0(parameter_dir, "/posterior_estimates.txt"))

    # extract posterior results
    # proportions
    prop_dt[,i] = round(plogis(mod_age$summary.linear.predictor$mean),4)
    prop_dtL[,i] = round(plogis(mod_age$summary.linear.predictor$'0.025quant'),4)
    prop_dtU[,i] = round(plogis(mod_age$summary.linear.predictor$'0.975quant'),4)

    # counts
    pred_dt[,i] = round(prop_dt[,i]*age_df$pop)
    pred_dtL[,i] = round(prop_dtL[,i]*age_df$pop)
    pred_dtU[,i] = round(prop_dtU[,i]*age_df$pop)



    # 2) Disaggregate by sex - estimate missing female age group proportion for each admin unit

    f_dat[,colnames(f_dat)[i]] <- round(f_dat[,i])
    form_sex <- as.formula(paste0(colnames(f_dat)[i], " ~ ",
                                  "1 +   f(ID, model = 'iid', hyper = prior.prec)"))# Adding the IID here

    if (requireNamespace("INLA", quietly = TRUE)) {
      mod_sex  <- INLA::inla(form_sex,
                             data = f_dat,
                             family = "binomial", Ntrials = age_df[,i],
                             control.predictor = list(link=1, compute = TRUE),
                             control.compute = list(dic = TRUE, cpo = TRUE)
      )

    } else {
      stop("The 'INLA' package is required but not installed. Please install it from https://www.r-inla.org.")
    }
    f.prop_dt[,i] = round(plogis(mod_sex$summary.linear.predictor$mean),4) # female proportion - mean
    m.prop_dt[,i] = 1- f.prop_dt[,i] # male proportion


    f.prop_dtL[,i] = round(plogis(mod_sex$summary.linear.predictor$'0.025quant'),4) # Not meaningful

    # please ignore uncertainties (lower and upper bounds estimates for the sex proportions only)
    m.prop_dtL[,i] = 1- f.prop_dtL[,i] # male proportion
    f.prop_dtU[,i] = round(plogis(mod_sex$summary.linear.predictor$'0.975quant'),4) # Not meaningful
    m.prop_dtU[,i] = 1- f.prop_dtU[,i] # male proportion


    f.pred_dt[,i] = round(f.prop_dt[,i]*pred_dt[,i])# female counts
    f.pred_dtL[,i] = round(f.prop_dt[,i]*pred_dtL[,i])# female counts - lower
    f.pred_dtU[,i] = round(f.prop_dt[,i]*pred_dtU[,i])# female counts  upper



    m.pred_dt[,i] = pred_dt[,i] - f.pred_dt[,i] # male cunts
    m.pred_dtL[,i] = pred_dtL[,i] - f.pred_dtL[,i] # male cunts
    m.pred_dtU[,i] = pred_dtU[,i] - f.pred_dtU[,i] # male cunts

  }

  ## Rename Columns
  # age combined
  # count
  age_classes_pop = paste0("pp_",age_classes)
  colnames(pred_dt) <- age_classes_pop # predicted population counts
  age_classes_popL = paste0(age_classes_pop,"L")
  colnames(pred_dtL) <- age_classes_popL # lower bound of predicted population counts
  age_classes_popU = paste0(age_classes_pop,"U")
  colnames(pred_dtU) <- age_classes_popU # upper bound of predicted population counts


  # proportion
  age_classes_prop = paste0("prp_",age_classes)
  colnames(prop_dt) <- age_classes_prop # predicted population counts
  age_classes_propL = paste0(age_classes_prop,"L")
  colnames(prop_dtL) <- age_classes_propL # lower bound of predicted population counts
  age_classes_propU = paste0(age_classes_prop,"U")
  colnames(prop_dtU) <- age_classes_propU # upper bound of predicted population counts


  # female
  # count
  fage_classes_pop = paste0("pp_",fage_classes)
  colnames(f.pred_dt) <- fage_classes_pop # predicted population counts
  fage_classes_popL = paste0(fage_classes_pop,"L")
  colnames(f.pred_dtL) <- fage_classes_popL # lower bound of predicted population counts
  fage_classes_popU = paste0(fage_classes_pop,"U")
  colnames(f.pred_dtU) <- fage_classes_popU # upper bound of predicted population counts


  # proportion
  fage_classes_prop = paste0("prp_",fage_classes)
  colnames(f.prop_dt) <- fage_classes_prop # predicted population proportion



  # Not meaningful, not used - please ignore
  fage_classes_propL = paste0(fage_classes_prop,"L")
  colnames(f.prop_dtL) <- fage_classes_propL
  fage_classes_propU = paste0(fage_classes_prop,"U")
  colnames(f.prop_dtU) <- fage_classes_propU


  # male
  #count
  mage_classes_pop = paste0("pp_",mage_classes)
  colnames(m.pred_dt) <- mage_classes_pop # predicted population counts
  mage_classes_popL = paste0(mage_classes_pop,"L")
  colnames(m.pred_dtL) <- mage_classes_popL # lower bound of predicted population counts
  mage_classes_popU = paste0(mage_classes_pop,"U")
  colnames(m.pred_dtU) <- mage_classes_popU # upper bound of predicted population counts

  # proportion
  mage_classes_prop = paste0("prp_",mage_classes)
  colnames(m.prop_dt) <- mage_classes_prop # predicted population proportion

  # Not meaningful, not used - please ignore
  mage_classes_propL = paste0(mage_classes_prop,"L")
  colnames(m.prop_dtL) <- mage_classes_propL #
  mage_classes_propU = paste0(mage_classes_prop,"U")
  colnames(m.prop_dtU) <- mage_classes_propU #


  ###

  ## predictive ability checksall_prop <- f.prop_dt + m.prop_dt # should be a matrix of 1s only!
  all_pop <- f.pred_dt + m.pred_dt
  all_pop$total <- apply(all_pop, 1, sum)# NO NA

  png(paste0(output_dir,"/model_validation_scatter_plot.png"))
  plot(all_pop$total, df$total,
       xlab="Observed population", ylab = "Predicted population",
       main= "Scatter plot of \n observed versus predicted")
  abline(0,1, col=2, lwd=2) # should be a straight perfect fit
  dev.off()


  # Calculate the model fit metrics
  # Calculate the model fit metrics
  residual = all_pop$total - df$total
  print(mets <- t(c(MAE = mean(abs(residual), na.rm=T),#MAE
                    MAPE = (1/length(df$total))*sum(abs((df$total-all_pop$total)/df$total))*100,#MAPE
                    RMSE = sqrt(mean(residual^2, na.rm=T)),
                    corr = cor(df$total[!is.na(df$total)],all_pop$total[!is.na(df$total)]))))# should be with at least 95% correlation

  write.csv(t(mets), paste0(output_dir,"/fit_metrics.csv"),row.names = F)

  # join all data
  full_dat <- cbind(df,
                    pred_dt, pred_dtL,pred_dtU,
                    prop_dt, prop_dtL,prop_dtU,
                    f.pred_dt,f.pred_dtL,f.pred_dtU,
                    f.prop_dt, m.prop_dt,
                    m.pred_dt, m.pred_dtL, m.pred_dtU) # everything

  # save the datasets
  write.csv(full_dat, paste0(output_dir,"/full_disaggregated_data.csv"),row.names = F)
  write.csv(pred_dt, paste0(output_dir,"/age_disaggregated_data.csv"),row.names = F)
  write.csv(f.pred_dt, paste0(output_dir,"/female_disaggregated_data.csv"),row.names = F)
  write.csv(m.pred_dt, paste0(output_dir,"/male_disaggregated_data.csv"),row.names = F)
  write.csv(f.prop_dt, paste0(output_dir,"/female_proportions.csv"),row.names = F)
  write.csv(m.prop_dt, paste0(output_dir,"/male_proportions.csv"),row.names = F)
  write.csv(prop_dt, paste0(output_dir,"/age_proportions.csv"),row.names = F)


  # return output as a list
  return(out <- list(age_pop = pred_dt,
                     age_popL = pred_dtL,
                     age_popU = pred_dtU,
                     age_prop = prop_dt,
                     fem_age_pop = f.pred_dt,
                     fem_age_prop = f.prop_dt,
                     male_age_pop = m.pred_dt,
                     male_age_prop = m.prop_dt,
                     full_data = full_dat))

}
