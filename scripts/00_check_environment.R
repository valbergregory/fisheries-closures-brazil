# Console RStudio — auditoria rápida do ambiente. Não instala nada.
cat("R:", R.version.string, "\n")
for (p in c("targets","tarchetypes","renv","sf","terra","duckdb","arrow",
            "data.table","fixest","did","rdrobust","synthdid","modelsummary",
            "digest","yaml","jsonlite","httr2","quarto","testthat")) {
  cat(sprintf("%-14s %s\n", p,
              if (requireNamespace(p, quietly = TRUE))
                as.character(utils::packageVersion(p)) else "AUSENTE"))
}
cat("GFW_TOKEN definido:", nzchar(Sys.getenv("GFW_TOKEN")), "\n")
cat("Auditoria 2026-09-03: sf/terra/duckdb/arrow/rdrobust/synthdid AUSENTES —\n",
    "instalar via renv na fase 1 (docs/reproducibility_guide.md).\n")
