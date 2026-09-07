#!/usr/bin/env Rscript
# run_all.R — Orquestrador leve (sem pacotes externos)
# Uso: Rscript run_all.R [--stop-on-error] [--root DIR]

args <- commandArgs(trailingOnly = TRUE)
stop_on_error <- "--stop-on-error" %in% args

root_arg <- grep("--root", args, value = TRUE)
if (length(root_arg) > 0) {
  root_dir <- sub("--root=", "", root_arg[1])
} else {
  # Tenta descobrir a raiz a partir do local do script
  script_path <- if (interactive()) getwd() else dirname(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))
  if (length(script_path) == 0 || script_path == "") script_path <- getwd()
  root_dir <- script_path
}
root_dir <- normalizePath(root_dir, winslash = "/", mustWork = FALSE)
cat("Raiz do projeto:", root_dir, "\n")

# Verifica se o Rscript está funcionando
teste <- system2("Rscript", c("-e", "cat('Rscript OK\\n')"), stdout = TRUE, stderr = TRUE)
if (length(teste) == 0 || !grepl("OK", teste[1])) {
  stop("Rscript não está respondendo. Verifique a instalação do R.")
}

# Define diretórios de busca
dirs <- c("scripts", "R")
dirs <- file.path(root_dir, dirs)
dirs <- dirs[dir.exists(dirs)]
if (length(dirs) == 0) {
  stop("Nenhum diretório 'scripts' ou 'R' encontrado em ", root_dir)
}
cat("Diretórios de busca:", paste(dirs, collapse = ", "), "\n")

# Coleta scripts numerados
script_files <- c()
for (d in dirs) {
  files <- list.files(d, pattern = "^[0-9]{2}_.*\\.R$", full.names = TRUE)
  if (length(files) > 0) script_files <- c(script_files, files)
}
if (length(script_files) == 0) {
  stop("Nenhum script numerado (00_*.R a 23_*.R) encontrado.")
}
script_files <- script_files[order(as.numeric(sub(".*/([0-9]{2})_.*", "\\1", script_files)))]
cat("Scripts encontrados:\n", paste(basename(script_files), collapse = "\n"), "\n")

# Cria diretório de logs
log_dir <- file.path(root_dir, "outputs/logs")
dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)

# Função para executar um script via Rscript
run_script <- function(file) {
  cat("\n", rep("=", 60), "\n", sep = "")
  cat(sprintf("Executando: %s\n", basename(file)))
  cat(rep("-", 60), "\n", sep = "")

  log_file <- file.path(log_dir,
                        paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_",
                               gsub("\\.R$", "", basename(file)), ".log"))

  # Executa Rscript com o script, redirecionando saída e erro para o log
  cmd <- paste0("Rscript \"", file, "\"", " > \"", log_file, "\" 2>&1")
  start_time <- Sys.time()
  exit_code <- system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
  elapsed <- difftime(Sys.time(), start_time, units = "secs")

  success <- exit_code == 0
  cat(sprintf("Tempo decorrido: %.2f segundos\n", elapsed))
  cat(sprintf("Status: %s (código %d)\n", if (success) "SUCESSO" else "FALHA", exit_code))

  # Lê as últimas linhas do log para exibir no console (opcional)
  if (!success && file.exists(log_file)) {
    tail_lines <- tryCatch(readLines(log_file, n = 10, warn = FALSE), error = function(e) NULL)
    if (length(tail_lines) > 0) {
      cat("Últimas linhas do log:\n")
      cat(paste(tail_lines, collapse = "\n"), "\n")
    }
  }

  list(
    file = basename(file),
    success = success,
    exit_code = exit_code,
    log = log_file,
    elapsed = elapsed
  )
}

# Executa todos
results <- list()
for (f in script_files) {
  results[[f]] <- run_script(f)
  if (stop_on_error && !results[[f]]$success) {
    cat("\nParando por --stop-on-error.\n")
    break
  }
}

# Sumário
cat("\n\n", rep("=", 60), "\n", sep = "")
cat("RESUMO DA EXECUÇÃO\n")
cat(rep("=", 60), "\n", sep = "")
for (r in results) {
  status <- if (r$success) "✔" else "✘"
  cat(sprintf("%s %-30s %s\n", status, r$file,
              if (r$success) sprintf("OK (%.1fs)", r$elapsed) else sprintf("ERRO (código %d)", r$exit_code)))
}
cat("\nLogs detalhados em:", log_dir, "\n")
