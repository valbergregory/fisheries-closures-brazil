# Background Job — piloto de viabilidade.
# NOTA (2026-09-03): o piloto geométrico roda em Python puro enquanto sf/terra
# não estão instalados (renv fase 1). Este script delega e valida a saída.
status <- system2("python", "python/feasibility_pilot.py", stdout = TRUE, stderr = TRUE)
writeLines(status)
stopifnot(file.exists("data/interim/pilot_panel_trindade.csv"),
          file.exists("outputs/diagnostics/map_trindade_pilot.png"))
panel <- data.table::fread("data/interim/pilot_panel_trindade.csv")
stopifnot(nrow(panel) > 0, all(c("zone","post","treated_mona") %in% names(panel)))
cat("Piloto OK:", nrow(panel), "linhas;",
    data.table::uniqueN(panel[, .(cell_lon, cell_lat)]), "células\n")
