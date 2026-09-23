# 26_inference.R — inferência com poucos clusters.
# Wild cluster bootstrap-t restrito (Cameron, Gelbach & Miller 2008) com pesos
# de Webb (6 pontos), recomendados quando G < 12 — aqui G = 5 UFs, caso em que
# Rademacher só geraria 2^5 = 32 reamostras distintas.
# Implementação própria: `fwildclusterboot` não está disponível no CRAN neste
# ambiente (2026-09-22).

webb_weights <- function(n) {
  v <- c(-sqrt(3/2), -1, -sqrt(1/2), sqrt(1/2), 1, sqrt(3/2))
  v[sample.int(6L, n, replace = TRUE)]
}

# fml: fórmula completa (com i(status, post, ...)); coef_name: nome exato do
# coeficiente testado; cluster_var: coluna do cluster (ex.: "uf").
wild_cluster_boot <- function(data, fml, coef_name, cluster_var = "uf",
                              B = 999L, seed = 20260903) {
  set.seed(seed)
  d <- data.table::copy(data)
  fit <- fixest::feols(fml, data = d, cluster = stats::as.formula(paste0("~", cluster_var)))
  ct <- fixest::coeftable(fit)
  stopifnot(coef_name %in% rownames(ct))
  t_obs <- ct[coef_name, 1] / ct[coef_name, 2]

  # modelo restrito: remove o regressor testado (H0: beta = 0)
  rhs <- deparse(fml[[3]], width.cutoff = 500L)
  rhs <- paste(rhs, collapse = "")
  # o termo i(status, post, ref=...) gera vários coeficientes; para impor H0 em
  # apenas um deles, usamos a dummy explícita do nível testado.
  lvl <- sub("^status::", "", sub(":post$", "", coef_name))
  d[, D_test := as.numeric(status == lvl) * post]
  rhs_free <- gsub("i\\(status, post, ref = \"open_both\"\\)",
                   paste0("i(status, post, ref = \"open_both\") - D_test"), rhs, fixed = FALSE)
  # forma prática: o restrito é o modelo com todos os termos MENOS D_test
  others <- setdiff(grep("^status::", rownames(ct), value = TRUE), coef_name)
  lvls_other <- sub("^status::", "", sub(":post$", "", others))
  for (l in lvls_other) d[, (paste0("D_", l)) := as.numeric(status == l) * post]
  extra <- gsub("i\\(status, post, ref = \"open_both\"\\) \\+ ", "", rhs)
  extra <- gsub("i\\(status, post, ref = \"open_both\")", "1", extra, fixed = TRUE)
  f_restr <- stats::as.formula(paste0(deparse(fml[[2]]), " ~ ",
                                      paste(paste0("D_", lvls_other), collapse = " + "), " + ", extra))
  f_full <- stats::as.formula(paste0(deparse(fml[[2]]), " ~ D_test + ",
                                     paste(paste0("D_", lvls_other), collapse = " + "), " + ", extra))
  fit_r <- fixest::feols(f_restr, data = d, notes = FALSE)
  y_hat <- stats::predict(fit_r)
  u_hat <- stats::resid(fit_r)
  ok <- !is.na(y_hat) & !is.na(u_hat)
  d_b <- d[ok]; y_hat <- y_hat[ok]; u_hat <- u_hat[ok]
  yname <- deparse(fml[[2]])
  gs <- unique(d_b[[cluster_var]]); G <- length(gs)
  gidx <- match(d_b[[cluster_var]], gs)

  t_star <- numeric(B)
  for (b in seq_len(B)) {
    w <- webb_weights(G)[gidx]
    d_b[, (yname) := y_hat + u_hat * w]
    fb <- fixest::feols(f_full, data = d_b, cluster = stats::as.formula(paste0("~", cluster_var)), notes = FALSE)
    cb <- fixest::coeftable(fb)
    t_star[b] <- if ("D_test" %in% rownames(cb)) cb["D_test", 1] / cb["D_test", 2] else NA_real_
  }
  t_star <- t_star[is.finite(t_star)]
  list(coef = ct[coef_name, 1], se_cluster = ct[coef_name, 2], t_obs = t_obs,
       p_boot = mean(abs(t_star) >= abs(t_obs)), B_used = length(t_star), G = G,
       ci_boot = ct[coef_name, 1] - stats::quantile(t_star, c(0.975, 0.025), names = FALSE) * ct[coef_name, 2])
}
