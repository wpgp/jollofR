# 1. Background
**jollofR** version 0.3.0 is an R package that enables rapid disaggregation of small area population estimates into demographic groups such as age and sex groups as well as other socio-demographic and socio-economic categories (e.g., marital status, wealth indices, educationa level, race, etc). It facilitates the filling of important population data gaps especially across settings where census data are either outdated or incomplete. **jollofR** is based on advanced multi-steps Bayesian hierarchical statistical modelling approach which first estimates the proportions of each demographic group’s composition within the population of interest based on a (usually partially observed) sample data, and then uses it to disaggregate the total population estimate for each administrative unit within the population. Note that each administrative unit’s total population could come from census, Microcensus, household surveys or other sources.

This statistical model-based approach allows us to estimate population proportion and population counts across all the demographic units of interest including at locations with no observations within the the sample data. The use of Bayesian inference approach enables us to quantify uncertainties within these parameter estimates based on the 95% credible interval of the posterior probability. The posterior inference utilises the integrated nested Laplace approximation (INLA) strategies thereby leading to significantly high computational speed. Thus, the **jollofR** package provides a fast and efficient way to accurately disaggregate population counts by various demographic groups for evidence-based governance and more effective humanitarian response strategies. The package is designed to support population data producers and users as well as policymakers in providing timely spatially detailed small area population data, thereby making it a useful tool for filling population data gaps due to outdated or incomplete census enumerations.

The present version of **jollofR** automatically produces subnational age/sex pyramids (or other demographic groups such as ethnicity, wealth indices, etc), which could then be used to produce the associated high resolution age/sex gridded layers as a separate step (if required). However, the version of the package which simultaneously creates both the subnational demographically structured population counts and proportions as well as the corresponding high-resolution raster files within a robust statistical modelling framework is currently under development by the authors.

# 2. Installation


Here is a simple flow chart:

```mermaid
graph TD;
    A-->B;
    A-->C;
    B-->D;
    C-->D;
```
## System Requirements

Before installing **jollofR**, please ensure that your system meets the following requirements:
|   2   |
|------|
|   4   |


When $a \ne 0$, there are two solutions to $(ax^2 + bx + c = 0)$ and they are
$ x = {-b \pm \sqrt{b^2-4ac} \over 2a} $



1.  **R version**: \>= 4.1.0
3.  **INLA** (please check that you have INLA already installed)

### Platform-Specific Setup

### Windows

1.  Install Rtools (matches your R version):
``` r
# Check if Rtools is installed and properly configured
pkgbuild::has_build_tools()
```

If FALSE, download and install Rtools from: [CRAN Rtools](https://cran.r-project.org/bin/windows/Rtools/)

### macOS

1.  Install Command Line Tools:

```         
xcode-select --install
```

2.  Alternatively, install gcc via Homebrew:

```         
brew install gcc
```

### Linux (Ubuntu/Debian)

1.  Update your system and install necessary packages:

```         
sudo apt-get update
sudo apt-get install build-essential libxml2-dev
```

## Install from GitHub

Once the setup is complete, follow the instructions below to download **jollofR**. Note that the package is still under development. So, we will show you how to install the development version and how to install it once it becomes available on CRAN. 

First, you may need to install **INLA** by running the following codes (if you do not have INLA already installed)
```{r eval=FALSE, include=TRUE}
# install.packages("devtools")
install.packages("INLA", repos=c(getOption("repos"),
                                 INLA="https://inla.r-inla-download.org/R/stable"), dep=TRUE)
```
After confirming that **INLA** has been successfully installed, please install the development version of **jollofR** package from GitHub using the following codes: 
```{r eval=FALSE, include=TRUE}
# install.packages("devtools")
devtools::install_github("wpgp/jollofR")
```

## Install from CRAN
As soon as **jollofR** becomes available on CRAN, you can then install it directly from CRAN using the following:
```{r eval=FALSE, include=TRUE}
# install.packages("jollofR")
```

# 3. Workflow Overview
**jollofR** is designed to provide a very simple, efficient and statistically robust appraoch for providing disaggregated population counts across various demographic groups at operational admnistrative unit levels thus making it handy for the production of rapid demographically structured small area population counts. The **jollofR** package allows for population disaggregation with or without geospatial covariates. However, note that these geospatial covariates are those indentified apriori to significantly predict population distributions (functions which allow for wider range of geospatial covariates and automatically selects and retains the best fit covariates within the package are being developed by the authors). In all cases, estimates of uncertainties are also produced, and age-sex pyramid graphs are automatically generated for age-sex disaggregations. 

##  Initialise

As a first requirement, you will need to do the following: 1) ensure that you have **INLA** and **jollofR** packages installed; 2) create your output folder which is where all the model outputs (results) will be saved, and check to confirm that it works; 3) prepare your input data to ensure it conforms with the input data structure requirements (see the simple data format described within the **Preparing the input data** section). Once all the initial checks are completed (INLA & jollofR installed and working, input data prepared in the correct formats and structure), you are set to start! Please note that while R GUI could be used, RStudio is highly recommended as it makes it easier to monitor the progress of the computations. 

