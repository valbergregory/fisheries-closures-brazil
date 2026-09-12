# SST OISST mensal para a grade de Trindade (chamado pelo pipeline targets).
suppressPackageStartupMessages(library(data.table)); source("R/08_download_environment.R")
cells <- unique(fread("data/interim/pilot_panel_trindade.csv")[, .(cell_lon, cell_lat)])
s <- oisst_monthly_for_grid(cells, 2014:2024, "D:/Claude code - projetos/marine-fisheries-data-cube/data/raw/oisst_global")
cat("SST Trindade:", nrow(s), "linhas\n")
