# 00_setup.R — utilidades de inicialização (sem efeitos colaterais globais).

ensure_dirs <- function(paths) {
  for (p in paths) if (!dir.exists(p)) dir.create(p, recursive = TRUE)
  invisible(paths)
}