##  Creating output folder
This is where all the automatically produced outputs will be saved on your machine:
```r
output_dir <- "your output directory"
```
The package will create the folder if it does not already exist. 

##  Preparing the input data
The input data 'df' is a .csv file data frame which contains the key variables of the interest. The data is often a completely anonymized aggregated population data with the following fields:

-   **id**: a numeric variable used as the indentification number for each administrative unit (mandatory).

-   **x1, ..., xn**: n geospatial covariates identified for the covariates-based modelling, i.e., for population disaggregation using covariates. In the 'toydata' used as an example here, only 3 geospatial covariates x1, x2, x3 were used for the purpose of illustration only.
The package allows for as many covariates as possible in the model. However, please note that the use of covariates to disaggregate a model-based total population estimates, couls lead to circularity issues. Examples of these geospatial covariates include night time light intensity, distance to market, etc - mandatory if disaggregating based on covariates or optional if disaggregating without covariates.

-   **total**: an integer valued variable which contains the values to be disggregated. It is the total number of individuals per given administrative unit. Check to ensure that *total* has values across all the administrative unit of interest. You may wish to first predict all missing total values (mandatory).

-   **age_1, ....., age_n**: n age groups of interest containing observed population counts per age group per administrtaive unit. Note that *age_1, ....., age_n* can come from a sample survey, opportunistically generated data or from incomplete census data. **jollofR** predicts any missing age proportion, and the these are used to disaggregate the *total* population count. - *mandatory*

-   **fage_1, ....., fage_n**: n age groups of interest containing observed population counts per age group of females per administrtaive unit. Note that *fage_1, ....., fage_n* can come from a sample survey, opportunistically generated data or from incomplete census data. **jollofR** predicts any missing age proportion, and the these are used to disaggregate the *total* population count.- *mandatory*

-   **mage_1, ....., mage_n**: n age groups of interest containing observed population counts per age group of males per administrtaive unit. Note that *mage_1, ....., mage_n* can come from a sample survey, opportunistically generated data or from incomplete census data. **jollofR** predicts any missing age proportion, and the these are used to disaggregate the total population count.


# 4. Key functions and usage
## 'cheesecake'
### Description
Used to disaggregate small area population estimates by age, sex, and other socio-demographic and socio-economic characteristics (e.g., ethnicity, religion, educational level, immigration status, etc).

It uses statistical models to predict population proportions and population totals across demographic groups. Primarily designed to help users in filling population data gaps across demographic groups due to outdated or incomplete census.

### Usage
```r
result <- cheesecake(df, output_dir)
```
### Arguments
```
df	
A data frame object containing sample data (often partially observed) on age and sex groups population data as well as the estimated overall total counts per administrative unit.

output_dir	
This is the directory with the name of the output folder where the disaggregated population proportions and population totals are automatically saved.

Value
Data frame objects of the output files including the disaggregated population proportions and population totals along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic. In addition, a file containing the model performance/model fit evaluation metrics is also produced.
```

## 'cheesepop'	
### Description
Similar to the 'cheesecake' function, 'cheesepop' disaggregates small area population estimates by age, sex, and other socio-demographic and socio-economic characteristics (e.g., ethnicity, religion, educational level, immigration status, etc). However, unlike the 'cheesecake' function which uses geospatial covariates to predict missing data values, 'cheesepop' does not use covariates.
It uses Bayesian statistical models to predict population proportions and population totals across demographic groups. Primarily designed to help users in filling population data gaps across demographic groups due to outdated or incomplete census.

### Usage
```r
result <- cheesepop(df, output_dir)
```
### Arguments
```
df	
A data frame object containing sample data (often partially observed) on age and sex groups population data as well as the estimated overall total counts per administrative unit.

output_dir	
This is the directory with the name of the output folder where the disaggregated population proportions and population totals are automatically saved.

Value
Data frame objects of the output files including the disaggregated population proportions and population totals along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic. In addition, a file containing the model performance/model fit evaluation metrics is also produced.
```


## 'pyramid'
### Description
This function creates population pyramid based on the outputs from the '*cheesecake*' or '*cheesepop*' functions.

### Usage
```r
plot <- pyramid(female_pop, male_pop)
``` 
### Arguments
```
female_pop	
A data frame containing the disaggregated population estimates for females across all ages groups. considered.

male_pop	
A data frame containing the disaggregated population estimates for males across all ages groups. considered.

Value
Data frames of the diaggregated population numbers along with uncertainty for the age and sex groups or other demographic groups.
```


