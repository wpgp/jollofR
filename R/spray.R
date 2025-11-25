
#' @title Spray: Disaggregates population counts by dividing the admin total by the number of grid cells within the
#' administrative units. Then admin proportions are used to further disaggregate the grid cell totals by groups
#'
#' @description This function disaggregates population estimates at grid cell levels when there are no information on the building and population counts.
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
#' @param verbose Logical. If TRUE, prints progress messages. Default is TRUE.
#'
#' @return A list of data frame objects of the output files including the disaggregated population proportions and population totals
#' along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic.
#' In addition, a file containing the model performance/model fit evaluation metrics is also produced.
#'
#'@examples
#'\donttest{
#'if (requireNamespace("INLA", quietly = TRUE)) {
#'  # load relevant libraries
#'  library(raster)
#'  library(terra)
#'  # load toy data
#'  data(toydata)
#'  # run 'cheesepop' function for admin level disaggregation
#'  result <- cheesepop(df = toydata$admin,output_dir = tempdir())
#'  rclass <- paste0("TOY_population_v1_0_age",1:12) # Mean
#'  # run 'spray' for grid cell level disaggregation
#'  result2 <- spray(df = result$full_data, rdf = toydata$grid, rclass, output_dir = tempdir())
#'  ras2<- rast(paste0(output_dir = tempdir(), "/pop_TOY_population_v1_0_age4.tif"))
#'  plot(ras2) # visualize
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

