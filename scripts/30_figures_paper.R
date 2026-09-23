# Figuras e tabelas do artigo (caso camarão + diagnóstico Trindade).
# Rodar: Rscript scripts/30_figures_paper.R
suppressPackageStartupMessages({ library(data.table); library(fixest); library(ggplot2); library(sf) })
source("R/24_camarao_prep.R")
theme_set(theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 9, colour = "grey30")))
OUT <- "outputs/figures"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
p <- prep_camarao()
pal <- c(new_closed = "#c0392b", new_open = "#1f77b4", closed_both = "#7f8c8d",
         mixed_jan = "#e67e22", open_both = "#bdc3c7")

## Fig 1 — mapa da área de estudo
land <- do.call(rbind, lapply(c("ES","RJ","SP","PR","SC","RS"), function(u) {
  g <- read_sf(file.path("data/raw/ibge", paste0("uf_", u, ".json"))); g$uf <- u; st_make_valid(g["uf"]) }))
cells <- p[, .(trawl = sum(trawl_hours), coast_km = coast_km[1]), by = .(cell_lon, cell_lat)]
g1 <- ggplot() +
  geom_sf(data = land, fill = "grey92", colour = "grey60", linewidth = 0.2) +
  geom_tile(data = cells, aes(cell_lon, cell_lat, fill = pmax(trawl, 1)), width = .25, height = .25) +
  scale_fill_viridis_c(trans = "log10", name = "horas de\narrasto\n2018–2024", option = "C") +
  coord_sf(xlim = c(-53.5, -40.5), ylim = c(-34, -21.2), expand = FALSE) +
  labs(title = "Área de estudo: arrasto no Mar Territorial e ZEE de RJ a RS",
       subtitle = "células de 0,25° a até 100 km da costa (D3); águas interiores excluídas",
       x = NULL, y = NULL)
ggsave(file.path(OUT, "fig1_area_estudo.png"), g1, width = 7, height = 7.5, dpi = 300)

## Fig 2 — calendário da reforma
cal <- data.table(month = 1:12,
  antes = c("livre","livre","fechado","fechado","fechado","livre","livre","livre","livre","livre","livre","livre"),
  depois = c("parcial","fechado","fechado","fechado","livre","livre","livre","livre","livre","livre","livre","livre"))
