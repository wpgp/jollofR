% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotHist.R
\name{plotHist}
\alias{plotHist}
\title{plotHist: Produces histogram of the disaggregated population counts across all groups}
\usage{
plotHist(dmat, xlab, ylab)
}
\arguments{
\item{dmat}{A data frame containing the group-structured disaggregated population estimates which could either be observed or predicted from
'cheesecake', 'cheesepop', 'slices','spices', 'spray' , 'sprinkle', 'splash', 'spray', 'sprinkle1', 'splash1', and 'spray1'.}

\item{xlab}{A user-defined label for the x-axis (e.g., 'Population Count')
considered.}

\item{ylab}{A user-defined label for the y-axis (e.g., 'Frequency')
considered.}
}
\value{
A graphic image of histogram of the disaggregated population count
}
\description{
This function produces a multi-panel histogram plot of the disaggregated population counts across all the groups.
The input data could come from any of the disaggregation functions within the 'jollofR' package (both at admin and grid levels) such as 'cheesecake', 'cheesepop', 'slices', etc.
}
\examples{

data(toydata)
library(ggplot2)
result <- cheesepop(df = toydata$admin,output_dir = tempdir())
plotHist(dmat=result$age_pop,
        xlab="Population Count",
        ylab = "Frequency")

}
