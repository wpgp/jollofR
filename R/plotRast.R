#' @title plotRast: Produces multi-panel maps of the raster files of the grid-cell disaggregated structured population counts
#'
#'@description This function produces multi-panel maps of the raster files across the various demographic groups of interest.
#'The input data could come from any of the jolloR disaggregation functions at grid cell levels, e.g.,'sprinkle', 'spray', 'splash',
#''sprinkle1', 'spray1', 'and splash1',
#'
#'@param title This is the title of the multi-panel maps of the gridded structured estimates
#'@param output_dir The directory for saving the raster files of the disaggregated population estimates
#'@param raster_files The names of the raster files to visualize. This must be the same as saved in the raster output folder
#'
#'@param names A user-defined names for the plot panels labels. For example, this could be the labels of different age groups.
#'It must be the same length as the 'raster_files'.
#'@param nrow Number of rows of the multi-panel maps. The value depends on the number of groups being displayed.
#'@param ncol  Number of columns of the multi-panel maps. The value depends on the number of groups being displayed.
#'For example, for 12 raster files the products of ncol and nrow must be at least 12.
#'
#'@return A graphic image of the multi-panel maps of population disaggregated raster files
#'
#'@examples
#'\donttest{
#'if (requireNamespace("INLA", quietly = TRUE)) {
#'  data(toydata)
#'  result <- cheesepop(df = toydata$admin,output_dir = tempdir())
#'  rclass <- paste0("TOY_population_v1_0_age",1:12)
#'  result2b <- spray(df=result$full_data, rdf=toydata$grid,
#'                    rclass, output_dir= tempdir())
#'
#'# make raster maps
#'         #list.files(output_dir, pattern = "\\.tif$",full.names = TRUE) #-
#'         #use this to see the list of raster files in the directory
#' group <- 1:12 # customised group
#' rclass <- paste0("TOY_population_v1_0_age",group)
#' plt1 <- plotRast(title = "Age disaggregated population counts", # title of the plot
#' output_dir = tempdir(), # directory where the raster files are saved
#' raster_files = paste0(output_dir=tempdir(), "/pop_",rclass, ".tif") , # raster files to plot
#' names = paste0("Age ", group),  # Customised names of the plot panels (same length as rclass)
#' nrow = 4, ncol =3)# rows and columns of the panels of the output maps
#' #ggsave(paste0(out_path, "/grid_maps.tif"),#plot = plt1, dpi = 300) - save in output folder
#'}
#'}
#'
#'
#'@export
#'@importFrom dplyr "%>%"
#'@importFrom ggplot2 "ggplot"
#'@importFrom ggplot2 "aes"
#'@importFrom ggplot2 "geom_bar"
#'@importFrom ggplot2 "scale_y_continuous"
#'@importFrom ggplot2 "labs"
#'@importFrom ggplot2 "theme_minimal"
#'@importFrom ggpubr "ggpar"
#'@importFrom ggplot2 "coord_flip"
#'@importFrom grDevices "dev.off" "png"
#'@importFrom graphics "abline"
#'@importFrom stats "as.formula" "cor" "plogis"
#'@importFrom utils "write.csv"
#'@importFrom terra "rast"
#'@importFrom reshape2 "melt"
#'

plotRast <- function(title, output_dir,raster_files,
                     names, nrow, ncol)
{
  # Initialize an empty SpatRaster object
  raster_stack <- rast()
  # Loop through the files and add them to the stack
  for (file in raster_files) {
    raster_layer <- rast(file)
    raster_stack <- c(raster_stack, raster_layer)
  }

  names(raster_stack) <- names
  raster_df <- as.data.frame(raster_stack, xy=TRUE)
  (raster_lng <- reshape2::melt(raster_df, id=c("x", "y"), value.name="Population",
                                variable.name="Key"))

  raster_lng$Key <- factor(raster_lng$Key)
  levels(raster_lng$Key) <- names
  # Create the raster plot
  plot_cval4 <- ggplot(raster_lng, aes(x = x, y = y, fill = Population)) +
    ggplot2::geom_tile() +  # Use tiles to create the raster effect
    ggplot2::scale_fill_viridis_c() +  # Color gradient
    labs(title = title) +
    ggplot2::coord_equal()+
    ggplot2::theme_bw()+
    ggplot2::theme(strip.text = ggplot2::element_text(size = 15),
          axis.text.x=ggplot2::element_text(size=15),
          axis.text.y=ggplot2::element_text(size=15),
          legend.title=ggplot2::element_text(size=15),
          legend.text=ggplot2::element_text(size=14))+
    ggplot2::facet_wrap(~ Key, nrow = nrow, ncol = ncol)


  rcval4 <-  ggpubr::ggpar(plot_cval4, xlab="Longitude", ylab="Latitude",
                           legend = "right",
                           legend.title = "Population \n Count",size=20,
                           font.legend=c(15),
                           font.label = list(size = 15, face = "bold", color ="red"),
                           font.y = c(15),
                           font.x = c(15),
                           font.main=c(14),
                           font.xtickslab =c(14),
                           font.ytickslab =c(14),
                           xtickslab.rt = 45, ytickslab.rt = 45)
  print(rcval4)
}