## 'spices'
### Description
This function disaggregates population estimates by a single demographic (age or sex or religion, etc) - with geospatial covariates. Please use the *slices* function if no covariates are required.

### Usage
```r
result <- spices(df, output_dir, class)
```
### Arguments
```
df	
A data frame object containing sample data (often partially observed) on age or sex groups population data as well as the estimated overall total counts per administrative unit.

output_dir	
This is the directory with the name of the output folder where the disaggregated population proportions and population totals are automatically saved.

class	
This a vector which provides the levels of the categorical demographic characteristics of interest. For example, for disaggregating population by educational level, class could be the vector containing the elements "no education", "primary education", "secondary education", "tertiary education", etc.

Value
Data frame objects of the output files including the disaggregated population proportions and population totals along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic. In addition, a file containing the model performance/model fit evaluation metrics is also produced.
```

## 'slices'	
### Description
This function disaggregates population estimates by a single demographic (age or sex or religion, etc) -  with no geospatial covariates. Please use *spices* if covariates are required.

### Usage
```r
result <- slices(df, output_dir, class)
```
### Arguments
```
df	
A data frame object containing sample data (often partially observed) on age or sex groups population data as well as the estimated overall total counts per administrative unit.

output_dir	
This is the directory with the name of the output folder where the disaggregated population proportions and population totals are automatically saved.

class	
This a vector which provides the levels of the categorical demographic characteristics of interest. For example, for disaggregating population by educational level, class could be the vector containing the elements "no education", "primary education", "secondary education", "tertiary education", etc.

Value
Data frame objects of the output files including the disaggregated population proportions and population totals along with the corresponding measures of uncertainties (lower and upper bounds of 95-percent credible intervals) for each demographic characteristic. In addition, a file containing the model performance/model fit evaluation metrics is also produced.
```


## 5. Toy data for illustration
Name: **toydata**	
### Description
Artificially generated toy data set that comes in a cross-sectional format where the unit of analysis is either administrative unit or enumeration area identifiable by an 'id' variable. 'It provides artificial information for 3,213 spatially distinct administrative units in which the individuals in the population are grouped into 12 mutually exclusive and exhaustive age groups. Each of the age groups was further grouped into 'male' and 'female' groups. The data contains the total population counts (total) for each spatial unit but also contains missing age and sex groups population counts. The model first predicts the population proportions of the mising data and then disaggregates the population totals using the predicted proportions to obtain the predicted population counts for the age and sex groups. Note that the same applies for other demographic groups such as marital status, race, etc. illustrate the use of the package.

### Usage
```r
data(toydata)
```
### Format

An object of class "data.frame"

- **id**: Administrative units ids (as numeric) for the administrative units of interest
  
- **x1,x2,x3**: These are the samples of geospatial covariates (only required for the 'cheesecake' and the 'slices' functions). Note that these are the covariates identified to significantly predict population distribution among the demographic groups. The package allows the user to include any number of covariates in thier own datasets.
  
- **total**: The total population counts being disaggregated (not necessarily equal to age groups row sums).
  
- **age_1, ..., age_12**: These correspond to the partially or fully observed number of people corresponding to each of the age groups. Note that we have used only 12 age groups here for illustration but the package can accomodate any number of age or sex or any demographic groups.
  
- **fage_1, ..., fage_12**: These correspond to the partially or fully observed number of females corresponding to each of the age groups. Note that we have used only 12 age groups here for illustration but the package can accomodate any number of age or sex or any demographic groups.
  
- **mage_1, ..., mage_12**: These correspond to the partially or fully observed number of males corresponding to each of the age groups. Note that we have used only 12 age groups here for illustration but the package can accomodate any number of age or sex or any demographic groups.


## 6. Examples: using jollofR functions
### cheesecake
```r
data(toydata)
result <- cheesecake(df = toydata, output_dir = tempdir())
```

### cheesepop
```r
data(toydata)
result <- cheesepop(df = toydata, output_dir = tempdir())
```

### pyramid
```r
data(toydata)
result <- cheesecake(df = toydata, output_dir = tempdir())
pyramid(result$fem_age_pop,result$male_age_pop)
```

### spices
```{r eval=TRUE, include=TRUE}
data(data/toydata.RData)
classes <- names(toydata %>% select(starts_with("age_")))
result2 <- spices(df = toydata, output_dir = tempdir(), class = classes)
```


### slices
```r
data(toydata)
classes <- names(toydata %>% select(starts_with("age_")))
result2 <- slices(df = toydata, output_dir = tempdir(), class = classes)
```


