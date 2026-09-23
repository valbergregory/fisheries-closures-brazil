# Tabelas do artigo (LaTeX + CSV) e macros numéricas para o manuscrito.
# Rodar: Rscript scripts/31_tables_paper.R
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/24_camarao_prep.R")
OUT <- "outputs/tables"; p <- prep_camarao()

## T1 — descritivas
t1 <- p[, .(celulas = uniqueN(cell),
            horas_arrasto = round(sum(trawl_hours)),
            horas_arrasto_prefrota = round(sum(trawl_hours_prefleet)),
            horas_outras_artes = round(sum(other_hours)),
            presenca_ais = round(sum(presence_hours)),
            cargueiros = round(sum(as.numeric(cargo_hours)))), by = year][order(year)]
fwrite(t1, file.path(OUT, "T1_descritivas.csv")); cat("== T1 ==\n"); print(t1)

## T2 — resultado principal
m <- readRDS("outputs/models/camarao_calendar.rds")
etable(m$A, m$B, m$C, m$D, m$E, m$G, file = file.path(OUT, "T2_principal.tex"), replace = TRUE,
       headers = c("(1) toda a frota", "(2) + cobertura", "(3) frota pré-2023", "(4) + SST", "(5) PPML", "(6) cluster duplo"),
       title = "Efeito da reforma do calendário sobre o esforço de arrasto, por janela do calendário",
       digits = 3, fitstat = ~ n + r2)
cat("\n== T2 gerada ==\n")

## T3 — placebos e robustez de inferência
wcb <- fread(file.path(OUT, "camarao_wild_bootstrap.csv"))
plm <- fread(file.path(OUT, "camarao_placebo_months.csv"))
ptmp <- fread(file.path(OUT, "camarao_placebo_temporal.csv"))
t3 <- data.table(
  teste = c("efeito estimado (principal)", "cluster por UF (G=5)", "wild bootstrap Webb (p)",
            "placebo temporal: reforma fictícia 2021", "randomização: rank entre 8 meses",
            "placebo cargueiros (detecção)"),
  fevereiro = c("-0,314***", "-0,314 (0,274)", sprintf("%.3f", wcb[coef_name %like% "new_closed", p_wcb]),
                sprintf("%+.3f (%.3f)", ptmp[rn %like% "new_closed", Estimate], ptmp[rn %like% "new_closed", `Std. Error`]),
                "1/8", "-0,001 (n.s.)"),
  maio = c("+0,631***", "+0,631** (0,129)", sprintf("%.3f", wcb[coef_name %like% "new_open", p_wcb]),
           sprintf("%+.3f (%.3f)", ptmp[rn %like% "new_open", Estimate], ptmp[rn %like% "new_open", `Std. Error`]),
           "1/8", "-0,074*** (sinal oposto)"))
fwrite(t3, file.path(OUT, "T3_placebos.csv")); cat("\n== T3 ==\n"); print(t3)

## T4 — heterogeneidade e T5 — geometria já existem como CSV
t4 <- fread(file.path(OUT, "camarao_by_uf.csv")); cat("\n== T4 (UF) ==\n"); print(t4)
t5 <- fread(file.path(OUT, "camarao_geometry_sensitivity.csv")); cat("\n== T5 (geometria) ==\n"); print(t5)

## macros numéricas para o manuscrito (evita números digitados à mão)
ct <- coeftable(m$D)
dec <- fread(file.path(OUT, "camarao_leakage_decomposition.csv"))
comp <- fread(file.path(OUT, "camarao_gear_composition.csv"))
sd <- fread(file.path(OUT, "seguro_defeso_calendar_shift.csv"))
macros <- c(
  sprintf("\\newcommand{\\betaFeb}{%.3f}", ct["status::new_closed:post", 1]),
  sprintf("\\newcommand{\\seFeb}{%.3f}", ct["status::new_closed:post", 2]),
  sprintf("\\newcommand{\\betaMay}{%.3f}", ct["status::new_open:post", 1]),
  sprintf("\\newcommand{\\seMay}{%.3f}", ct["status::new_open:post", 2]),
  sprintf("\\newcommand{\\pctMay}{%.0f}", 100 * (exp(ct["status::new_open:post", 1]) - 1)),
  sprintf("\\newcommand{\\pctFeb}{%.0f}", 100 * (exp(ct["status::new_closed:post", 1]) - 1)),
  sprintf("\\newcommand{\\pWCBMay}{%.3f}", wcb[coef_name %like% "new_open", p_wcb]),
  sprintf("\\newcommand{\\pWCBFeb}{%.2f}", wcb[coef_name %like% "new_closed", p_wcb]),
  sprintf("\\newcommand{\\netHours}{%.1f}", sum(dec[status != "open_both", change]) / 1000),
  sprintf("\\newcommand{\\netPct}{%.0f}", 100 * sum(dec[status != "open_both", change]) / dec[status != "open_both", sum(hours_obs)]),
  sprintf("\\newcommand{\\nCells}{%d}", uniqueN(p$cell)),
  sprintf("\\newcommand{\\nVesselsTrawl}{%d}", 1106L),
  sprintf("\\newcommand{\\trawlShareFebPre}{%.1f}", comp[geartype == "TRAWLERS" & window == "fev", pre_2023]),
  sprintf("\\newcommand{\\trawlShareFebPos}{%.1f}", comp[geartype == "TRAWLERS" & window == "fev", pos_2023]),
  sprintf("\\newcommand{\\trawlShareMayPre}{%.1f}", comp[geartype == "TRAWLERS" & window == "mai", pre_2023]),
  sprintf("\\newcommand{\\trawlShareMayPos}{%.1f}", comp[geartype == "TRAWLERS" & window == "mai", pos_2023]),
  sprintf("\\newcommand{\\sdJanFeb}{%.1f}", sd[month %in% 1:2, sum(diff)]),
  sprintf("\\newcommand{\\sdMayJun}{%.1f}", sd[month %in% 5:6, sum(diff)]))
writeLines(macros, "article/numbers.tex")
cat("\n== macros -> article/numbers.tex ==\n"); writeLines(macros)