spray <- function (df, rdf, rclass, output_dir, verbose = TRUE)
{

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message(paste("Directory", output_dir, "created successfully."))
  }
  else {
    message(paste("Directory", output_dir, "already exists."))
  }

  # df = result$full_data
  # rdf = toydata$grid

  # create age classes
  age_classes <- names(df %>% dplyr::select(starts_with("age_")))
  prp_age_classes <- paste0("prp_",age_classes)
  prp_age_classesL <- paste0("prp_",age_classes, "L")
  prp_age_classesU <- paste0("prp_",age_classes, "U")
  pp_age_classes <- paste0("pp_",age_classes)


  age_df <- df[, pp_age_classes]
  age_df$total <- apply(age_df, 1, sum, na.rm=TRUE)
  # create female age classes
  fage_classes <- names(df %>% dplyr::select(starts_with("fage_")))
  prp_fage_classes <- paste0("prp_",fage_classes)

  # create male age classes
  mage_classes <- names(df %>% dplyr::select(starts_with("mage_")))
  prp_mage_classes <- paste0("prp_",mage_classes)



  # specify grids for all ages
  pred_dt <- pred_dtL <- pred_dtU <- matrix(0, ncol = length(age_classes), nrow = nrow(rdf))
  prop_dt <- prop_dtL <- prop_dtU <- pred_dt

  # specify grids for females
  fpred_dt <- fpred_dtL <- fpred_dtU <- fprop_dt <- pred_dt

  # specify grids for males
  mpred_dt <- mpred_dtL <- mpred_dtU <- mprop_dt <- pred_dt


  for(i in df$admin_id){

    # i = 8
    dim(grid_df <- rdf[rdf$admin_id == i, ])
    tot <- age_df$total[i]/nrow(grid_df) # total pop is divided equally across all the admin's grid cells
    ids <- which(rdf$admin_id == i)


    for (j in 1:length(age_classes)) {

      if(verbose) print(paste(paste0("age class ", j, " of admin ", i,
                         " is running")))
      # j = 4
      #Grid disaggregation for all age groups
      prop_dt[ids, j] <- df[i, prp_age_classes[j]]  # mean
      pred_dt[ids, j] <- round(prop_dt[ids, j]*tot, 2)

      prop_dtL[ids, j] <- df[i, prp_age_classesL[j]] # lower
      pred_dtL[ids, j] <- round(prop_dtL[ids, j]*tot,2)

      prop_dtU[ids, j] <- df[i, prp_age_classesU[j]] # upper
      pred_dtU[ids, j] <- round(prop_dtU[ids, j]*tot,2)


      #Grid disaggregation for all male and female age groups
      # mean
      fprop_dt[ids, j] <- df[i, prp_fage_classes[j]]
      mprop_dt[ids, j] <- 1 - fprop_dt[ids, j]

      fpred_dt[ids, j] <- round(fprop_dt[ids, j]*pred_dt[ids, j],2)
      mpred_dt[ids, j] <- pred_dt[ids, j] - fpred_dt[ids, j]

      # lower
      fpred_dtL[ids, j] <- round(fprop_dt[ids, j]*pred_dtL[ids, j],2)
      mpred_dtL[ids, j] <- round(mprop_dt[ids, j]*pred_dtL[ids, j],2)

      # upper
      fpred_dtU[ids, j] <- round(fprop_dt[ids, j]*pred_dtU[ids, j],2)
      mpred_dtU[ids, j] <- round(mprop_dt[ids, j]*pred_dtU[ids, j],2)

    }

  }


  # Rename columns
  # age pop
  age_classes_pop = paste0("pp_", age_classes)
  colnames(pred_dt) <- age_classes_pop
  age_classes_popL = paste0(age_classes_pop, "L")
  colnames(pred_dtL) <- age_classes_popL
  age_classes_popU = paste0(age_classes_pop, "U")
  colnames(pred_dtU) <- age_classes_popU

  # age proportions
  age_classes_prop = paste0("prp_", age_classes)
  colnames(prop_dt) <- age_classes_prop
  age_classes_propL = paste0(age_classes_prop, "L")
  colnames(prop_dtL) <- age_classes_propL
  age_classes_propU = paste0(age_classes_prop, "U")
  colnames(prop_dtU) <- age_classes_propU

  # female age pop
  fage_classes_pop = paste0("pp_", fage_classes)
  colnames(fpred_dt) <- fage_classes_pop
  fage_classes_popL = paste0(fage_classes_pop, "L")
  colnames(fpred_dtL) <- fage_classes_popL
  fage_classes_popU = paste0(fage_classes_pop, "U")
  colnames(fpred_dtU) <- fage_classes_popU

  # female age prop
  fage_classes_prop = paste0("prp_", fage_classes)
  colnames(fprop_dt) <- fage_classes_prop

  # male age pop
  mage_classes_pop = paste0("pp_", mage_classes)
  colnames(mpred_dt) <- mage_classes_pop
  mage_classes_popL = paste0(mage_classes_pop, "L")
  colnames(mpred_dtL) <- mage_classes_popL
  mage_classes_popU = paste0(mage_classes_pop, "U")
  colnames(mpred_dtU) <- mage_classes_popU

  # male age  prop
  mage_classes_prop = paste0("prp_", mage_classes)
  colnames(mprop_dt) <- mage_classes_prop



  if(verbose) print("Writing age and age-sex raster files")
  # write the raster files
  ref_coords <- cbind(rdf$lon, rdf$lat) # the reference coordinates
  xx <- as.matrix(ref_coords)

  rclassL <- paste0(rclass,"L")# lower
  rclassU <- paste0(rclass,"U")# upper

  frclass <- gsub("_age", "_agesex_f",rclass) # for female age groups
  mrclass <- gsub("_age", "_agesex_m",rclass) # for male age groups
  for(k in 1:length(rclass))
  {
    # k = 1
    # proportions --------------------------------------------------------------------
    #AGE
    z1a <- as.matrix(prop_dt[,k])
    h1a <- rasterFromXYZ(cbind(xx, z1a))
    raster::writeRaster(h1a, filename=paste0(output_dir,"/prop_",rclass[k], ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z2a <- as.matrix(prop_dtL[,k])
    h2a <- rasterFromXYZ(cbind(xx, z2a))
    raster::writeRaster(h2a, filename=paste0(output_dir,"/prop_",rclass[k], "_lower",".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z3a <- as.matrix(prop_dtU[,k])
    h3a <- rasterFromXYZ(cbind(xx, z3a))
    raster::writeRaster(h3a, filename=paste0(output_dir,"/prop_",rclass[k],"_upper", ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    # SEX
    # FEMALE
    z4a<- as.matrix(fprop_dt[,k])
    h4a <- rasterFromXYZ(cbind(xx, z4a))
    raster::writeRaster(h4a, filename=paste0(output_dir,"/prop_",frclass[k],".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    # MALE
    z5a <- as.matrix(mprop_dt[,k])
    h5a <- rasterFromXYZ(cbind(xx, z5a))
    raster::writeRaster(h5a, filename=paste0(output_dir,"/prop_",mrclass[k], ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))
    #--------------------------------------------------------------------------------
    # populations
    #--------------------------------------------------------------------------------
    #AGE
    z1b <- as.matrix(pred_dt[,k])
    h1b <- rasterFromXYZ(cbind(xx, z1b))
    raster::writeRaster(h1b, filename=paste0(output_dir,"/pop_",rclass[k], ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z2b <- as.matrix(pred_dtL[,k])
    h2b <- rasterFromXYZ(cbind(xx, z2b))
    raster::writeRaster(h2b, filename=paste0(output_dir,"/pop_",rclass[k], "_lower",".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))


    z3b <- as.matrix(pred_dtU[,k])
    h3b <- rasterFromXYZ(cbind(xx, z3b))
    raster::writeRaster(h3b, filename=paste0(output_dir,"/pop_",rclass[k],"_upper", ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    # SEX
    # FEMALE
    z4b<- as.matrix(fpred_dt[,k]) # mean
    h4b <- rasterFromXYZ(cbind(xx, z4b))
    raster::writeRaster(h4b, filename=paste0(output_dir,"/pop_",frclass[k],".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    z4bL<- as.matrix(fpred_dtL[,k])
    h4bL <- rasterFromXYZ(cbind(xx, z4bL)) # lower
    raster::writeRaster(h4bL, filename=paste0(output_dir,"/pop_",frclass[k],"_lower",".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    z4bU<- as.matrix(fpred_dtU[,k])
    h4bU <- rasterFromXYZ(cbind(xx, z4bU)) # upper
    raster::writeRaster(h4bU, filename=paste0(output_dir,"/pop_",frclass[k],"_upper",".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    # MALE
    z5b <- as.matrix(mpred_dt[,k])
    h5b <- rasterFromXYZ(cbind(xx, z5b)) # mean
    raster::writeRaster(h5b, filename=paste0(output_dir,"/pop_",mrclass[k], ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    z5bL <- as.matrix(mpred_dtL[,k])
    h5bL <- rasterFromXYZ(cbind(xx, z5bL)) # lower
    raster::writeRaster(h5bL, filename=paste0(output_dir,"/pop_",mrclass[k],"_lower", ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))

    z5bU <- as.matrix(mpred_dtU[,k])
    h5bU <- rasterFromXYZ(cbind(xx, z5bU)) # upper
    raster::writeRaster(h5bU, filename=paste0(output_dir,"/pop_",mrclass[k],"_upper", ".tif"),
                overwrite=TRUE, options = c('COMPRESS' = 'LZW'))
  }


  # Calculate fit metrics (evaluated at admin level)
  all_pop <- as.data.frame(fpred_dt + mpred_dt)
  all_pop <- cbind(rdf, all_pop)
  all_pop <- all_pop %>% dplyr::group_by(admin_id) %>%
    dplyr::summarise_at(fage_classes_pop, sum, na.rm=TRUE)%>%
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
                    prop_dt, prop_dtL, prop_dtU,
                    fpred_dt, fpred_dtL, fpred_dtU,
                    mpred_dt, mpred_dtL, mpred_dtU)

  # save
  write.csv(full_dat, paste0(output_dir, "/full_disaggregated_data.csv"),
            row.names = FALSE)

  return(out <- list(full_data = data.frame(full_dat),
                     fem_age_pop = data.frame(fpred_dt),
                     male_age_pop = data.frame(mpred_dt)))

}
