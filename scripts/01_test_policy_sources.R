# Background Job — testa acesso às fontes NORMATIVAS (requisições mínimas).
# Log em outputs/logs/. Não baixa universo.
#
# NOTA (2026-09-08): corrigido após falsos negativos de 05/09 — HEAD com
# user-agent padrão do httr2 leva 403 no gov.br e erro HTTP/2 no in.gov.br.
# Usar GET com UA de browser e HTTP/1.1 quando necessário.
source("R/01_config.R")
catalog <- load_policy_catalog()
log <- file.path("outputs/logs", format(Sys.time(), "policy_access_%Y%m%d_%H%M.log"))
con <- file(log, open = "wt"); sink(con, split = TRUE)

UA <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) research-compendium fisheries-closures-brazil"

check_url <- function(url, http1 = FALSE) {
  req <- httr2::request(url) |>
    httr2::req_user_agent(UA) |>
    httr2::req_timeout(30)
  if (http1) req <- httr2::req_options(req, http_version = 2L)  # CURL_HTTP_VERSION_1_1
  tryCatch(httr2::req_perform(req)$status_code,
           error = function(e) conditionMessage(e))
}

urls <- list(
  ibama_defesos = list(url = "https://www.gov.br/ibama/pt-br/assuntos/biodiversidade/biodiversidade-aquatica/periodos-de-defeso/defesos-marinhos"),
  dou           = list(url = "https://www.in.gov.br/servicos", http1 = TRUE),
  planalto      = list(url = "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/decreto/D9312.htm")
)
for (n in names(urls)) {
  st <- check_url(urls[[n]]$url, isTRUE(urls[[n]]$http1))
  cat(sprintf("%-16s %s -> %s\n", n, urls[[n]]$url, st))
}
print(catalog)
sink(); close(con)
