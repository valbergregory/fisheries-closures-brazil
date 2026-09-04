# Fisheries Regulation Knowledge Base and Spatial Compliance Observatory
# Protótipo mínimo — mostra o registro de regras. Mapa/esforço na fase 1+.
library(shiny)
rules <- list.files("../outputs/policies", pattern = "\.json$", full.names = TRUE)
if (length(rules) == 0) rules <- list.files("outputs/policies", pattern = "\.json$", full.names = TRUE)
ui <- fluidPage(
  titlePanel("Fisheries Regulation Observatory — protótipo"),
  tableOutput("registry")
)
server <- function(input, output, session) {
  output$registry <- renderTable({
    do.call(rbind, lapply(rules, function(f) {
      r <- jsonlite::read_json(f)
      data.frame(rule = r$rule_id, norma = r$norm_id,
                 periodo = paste(r$period$start, "a", r$period$end),
                 UF = paste(unlist(r$area$uf), collapse = ","),
                 validada = isTRUE(r$validation$human_validated))
    }))
  })
}
shinyApp(ui, server)
