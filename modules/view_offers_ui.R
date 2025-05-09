
view_offers_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h2("📋 Active Offers"),
    DTOutput(ns("offers_table")),
    br(),
    actionButton(ns("back_to_admin"), "Back to Admin Home")
  )
}
