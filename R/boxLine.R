#' @title boxLine: Produces  two graphs - boxplots of disaggregated population counts across groups and a line plot showing the distribution of the
#' aggregated totals of the disaggregated counts
#'
#'@description This function automatically generates two graphs that are combined together - (a) a boxplot  of the distribution of the various groups'
#'disaggregated population counts, and (b) a line graph of the aggregated counts across all groups (e.g., total number of individuals for each group).
#'Here, the input data could come from any of the disaggregation functions within the 'jollofR' package such as 'cheesecake', 'cheesepop', 'slices' & 'spices'.
#'
#'@param dmat A data frame containing the group-structured disaggregated population estimates which could be observed or from modelled estimates based on any of the functions -
#' cheesecake', 'cheesepop', 'slices','spices', 'spray' , 'sprinkle', 'splash', 'spray', 'sprinkle1', 'splash1', or 'spray1'.
#' considered.
#'
#'@param xlab A user-defined label for the x-axis (e.g., 'Age group').
#'@param ylab A user-defined label for the y-axis (e.g., 'Population count').
#'@return A graphic image of two combined graphs - a boxplot and a line plot showing the distribution of the disaggregated  population counts across the groups.
#'
#'@examples
#'\donttest{
#'if (requireNamespace("INLA", quietly = TRUE)) {
#'  library(ggplot2)
#'  data(toydata)
#'  result <- cheesepop(df = toydata$admin,output_dir = tempdir())
#'  boxLine(dmat=result$male_age_pop,
#'          xlab="Age group (years)",
#'          ylab = "Population Count")
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


boxLine <- function(dmat, xlab, ylab)
{
classes <- names(dmat)
dmat_lng <- tidyr::gather(as.data.frame(dmat))
dmat_lng$key <- factor(dmat_lng$key,
                         levels=classes,
                         labels=classes)
levels(dmat_lng$key) <- gsub("pp.", "", classes)

plt_box <- ggplot(dmat_lng, aes(y=value, x=key, col = key)) +
  geom_boxplot(fill="grey")+
  theme_minimal()


page_box <- ggpubr::ggpar(plt_box , xlab=xlab, ylab=ylab,
                  legend = "none", legend.title = "",size=22,
                  font.legend=c(18),
                  palette = "",
                  font.label = list(size = 15, face = "bold", color ="red"),
                  font.x = c(22),
                  font.y = c(20),
                  font.main=c(18),
                  font.xtickslab =c(18),
                  font.ytickslab =c(18),
                  xtickslab.rt = 45
)
page_box

# Make line graph
total <- apply(dmat, 2, sum)
tot_dat <- data.frame(Population = total,
                      Key = 1:length(classes),
                      label = levels(dmat_lng$key))


plt_line <- ggplot(tot_dat, aes(y=Population, x=Key)) +
  geom_line(size=1)+
  scale_x_continuous(breaks = seq(1, length(classes),
                                  by =1), labels =levels(dmat_lng$key))+
  theme_bw()
page_line <- ggpubr::ggpar(plt_line , xlab=xlab, ylab=ylab,
                          legend = "none", legend.title = "",size=22,
                          font.legend=c(18),
                          palette = "pnj",
                          font.label = list(size = 15, face = "bold", color ="red"),
                          font.x = c(22),
                          font.y = c(20),
                          font.main=c(18),
                          font.xtickslab =c(18),
                          font.ytickslab =c(18),
                          xtickslab.rt = 45
)
page_line


print(ggpubr::ggarrange(page_box,
                        page_line,
                        labels = c("(a)","(b)"),
                        nrow=2, ncol=1))
}

