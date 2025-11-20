#' @title plotHist: Produces histogram of the disaggregated population counts across all groups
#'
#'@description This function produces a multi-panel histogram plot of the disaggregated population counts across all the groups.
#'The input data could come from any of the disaggregation functions within the 'jollofR' package (both at admin and grid levels) such as 'cheesecake', 'cheesepop', 'slices', etc.
#'
#'@param dmat A data frame containing the group-structured disaggregated population estimates which could either be observed or predicted from
#' 'cheesecake', 'cheesepop', 'slices','spices', 'spray' , 'sprinkle', 'splash', 'spray', 'sprinkle1', 'splash1', and 'spray1'.
#'
#'@param xlab A user-defined label for the x-axis (e.g., 'Population Count')
#' considered.
#'@param ylab A user-defined label for the y-axis (e.g., 'Frequency')
#' considered.
#'@return A graphic image of histogram of the disaggregated population count
#'
#'@examples
#'\donttest{
#'if (requireNamespace("INLA", quietly = TRUE)) {
#'  data(toydata)
#'  library(ggplot2)
#'  result <- cheesepop(df = toydata$admin,output_dir = tempdir())
#'  plotHist(dmat=result$age_pop,
#'           xlab="Population Count",
#'           ylab = "Frequency")
#'}
#'}
#'
#'@export
#'@importFrom dplyr "%>%"
#'@importFrom ggplot2 "ggplot"
#'@importFrom ggplot2 "aes"
#'@importFrom ggplot2 "geom_bar"
#'@importFrom ggplot2 "scale_y_continuous"
#'@importFrom ggplot2 "labs"
#'@importFrom ggplot2 "theme_minimal"
#'@importFrom ggplot2 "coord_flip"
#'@importFrom grDevices "dev.off" "png"
#'@importFrom graphics "abline"
#'@importFrom stats "as.formula" "cor" "plogis"
#'@importFrom utils "write.csv"
#'@importFrom reshape2 "melt"
#'

plotHist <- function(dmat, xlab, ylab)
{
classes <- names(dmat)
dmat_lng <- tidyr::gather(as.data.frame(dmat))
dmat_lng$key <- factor(dmat_lng$key,
                       levels=classes,
                       labels=classes)
levels(dmat_lng$key) <- gsub("pp.", "", classes)


dens_dist <- ggplot(dmat_lng, aes(x=value, color=key)) +
  geom_histogram(alpha=0.3,size=0.8)+
  theme_bw()+
  theme(strip.text = element_text(size=18))+
  facet_wrap(~key)
pdens_dist <- ggpubr::ggpar(dens_dist, ylab=ylab, xlab=xlab,
                            legend = "none", legend.title = "",size=18,
                            font.legend=c(18),
                            palette = "pnj",
                            font.label = list(size = 15, face = "bold", color ="red"),
                            font.x = c(18),
                            font.y = c(18),
                            font.main=c(18),
                            font.xtickslab =c(18),
                            font.ytickslab =c(18),
                            xtickslab.rt = 45
)
print(pdens_dist)

}
