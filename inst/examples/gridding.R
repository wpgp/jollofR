# Example script for grid-level population disaggregation
# Uses toydata included with jollofR package

library(INLA)
library(tidyverse)
library(jollofR)

# Load toydata from package
data(toydata)

# Extract admin and grid data
datf <- toydata$admin
rdatf <- toydata$grid

# Set output directory (creates temp directory for this example)
out_path <- tempdir()

# Run cheesecake for administrative level disaggregation
result <- cheesecake(df = datf, output_dir = out_path)
pyramid(result$fem_age_pop, result$male_age_pop)

# Get full data with predictions for grid disaggregation
dat <- result$full_data

# Age classes for grid disaggregation (matching admin data structure)
rclass <- names(datf)[grepl("^age_", names(datf))]

# Run sprinkle (uses known grid cell population totals)
output_dir <- file.path(out_path, "raster", "sprinkle")
result2 <- sprinkle(df = dat, rdf = rdatf, rclass, output_dir)
dev.off()
pyr2 <- pyramid(result2$fem_age_pop, result2$male_age_pop)

# Plot raster output
ras2 <- raster(paste0(output_dir, "/pop_", rclass[4], "_f.tif"))
p2 <- plot(ras2,
     legend = TRUE, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis = 3)

# Run splash (uses building counts as weighting layer)
output_dir3 <- file.path(out_path, "raster", "splash")
result3 <- splash(df = dat, rdf = rdatf, rclass, output_dir3)
dev.off()
pyr3 <- pyramid(result3$fem_age_pop, result3$male_age_pop)

# Plot raster output
ras3 <- raster(paste0(output_dir3, "/pop_", rclass[4], "_f.tif"))
p3 <- plot(ras3,
     legend = TRUE, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis = 3)

# Run spray (equal weight distribution across grid cells)
output_dir4 <- file.path(out_path, "raster", "spray")
result4 <- spray(df = dat, rdf = rdatf, rclass, output_dir4)
dev.off()
pyr4 <- pyramid(result4$fem_age_pop, result4$male_age_pop)

# Plot raster output
ras4 <- raster(paste0(output_dir4, "/pop_", rclass[4], "_f.tif"))
p4 <- plot(ras4,
     legend = TRUE, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis = 3)

# Compare all three methods side by side
oldpar <- par(mfrow = c(2, 2))
plot(ras2, main = "Sprinkle Method",
     legend = TRUE, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis = 3)
plot(ras3, main = "Splash Method",
     legend = TRUE, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis = 3)
plot(ras4, main = "Spray Method",
     legend = TRUE, col = colorRampPalette(c("white", "orange", "brown"))(255),
     asp = NA, cex.axis = 3)
par(oldpar)

# Plot population pyramids together
library(ggpubr)
ggarrange(pyr2, pyr3, pyr4,
          labels = c("Sprinkle", "Splash", "Spray"),
          ncol = 2, nrow = 2)

# Compare results for a random age group
set.seed(123)  # for reproducibility
ii <- sample(12, 1)
comparison <- cbind(
  Sprinkle = result2$male_age_pop[, ii],
  Splash = result3$male_age_pop[, ii],
  Spray = result4$male_age_pop[, ii]
)
head(comparison, 30)
