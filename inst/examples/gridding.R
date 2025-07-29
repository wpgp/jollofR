# install.packages("devtools")
#devtools::install_github("wpgp/jollofR")
library(INLA)
library(tidyverse)
library(jollofR)

# set directories
path <- "C:/Users/ccn1r22/OneDrive - University of Southampton/Documents/packages/main/jollofR_scripts"
data_path <- paste0(path, "/data")
out_path <- paste0(path, "/output")

# Load key packages and libraries
# install.packages("jollofR")

source(paste0(path, "/sprinkle.R")) #disaggregates population based on the grid pop count
source(paste0(path, "/splash.R")) #disaggregates population based on the grid building count
source(paste0(path, "/spray.R")) #disaggregates population by area-weighting


# load in put data
dim(datf <- read.csv(paste0(data_path, "/toy_admin_data.csv")))
dim(rdatf <- readRDS(paste0(data_path, "/toy_grid_data.rds")))

# run cheesepop
result <- cheesecake(df = datf,out_path) 
#result <- cheesecake(df = datf,out_path) 
pyramid(result$fem_age_pop,result$male_age_pop)
dat <- result$full_data
dat$admin_id <- dat$clst_id

# grid population classes (you can create yours but has to be same as in the admin data)
rclass <- paste0("TOY_population_v1_0_age",1:12) # Mean


# run sprinkle
output_dir <- paste0(out_path, "/raster/sprinkle")
result2 <- sprinkle(df = dat, rdf = rdatf, rclass, output_dir) 
dev.off()
pyr2 <- pyramid(result2$fem_age_pop,result2$male_age_pop)
#result2$full_data
ras2<- raster(paste0(output_dir, "/pop_TOY_population_v1_0_agesex_f4.tif"))
p2 <- plot(ras2,
     legend=T, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis=3)


# run splash
output_dir3 <- paste0(out_path, "/raster/splash")
result3 <- splash(df = dat, rdf = rdatf, rclass, output_dir3) 
dev.off()
pyr3 <- pyramid(result3$fem_age_pop,result3$male_age_pop)
#result2$full_data
ras3<- raster(paste0(output_dir3, "/pop_TOY_population_v1_0_agesex_f4.tif"))
p3 <- plot(ras3,
     legend=T, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis=3)


# run spray
output_dir4 <- paste0(out_path, "/raster/spray")
result4 <- spray(df = dat, rdf = rdatf, rclass, output_dir4) 
dev.off()
pyr4 <- pyramid(result4$fem_age_pop,result4$male_age_pop)
#result2$full_data
ras4<- raster(paste0(output_dir4, "/pop_TOY_population_v1_0_agesex_f4.tif"))
p4 <- plot(ras4,
     legend=T, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis=3)

par(mfrow=c(2,2))
p2 <- plot(ras2,
           legend=T, col = colorRampPalette(c("white", "orange", "brown"))(255),
           asp = NA, cex.axis=3)
p3 <- plot(ras3,
           legend=T, col = colorRampPalette(c("white", "orange", "brown"))(255),
           asp = NA, cex.axis=3)
p4 <- plot(ras4,
           legend=T, col = colorRampPalette(c("white", "orange", "brown"))(255),
           asp = NA, cex.axis=3)


## plot pyramids together
library(ggpubr)
ggarrange(pyr2, pyr3, pyr4,
          ncol=2, nrow=2)


# compare
ii <- sample(12,1)
head(cbind(result2$male_age_pop[, ii], result3$male_age_pop[, ii],result4$male_age_pop[, ii]),30)


