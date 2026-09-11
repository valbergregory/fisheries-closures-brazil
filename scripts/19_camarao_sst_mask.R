# Background Job — SST mensal + máscara oceânica para a bbox do camarão (OISST local).
suppressPackageStartupMessages(library(data.table)); source("R/08_download_environment.R")
lons <- seq(-54 + 0.125, -40 - 0.125, by = 0.25); lats <- seq(-34.5 + 0.125, -21 - 0.125, by = 0.25)
cells <- CJ(cell_lon = lons, cell_lat = lats)
s <- oisst_monthly_for_grid(cells, 2018:2024, "D:/Claude code - projetos/marine-fisheries-data-cube/data/raw/oisst_global",
                            out_file = "data/interim/sst_camarao_monthly.csv")
cat("células oceânicas:", uniqueN(paste(s$cell_lon, s$cell_lat)), "de", nrow(cells), "\n")