cl <- melt(cal, id.vars = "month", variable.name = "regime", value.name = "estado")
cl[, regime := factor(regime, levels = c("depois","antes"), labels = c("desde 2023\n(Port. 656/2022)","até 2022\n(IN 189/2008)"))]
g2 <- ggplot(cl, aes(factor(month), regime, fill = estado)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  scale_fill_manual(values = c(fechado = "#c0392b", livre = "#d5e8f7", parcial = "#e67e22"), name = NULL) +
  scale_x_discrete(labels = c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  labs(title = "A reforma do calendário do defeso do camarão (SE/S)",
       subtitle = "fevereiro passa de livre a fechado; maio passa de fechado a livre", x = NULL, y = NULL)
ggsave(file.path(OUT, "fig2_calendario.png"), g2, width = 7.5, height = 2.6, dpi = 300)

## Fig 3 — event study
es <- readRDS("outputs/models/camarao_eventstudy.rds")
lab <- c("1" = "janeiro (parcial)", "2" = "fevereiro: livre → FECHADO", "5" = "maio: fechado → LIVRE", "3" = "março (fechado nos dois)")
dd <- rbindlist(lapply(names(es), function(k) {
  ct <- coeftable(es[[k]]); nm <- grep("^rel::", rownames(ct), value = TRUE)
  data.table(mes = lab[k], rel = as.integer(gsub(":tm", "", gsub("rel::", "", nm, fixed = TRUE), fixed = TRUE)),
             b = ct[nm, 1], se = ct[nm, 2]) }))
dd <- rbind(dd, data.table(mes = unique(dd$mes), rel = -1L, b = 0, se = 0))
dd[, mes := factor(mes, levels = lab[c("1","2","5","3")])]
g3 <- ggplot(dd, aes(rel + 2023, b)) +
  geom_hline(yintercept = 0, colour = "grey50") + geom_vline(xintercept = 2022.5, linetype = 2, colour = "#c0392b") +
  geom_errorbar(aes(ymin = b - 1.96*se, ymax = b + 1.96*se), width = .12, colour = "grey35") +
  geom_point(size = 1.9) + facet_wrap(~mes, nrow = 1) +
  labs(title = "Event study anual por janela de calendário",
       subtitle = "ihs(horas de arrasto), frota com AIS anterior a 2023; controle = jul–dez; ref. 2022; EF célula×mês e ano",
       x = NULL, y = "efeito vs. meses de controle")
ggsave(file.path(OUT, "fig3_event_study.png"), g3, width = 10, height = 3.1, dpi = 300)

## Fig 4 — meses-placebo
pl <- fread("outputs/tables/camarao_placebo_months.csv")
real <- data.table(mes = c("fevereiro", "maio"), beta = c(-0.3136, 0.6315))
g4 <- ggplot(pl, aes(beta, 0)) +
  geom_vline(xintercept = 0, colour = "grey70") +
  geom_point(size = 3, colour = "grey45", alpha = .8) +
  geom_point(data = real, aes(beta, 0, colour = mes), size = 4.5) +
  scale_colour_manual(values = c(fevereiro = "#c0392b", maio = "#1f77b4"), name = "meses reformados") +
  scale_y_continuous(breaks = NULL, limits = c(-.5, .5)) +
  labs(title = "Randomização sobre meses-placebo (jun–dez tratados como se fossem reformados)",
       subtitle = "cada ponto cinza é um mês não afetado pela reforma; os dois meses reformados são os extremos (rank 1/8 cada)",
       x = "coeficiente estimado", y = NULL)
ggsave(file.path(OUT, "fig4_placebo_meses.png"), g4, width = 8, height = 2.6, dpi = 300)

## Fig 5 — sensibilidade à distância
sens <- fread("outputs/tables/camarao_geometry_sensitivity.csv")
sl <- melt(sens[, .(raio_km, fev, mai)], id.vars = "raio_km", variable.name = "janela", value.name = "b")
se <- melt(sens[, .(raio_km, fev = fev_se, mai = mai_se)], id.vars = "raio_km", variable.name = "janela", value.name = "se")
sl <- merge(sl, se, by = c("raio_km", "janela"))
sl[, janela := factor(janela, levels = c("fev","mai"), labels = c("fevereiro (fechado)", "maio (aberto)"))]
g5 <- ggplot(sl, aes(raio_km, b, colour = janela)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_ribbon(aes(ymin = b - 1.96*se, ymax = b + 1.96*se, fill = janela), alpha = .15, colour = NA) +
  geom_line(linewidth = .9) + geom_point(size = 2) +
  geom_vline(xintercept = 100, linetype = 3) +
  scale_colour_manual(values = c("#c0392b", "#1f77b4"), name = NULL) +
  scale_fill_manual(values = c("#c0392b", "#1f77b4"), guide = "none") +
  labs(title = "O efeito está onde a pescaria está",
       subtitle = "raio de estudo (distância à costa); a linha pontilhada marca a especificação principal (100 km)",
       x = "raio máximo à costa (km)", y = "coeficiente")
ggsave(file.path(OUT, "fig5_sensibilidade_distancia.png"), g5, width = 7.5, height = 3.4, dpi = 300)

## Fig 6 — composição de artes
comp <- fread("outputs/tables/camarao_gear_composition.csv")
comp <- comp[geartype %in% c("TRAWLERS","SET_LONGLINES","FISHING")]
cm <- melt(comp, id.vars = c("geartype","window"), measure.vars = c("pre_2023","pos_2023"),
           variable.name = "periodo", value.name = "share")
cm[, periodo := factor(periodo, levels = c("pre_2023","pos_2023"), labels = c("até 2022","desde 2023"))]
cm[, window := factor(window, levels = c("fev","mai"), labels = c("fevereiro: livre → FECHADO","maio: fechado → LIVRE"))]
cm[, geartype := factor(geartype, levels = c("TRAWLERS","SET_LONGLINES","FISHING"),
                        labels = c("arrasto","espinhel de fundo","outras/não classificada"))]
g6 <- ggplot(cm, aes(periodo, share, fill = geartype)) +
  geom_col(width = .65) + facet_wrap(~window) +
  scale_fill_manual(values = c("#c0392b", "#2e86c1", "#f0b27a"), name = NULL) +
  labs(title = "Substituição de arte: a mesma frota troca de modalidade quando o arrasto fecha",
       subtitle = "composição das horas observadas na frota com AIS anterior a 2023 (%)", x = NULL, y = "% das horas")
ggsave(file.path(OUT, "fig6_composicao_artes.png"), g6, width = 8, height = 3.6, dpi = 300)

## Fig 7 — Seguro-Defeso
sd <- fread("outputs/tables/seguro_defeso_calendar_shift.csv")
g7 <- ggplot(sd, aes(factor(month), diff, fill = diff > 0)) +
  geom_col(width = .7) + geom_hline(yintercept = 0, colour = "grey40") +
  scale_fill_manual(values = c("TRUE" = "#1f77b4", "FALSE" = "#c0392b"), guide = "none") +
  scale_x_discrete(labels = c("J","F","M","A","M","J","J","A","S","O","N","D")) +
  labs(title = "A compensação seguiu o novo calendário",
       subtitle = "Seguro-Defeso em RJ+SP+PR+SC+RS: mudança na participação de cada mês no total anual (média 2023–24 menos 2019–22)",
       x = NULL, y = "pontos percentuais")
ggsave(file.path(OUT, "fig7_seguro_defeso.png"), g7, width = 7.5, height = 3, dpi = 300)

## Fig 8 — decomposição do leakage
dec <- fread("outputs/tables/camarao_leakage_decomposition.csv")[status != "open_both"]
dec[, lab := fcase(status == "new_closed", "fevereiro\n(fechado)", status == "new_open", "maio\n(aberto)",
                   status == "closed_both", "mar–abr\n(fechado nos dois)", status == "mixed_jan", "janeiro\n(parcial)")]
dec[, lab := factor(lab, levels = dec$lab[order(-dec$change)])]
g8 <- ggplot(dec, aes(lab, change/1000, fill = change > 0)) +
  geom_col(width = .65) + geom_hline(yintercept = 0, colour = "grey40") +
  scale_fill_manual(values = c("TRUE" = "#1f77b4", "FALSE" = "#c0392b"), guide = "none") +
  labs(title = "Decomposição temporal: a reforma aumentou o esforço líquido",
       subtitle = sprintf("horas de arrasto em 2023–24 vs. contrafactual (frota pré-2023, PPML); líquido = %+.1f mil h",
                          sum(dec$change)/1000),
       x = NULL, y = "mil horas")
ggsave(file.path(OUT, "fig8_decomposicao.png"), g8, width = 7, height = 3.2, dpi = 300)

cat("figuras geradas em", OUT, ":\n"); print(list.files(OUT, pattern = "^fig"))