## 7. Model validation metrics
The **jollofR** package is a model-based approach which enables model validation by automatically computing model fit metrics based on the comparisons between the observed and the predicted values based on the age groups population disaggregation models. The computed metrics include:
```
- MAE: Mean Absolute Error
- MAPE: Mean Absolute Percentage Error
- RMSE: Root Mean Square Error
- corr: Pearson's Correlation Coefficient
```


## 8. The output files directly accessible using result$ 
**jollofR** automatically saves a number of output files as a list object. This contain 9 dataframes which can be accessed by running the function 'result$"name_of_the_dataframe", if the output object is called 'result' as in our example. These include:

- **age_pop**: This file contains the mean disaggregated population counts by age groups. This is obtained by running the function 'result$age_pop'
  
- **age_popL**: This file contains the lower bound (2.5%) of the 95% credible interval estimates of the disaggregated population counts by age groups. This is obtained by running the function 'result$age_popL'
  
- **age_popU**: This file contains the upper bound (97.5%) of the 95% credible interval estimates of the disaggregated population counts by age groups. This is obtained by running the function 'result$age_popU'
  
- **age_prop**: This file contains the mean disaggregated population proportions by age groups. This is obtained by running the function 'result$age_prop'
  
- **fem_age_pop**: This file contains the mean disaggregated population counts by female age groups. This is obtained by running the function 'result$fem_age_pop'
  
- **fem_age_prop**: This file contains the mean disaggregated population proportions by female age groups. This is obtained by running the function 'result$fem_age_prop'
  
- **male_age_pop**: This file contains the mean disaggregated population counts by male age groups. This is obtained by running the function 'result$male_age_pop'
  
- **male_age_prop**: This file contains the mean disaggregated population proportions by male age groups. This is obtained by running the function 'result$male_age_prop'
  
- **full_data**: This file contains both the input datasets and the predicted estimates. This is obtained by running the function 'result$full_data'
  


## 9. The output files saved in your output folder 
**jollofR** automatically saves 8 .csv files and 1 .png file in the output folder you specified. These include:

- **age_disaggregated_data.csv**: This file contains the mean disaggregated population counts by age groups. Variables are written as "pp_age_1, ....,pp_age_n" within the .csv file, where n is the last age group category.
  
- **age_proportions.csv**: This file contains the mean disaggregated population proportions by age groups. Variables are written as "prp_age_1, ....,prp_age_n" within the .csv file, where n is the last age group category.
  
- **female_disaggregated_data.csv**: This file contains the mean disaggregated population counts by female age groups. Variables are written as "pp_fage_1, ....,pp_fage_n" within the .csv file, where n is the last age group category.
  
- **female_proportions.csv**: This file contains the mean disaggregated population proportions by female age groups. Variables are written as "prp_fage_1, ....,prp_fage_n" within the .csv file, where n is the last age group category.
  
- **male_disaggregated_data.csv**: This file contains the mean disaggregated population counts by male age groups. Variables are written as "pp_mage_1, ....,pp_mage_n" within the .csv file, where n is the last age group category.
  
- **male_proportions.csv**: This file contains the mean disaggregated population proportions by male age groups. Variables are written as "prp_mage_1, ....,prp_mage_n" within the .csv file, where n is the last age group category.
  
- **full_disaggregated_data.csv**: This file contains both the input data and the posterior estimates of the disaggregated counts and proportionss.
  
- **fit_metrics.csv**: This file contains the values of the model fit metrics used for model performance evaluation. Variables are written as "MAE", "MAPE", "RMSE", "corr"
  
- **model_validation_scatter_plot.png**: This is the automatically generated correlation plot of the observed total age data versus the model predicted total age data.
  

## 10. Support and Contributions
This is a development version of the **jollofR** package and we welcome contributions from the research community to improve **jollofR** and make it even much simpler for everyone to use. For support, bug reports, or feature requests, please contact:

**Chris Nnanatu (Package Developer: https://www.worldpop.org/team/chris_nnanatu/)**

**Affiliation:** Spatial Statistics & Population Modelling (SSPM) Team, WorldPop Research Group (www.worldpop.org), School of Geography and Environmental Science, University of Southampton, SO17 IBJ Southampton, United Kingdom.

**Email:** cc.nnanatu@soton.ac.uk or nnanatuchibuzor@gmail.com.

**LinkedIn:** https://www.linkedin.com/in/dr-chibuzor-christopher-nnanatu-997b68a7/ 

Alternatively, please feel free to open an issue on the GitHub repository via https://github.com/wpgp/jollof/issues.

**Suggested citation**: Nnanatu C, Chaudhuri S, Lazar A, Tatem A (2025). **jollofR**: A Bayesian statistical model-based approach for disaggregating small area population estimates by demographic characteristics. R package version 0.3.0, https://wpgp.github.io/jollofR/.
