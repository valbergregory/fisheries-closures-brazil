# 02_utils.R — utilidades transversais.

track_legal_files <- function(dir = "data/legal") {
  list.files(dir, full.names = TRUE, pattern = "\\.(pdf|html|txt)$")
}

checksum_files <- function(files) {
  data.table::data.table(
    file = basename(files),
    sha256 = vapply(files, function(f) digest::digest(file = f, algo = "sha256"),
                    character(1)),
    bytes = file.size(files),
    checked_at = as.character(Sys.time())
  )
}
