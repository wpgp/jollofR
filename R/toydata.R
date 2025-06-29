#' A list object containing two dataframes - an administrative-level dataset (admin) containing
#' partially observed age-sex structured data, and a grid-cell level dataset (grid) for population disaggregation at 1km by 1km grid cells.
#'
#' Artificially generated toy datasets that come in a cross-sectional
#' format. The 'admin' data is a dataframe collated at administrative unit level which contains information on the observed number of individuals per age and sex groups
#' within each administrative unit. Key variables include the administrative unit identifier (admin_id), the admin total population to be disaggregated (total), the total number
#' of buildings within each admin unit (bld), and the longitude (lon) and latitude (lat).
#' The 'admin' data provides artificial information for 900 spatially distinct administrative units in which the individuals in the population
#'are grouped into 12 mutually exclusive and exhaustive age groups. Each of the age groups was further grouped into 'male' and 'female' groups.
#' The data contains the total population counts (total) for each spatial unit but also contains missing age and sex groups population counts.
#' The model first predicts the population proportions of the missing data and then disaggregates the population totals using the predicted
#' proportions to obtain the predicted population counts for the age and sex groups. Note that the same applies for other demographic
#' groups such as marital status, race, etc.
#'
#' The second dataset in the toydata list is the 'grid' data which allows for the prediction of the age-sex structures
#' at 1km by 1km grid cells (note that population predictions can be made at any spatial resolution of interest). The 'grid' data  contains six key variables. These are
#' administrative unit identifier (admin_id) which must be identical to the those in the 'admin' data; the grid cell identifier (grd_id); the total number of people per
#' grid cell (total), if available; the total number of buildings per grid cell (bld), if available; and the longitude (lon) and latitude (lat) variables for the grid cell centroids.
#'
#' illustrate the use of the package.
#'
#' @docType data
#'
#' @usage data(toydata)
#'
#' @format An object of class \code{"list"}
#' \describe{
#'  \item{admin_id}{Available in both the 'admin' and 'grid' datasets. It is a numerical value which serves as the administrative units unique identifier.
#'  They should match perfectly for both the 'admin' and grid' datasets}
#'  \item{grd_id}{Available in the 'grid' dataset only. It is a numerical value which serves as the grid cell unique indentifier.}
#'  \item{x1,x2,x3}{These are the samples of geospatial covariates (only required for the 'cheesecake' and the 'slices' functions).
#'  Note that these are the covariates identified to significantly predict population distribution among
#'  the demographic groups. The package allows the user to include any number of covariates in their own datasets.}
#'  \item{total}{Available in both the 'admin' and 'grid' datasets. It provides estimates of the total population counts to be disaggregated.
#'  It DOES NOT necessarily have to be a rowsum of the age groups totals.}
#'  \item{bld}{Available in both the 'admin' and 'grid' datasets. It provides the total number of buildings in each grid cell or administrative unit. }
#'  \item{set_typ}{Administrative unit's settlement type classification (e.g., urban, rural).}
#'  \item{edu_no, edu_prim, edu_sec, edu_high}{These are the fully or partially observed number of people
#'  by the highest educational level of the household members. Here, edu_no = no education, edu_prim =
#'  primary education, edu_sec = secondary education, and edu_high = higher education.}
#'  \item{age_1, ..., age_12}{These correspond to the partially or fully observed number of people
#'  for each age group. Note that only 12 age groups are used here for illustration purposes,however,
#'  the package can accommodate any number of age or sex or any demographic groups.}
#'  \item{fage_1, ..., fage_12}{These correspond to the partially or fully observed number of females
#'  corresponding to each of the age groups. Note that only 12 age groups are used here for illustration purposes,however,
#'  the package can accommodate any number of age or sex or any demographic groups.}
#'   \item{mage_1, ..., mage_12}{These correspond to the partially or fully observed number of males
#'  corresponding to each of the age groups. Note that only 12 age groups are used here for illustration purposes,however,
#'  the package can accommodate any number of age or sex or any demographic groups.}
#'  \item{lon}{Available in both the 'admin' and 'grid' datasets. Provides the value of the longitude of the centroids of the grid cells or admin unit polygons.}
#'  \item{lat}{Available in both the 'admin' and 'grid' datasets. Provides the value of the latitude of the centroids of the grid cells or admin unit polygons.}
#' }
#' @references This data set was artificially created for the purpose of illustrations within the jollofR package.
#' @keywords datasets
#' @examples
#'
#' data(toydata)
#' head(toydata$admin)
#' head(toydata$grid)
#'
"toydata"
