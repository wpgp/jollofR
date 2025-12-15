
#' @title spray1: Disaggregates population counts at high-resolution grid cells in the absence population and building counts - for one-level only
#'
#' @description This function disaggregates population estimates at grid cell levels using the building counts of each grid cell to first disaggregate the admin unit's
#' total population across the grid cells. Then, each grid cell's total count is further disaggregated into groups of interest using the admin's proportions.
#'
#' @param df A data frame object containing sample data (often partially observed) on different demographic groups population. It contains the admin's
#' total populatioin count to be disaggregated as well as other key variables as defined within the 'toydata'.
#'
#' @param rdf A gridded data frame object containing key information on the grid cells. Variables include the admin_id which must be identical to the one
#' in the admin level data. It contains GPS coordinates. i.e, longitude (lon) and Latitude (lat) of the grid cell's centroids.
#' @param  rclass This is a user-defined names of the files to be saved in the output folder.
#'
#' @param output_dir This is the directory with the name of the output folder where the
#' disaggregated population proportions and population totals are
#' automatically saved.
#'
#' @param class These are the categories of the variables of interest. For example, for educational level, it could be 'no education', 'primary education', 'secondary education', 'tertiary education'.
#'
#' @param verbose Logical. If TRUE, prints progress messages. Default is TRUE.
#'
#' @return A list of data frame objects of the output files including the disaggregated population proportions and population totals
#' along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic.
#' In addition, a file containing the model performance/model fit evaluation metrics is also produced.
#'
#'@examples
#'\donttest{
#'if (requireNamespace("INLA", quietly = TRUE)) {
#'  library(raster) # load relevant libraries
#'  library(dplyr)
#'  library(terra)
#'  data(toydata) # load toy data
#'
#'  # run 'cheesepop' admin unit disaggregation function
#'  result <- cheesepop(df = toydata$admin,output_dir = tempdir())
#'  class <- class <- names(toydata$admin %>% dplyr::select(starts_with("age_")))
#'  rclass <- paste0("TOY_population_v1_0_age",1:12)
#'
#'  # run spray1 grid cell disaggregation function
#'  result2 <- spray1(df = result$full_data, rdf = toydata$grid, class, rclass, output_dir = tempdir())
#'  ras2<- rast(paste0(output_dir = tempdir(), "/pop_TOY_population_v1_0_age4.tif"))
#'  plot(ras2) # visulize of the raster files produced
#'}
#'}
#'
#'@export
#'@importFrom dplyr "%>%"
#'@importFrom raster "rasterFromXYZ"
#'@importFrom grDevices "dev.off" "png"
#'@importFrom graphics "abline"
#'@importFrom stats "as.formula" "cor" "plogis"
#'@importFrom utils "write.csv"
#'
spray1 <- function (df, rdf, class, rclass, output_dir, verbose = TRUE)
{


  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message(paste("Directory", output_dir, "created successfully."))
  }
  else {
    message(paste("Directory", output_dir, "already exists."))
  }

  #df = result$full_data
  #rdf = toydata$grid
  # create age classes

  # define categorical classes
  cat_classes <- class

  prp_cat_classes <- paste0("prp_",cat_classes)
  prp_cat_classesL <- paste0("prp_",cat_classes, "L")
  prp_cat_classesU <- paste0("prp_",cat_classes, "U")
  pp_cat_classes <- paste0("pp_",cat_classes)


  cat_df <- df[,pp_cat_classes]
  cat_df$total <- apply(cat_df, 1, sum, na.rm=TRUE)

  # specify grids for all ages
  pred_dt <- pred_dtL <- pred_dtU <- matrix(0, ncol = length(cat_classes), nrow = nrow(rdf))
  prop_dt <- prop_dtL <- prop_dtU <- pred_dt

  for(i in df$admin_id){

    # i = 8
    dim(grid_df <- rdf[rdf$admin_id == i, ])
    tot <- cat_df$total[i]/nrow(grid_df) # total pop is divided equally across all the admin's grid cells
    ids <- which(rdf$admin_id == i)


    for (j in 1:length(cat_classes)) {

      # j = 4
      if(verbose) print(paste(paste0(cat_classes[j], " of admin ", i,
                         " is running")))

      #Grid disaggregation for all age groups
      prop_dt[ids, j] <- df[i, prp_cat_classes[j]]  # mean
      pred_dt[ids, j] <- round(prop_dt[ids, j]*tot, 2)

      prop_dtL[ids, j] <- df[i, prp_cat_classesL[j]] # lower
      pred_dtL[ids, j] <- round(prop_dtL[ids, j]*tot,2)

      prop_dtU[ids, j] <- df[i, prp_cat_classesU[j]] # upper
      pred_dtU[ids, j] <- round(prop_dtU[ids, j]*tot,2)

    }

  }


  # Rename columns
  # age pop
  cat_classes_pop = paste0("pp_", cat_classes)
  colnames(pred_dt) <- cat_classes_pop
  cat_classes_popL = paste0(cat_classes_pop, "L")
  colnames(pred_dtL) <- cat_classes_popL
  cat_classes_popU = paste0(cat_classes_pop, "U")
  colnames(pred_dtU) <- cat_classes_popU

  # age proportions
  cat_classes_prop = paste0("prp_", cat_classes)
  colnames(prop_dt) <- cat_classes_prop
  cat_classes_propL = paste0(cat_classes_prop, "L")
  colnames(prop_dtL) <- cat_classes_propL
  cat_classes_propU = paste0(cat_classes_prop, "U")
  colnames(prop_dtU) <- cat_classes_propU


  if(verbose) print("Writing raster files")
  # write the raster files

  ref_coords <- cbind(rdf$lon, rdf$lat) # the reference coordinates
  xx <- as.matrix(ref_coords)

  rclassL <- paste0(rclass,"L")# lower
  rclassU <- paste0(rclass,"U")# upper

  for(k in 1:length(rclass))
  {
    # k = 1
    # proportions --------------------------------------------------------------------
    #AGE
    z1a <- as.matrix(prop_dt[,k])
    h1a <- rasterFromXYZ(cbind(xx, z1a))
    writeRaster(h1a, filename=paste0(output_dir,"/prop_",rclass[k], ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z2a <- as.matrix(prop_dtL[,k])
    h2a <- rasterFromXYZ(cbind(xx, z2a))
    writeRaster(h2a, filename=paste0(output_dir,"/prop_",rclass[k], "_lower",".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z3a <- as.matrix(prop_dtU[,k])
    h3a <- rasterFromXYZ(cbind(xx, z3a))
    writeRaster(h3a, filename=paste0(output_dir,"/prop_",rclass[k],"_upper", ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    #--------------------------------------------------------------------------------
    # populations
    #--------------------------------------------------------------------------------
    #AGE
    z1b <- as.matrix(pred_dt[,k])
    h1b <- rasterFromXYZ(cbind(xx, z1b))
    writeRaster(h1b, filename=paste0(output_dir,"/pop_",rclass[k], ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z2b <- as.matrix(pred_dtL[,k])
    h2b <- rasterFromXYZ(cbind(xx, z2b))
    writeRaster(h2b, filename=paste0(output_dir,"/pop_",rclass[k], "_lower",".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z3b <- as.matrix(pred_dtU[,k])
    h3b <- rasterFromXYZ(cbind(xx, z3b))
    writeRaster(h3b, filename=paste0(output_dir,"/pop_",rclass[k],"_upper", ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

  }

  # Calculate fit metrics (evaluated at admin level)
  all_pop <- as.data.frame(pred_dt)
  all_pop <- cbind(rdf, all_pop)
  all_pop <-  all_pop %>% group_by(admin_id) %>%
    dplyr::summarise_at(cat_classes_pop, sum, na.rm=TRUE) %>%
    dplyr::select(-admin_id)




  all_pop$total <- round(apply(all_pop, 1, sum))
  png(paste0(output_dir, "/model_validation_scatter_plot.png"))
  plot(all_pop$total, df$total, xlab = "Observed population",
       ylab = "Predicted population", main = "Scatter plot of \n observed versus predicted")
  abline(0, 1, col = 2, lwd = 2)
  dev.off()
  residual = all_pop$total - df$total
  if(verbose) print(mets <- t(c(MAE = mean(abs(residual), na.rm = TRUE), MAPE = (1/length(df$total)) *
                      sum(abs((df$total - all_pop$total)/df$total)) * 100,
                    RMSE = sqrt(mean(residual^2, na.rm = TRUE)), corr = cor(df$total[!is.na(df$total)],
                                                                         all_pop$total[!is.na(df$total)]))))
  write.csv(mets, paste0(output_dir, "/fit_metrics.csv"),
            row.names = FALSE)

  #  combine the data outputs
  full_dat <- cbind(rdf,
                    pred_dt, pred_dtL, pred_dtU,
                    prop_dt, prop_dtL, prop_dtU)

  # save
  write.csv(full_dat, paste0(output_dir, "/full_disaggregated_data.csv"),
            row.names = FALSE)

  return(out <- list(full_data = data.frame(full_dat)))

}
