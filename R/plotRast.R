#' @title plotRast: Produces multi-panel maps of the raster files of the grid-cell disaggregated structured population counts
#'
#'@description This function produces multi-frame maps of the raster files across the various demographic groups of interest.
#'The input data could come from any of the jolloR disaggregation functions at grid cell levels, e.g.,'sprinkle', 'spray', 'splash',
#''sprinkle1', 'spray1', 'and splash1',
#'
#'@param output_dir The raster files folder directory for the disaggregated population estimates
#'
#'@param names A user-defined names for the x-axis ticks labels.
#'@param nrow Number of rows of the multi-panel maps. The value depends on the number of groups being displayed.
#'@param ncol  Number of columns of the multi-panel maps. The value depends on the number of groups being displayed.
#'
#'@return A graphic image of multi-panel maps of population disaggregated raster files
#'
#'@examples
#'dontrun{data(toydata)
#' # run the appropriate function
#'result <- cheesepop(df = toydata$admin, output_dir) # run cheesepop or cheesecake
#'rclass <- paste0("TOY_population_v1_0_age",1:12) # specify the names of the raster files to be saved
#'class <- names(result$full_data %>% dplyr::select(starts_with("age_"))) # specify the raster files to visualise
#'output_dir <- paste0(out_path, "/raster/spray2") # set output directory
#'result2b <- spray(df=result$full_data, rdf=toydata$grid,
#'                 rclass, output_dir)
#' #make raster maps
#'   #- use below to see the list of raster files saved in the directory
#'list.files(output_dir, pattern = "\\.tif$", full.names = TRUE)
#'
#'group <- 1:12 # customised group #
#'raster_files <- paste0(tempdir(), "/pop_",paste0("TOY_population_v1_0_age",group), ".tif")
#'names <- paste0("Age ", group) # Customised names of the plot panels (same length as rclass)
#'nrow = 4; ncol = 3 # rows and columns of the panels of the output maps
# '             (the product of ncol and nrow must be greater than or equal to the number of files to be plotted)
#'plotRast(tempdir(), names, nrow, ncol)} # make the maps
#'@export
#'@importFrom dplyr "%>%"
#'@importFrom INLA "inla"
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


plotRast <- function(output_dir,names, nrow, ncol)
{
# Make raster plots in loops

# Initialize an empty SpatRaster object
raster_stack <- rast()

# Loop through the files and add them to the stack
for (file in raster_files) {
  raster_layer <- rast(file)
  raster_stack <- c(raster_stack, raster_layer)
}

names(raster_stack) <- names

plot_cval4 <- ggplot(raster_stack) +
  geom_raster(aes(fill = value)) +
  scale_fill_viridis_c() +
  coord_equal()+
  theme_bw()+
  theme(strip.text = element_text(size = 15),
        axis.text.x=element_text(size=15),
        axis.text.y=element_text(size=15),
        legend.title=element_text(size=15),
        legend.text=element_text(size=14))+
  facet_wrap(~ variable, nrow = nrow, ncol = ncol)


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

#library(terra)
#library(rasterVis)



# path
#path <- "C:/Users/ccn1r22/OneDrive - University of Southampton/Documents/packages/main/jollofR_scripts" # main directory
#out_path <- paste0(path, "/output")
# install.packages("jollofR")
#source(paste0(path, "/sprinkle.R")) #disaggregates population based on the grid pop count
#source(paste0(path, "/splash.R")) #disaggregates population based on the grid building count
#source(paste0(path, "/spray.R")) #disaggregates population by area-weighting


# load in put data
#load("C:/Users/ccn1r22/OneDrive - University of Southampton/Documents/packages/jollofR/data/toydata.RData")


# run cheepop, or cheesecake, or slice or spice
#result <- cheesecake(df = toydata$admin,out_path)
#pyramid(result$fem_age_pop,result$male_age_pop)

#classes <- names(toydata$admin %>% dplyr::select(starts_with("age_")))# Diaggregate by age
#result <- slices(df = toydata$admin, output_dir = tempdir(), class = classes)

# run either sprinkle, splash, spray or sprinke1, spray1, and spalsh1
#rclass <- paste0("NGA_population_v1_0_age",1:12)
#class <- names(result$full_data %>% dplyr::select(starts_with("age_")))
#output_dir <- paste0(out_path, "/raster/spray2")
#result2b <- spray(df=result$full_data, rdf=toydata$grid,
  #                   rclass, output_dir)

# make raster maps
#list.files(output_dir, pattern = "\\.tif$", full.names = TRUE) #- use this to see the list of raster files in the directory
#group <- 1:12 # customised group
#raster_files <- paste0(output_dir, "/pop_",paste0("NGA_population_v1_0_age",group), ".tif")
#names <- paste0("Age ", group) # Customised names of the plot panels (same length as rclass)
#nrow = 4; ncol = 3 # rows and columns of the panels of the output maps
#               (the product of ncol and nrow must be greater than or equal to the number of files to be plotted)
#plotRast(output_dir, names, nrow, ncol)

