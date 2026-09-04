# Background Job — pipeline targets (fase 1+; hoje só alvos de configuração/registro).
targets::tar_make()
print(targets::tar_meta(fields = c("name", "seconds", "error")))
