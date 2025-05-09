view_prices_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h2("🧾 Current Item Prices"),
    DT::dataTableOutput(ns("prices_table")),
    br(),
    actionButton(ns("back_to_home"), "Back to Home")
  )
}
