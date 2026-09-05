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
cat("Auditoria 2026-09-04: stack completa via renv (lockfile em renv.lock);\n",
    "duckdb exige binário (fonte não compila no Rtools44 em tempo hábil) e\n",
    "synthdid vem do GitHub: renv::install('synth-inference/synthdid').\n")
