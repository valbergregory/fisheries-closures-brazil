# Background Job — testa acesso às fontes de DADOS (requisições mínimas).
log <- file.path("outputs/logs", format(Sys.time(), "data_access_%Y%m%d_%H%M.log"))
con <- file(log, open = "wt"); sink(con, split = TRUE)
tok <- Sys.getenv("GFW_TOKEN")
cat("GFW token:", if (nzchar(tok)) "definido" else "AUSENTE (bloqueio ativo)", "\n")
if (nzchar(tok)) {
  r <- tryCatch(httr2::req_perform(httr2::req_auth_bearer_token(
    httr2::request("https://gateway.api.globalfishingwatch.org/v3/datasets/public-global-fishing-effort:latest"), tok)),
    error = function(e) e)
  cat("GFW datasets:", if (inherits(r, "error")) conditionMessage(r) else r$status_code, "\n")
}
wfs <- "https://geoservicos.inde.gov.br/geoserver/ICMBio/ows?service=WFS&version=2.0.0&request=GetCapabilities"
st <- tryCatch(httr2::req_perform(httr2::request(wfs))$status_code, error = function(e) conditionMessage(e))
cat("INDE WFS ICMBio:", st, "\n")
sd <- "https://portaldatransparencia.gov.br/download-de-dados/seguro-defeso"
st <- tryCatch(httr2::req_perform(httr2::req_method(httr2::request(sd), "HEAD"))$status_code, error = function(e) conditionMessage(e))
cat("Seguro-Defeso CGU:", st, "\n")
sink(); close(con)
