# Background Job — pipeline targets completo (ver _targets.R).
targets::tar_make()
print(targets::tar_meta(fields = c("name", "seconds", "error"))[order(-seconds)][1:15, ])
