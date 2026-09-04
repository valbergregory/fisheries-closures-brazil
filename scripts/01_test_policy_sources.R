# Background Job — testa acesso às fontes NORMATIVAS (requisições mínimas).
# Log em outputs/logs/. Não baixa universo.
source("R/01_config.R")
catalog <- load_policy_catalog()
log <- file.path("outputs/logs", format(Sys.time(), "policy_access_%Y%m%d_%H%M.log"))
con <- file(log, open = "wt"); sink(con, split = TRUE)
urls <- c(
  ibama_defesos = "https://www.gov.br/ibama/pt-br/assuntos/biodiversidade/biodiversidade-aquatica/periodos-de-defeso/defesos-marinhos",
  dou = "https://www.in.gov.br/",
  planalto = "https://www.planalto.gov.br/ccivil_03/"
)
for (n in names(urls)) {
  st <- tryCatch(httr2::req_perform(httr2::req_method(httr2::request(urls[[n]]), "HEAD"))$status_code,
                 error = function(e) conditionMessage(e))
  cat(sprintf("%-16s %s -> %s\n", n, urls[[n]], st))
}
print(catalog)
sink(); close(con)
