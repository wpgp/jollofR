#' @title pyramid: Produces population pyramid (graphs) of demographics (for cheesecake and cheesepop age-sex output data)
#'
#'@description This function creates population pyramid for age and sex output data from the 'cheesecake' or
#' 'cheesepop' functions outputs. It could also be used to visualize observed age-sex compositions.
#'

#'@param female_pop A data frame containing the disaggregated population estimates for females across all ages groups.
#'
#'@param male_pop A data frame containing the disaggregated population estimates for males across all ages groups.
#'
#'@return A graphic image of age-sex population distribution pyramid
#'
#'@examples
#'\donttest{
#'if (requireNamespace("INLA", quietly = TRUE)) {
#'  data(toydata)
#'  result <- cheesecake(df = toydata$admin, output_dir = tempdir())
#'  pyramid(result$fem_age_pop,result$male_age_pop)
#'}
#'}
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

# Prepare data for age-sex pyramids
pyramid <- function(female_pop, male_pop)
{

  f_mat <- female_pop#age_dis$fem_age_pop
  age_classes <- names(f_mat)
  f_mat$id <- 1:nrow(f_mat)
  (female_pop <- reshape2::melt(f_mat, id=c("id"), value.name="Population",
                      variable.name="Age"))
  female_pop$Age <- factor(female_pop$Age)
  levels(female_pop$Age) <- gsub("pp_fage_", "", age_classes)
  female_pop$Gender <- rep("Female", nrow(female_pop))# create gender variable


  ### male data
  # mean
  m_mat <- male_pop
  age_classes <- names(m_mat)
  m_mat$id <- 1:nrow(m_mat)
  (male_pop <- reshape2::melt(m_mat, id=c("id"), value.name="Population",
                    variable.name="Age"))
  male_pop$Age <- factor(male_pop$Age)
  levels(male_pop$Age) <- gsub("pp_mage_", "", age_classes)
  male_pop$Gender <- rep("Male", nrow(male_pop))# create gender variable


  # combine both datasets
  dim(pop_pyramid <- rbind(female_pop, male_pop)) # mean

  # Create the age-sex population pyramid
  # national - mean
  population_pyramid1  <-  ggplot(
    pop_pyramid,
    aes(
      x = Age,
      fill = Gender,
      y = ifelse(
        test = Gender == "Male",
        yes = -Population,
        no = Population
      )
    )
  ) +
    geom_bar(stat = "identity") +
    scale_y_continuous(
      labels = abs
    ) +
    labs(
      x = "Age",
      y = "Population",
      fill = "Gender"#,
    ) +
    theme_minimal() +
    coord_flip()

  pyramid1 <- ggpubr::ggpar(population_pyramid1, ylab="Population Count", xlab="Age (years)",
                    legend = "right", legend.title = "Gender",size=22,
                    font.legend=c(16),
                    palette = "lancet",
                    font.label = list(size = 15, face = "bold", color ="red"),
                    font.x = c(16),
                    font.y = c(16),
                    font.main=c(14),
                    font.xtickslab =c(14),
                    font.ytickslab =c(16)#,
                    # orientation = "reverse",
                    #xtickslab.rt = 45, ytickslab.rt = 45
  )
  print(pyramid1)
  invisible(pyramid1)

}

#female_pop <- age_dis$fem_age_pop
#male_pop <- age_dis$male_age_pop
#pyramid(female_pop, male_pop)
