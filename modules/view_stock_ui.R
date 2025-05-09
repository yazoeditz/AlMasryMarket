view_stock_ui <- function(id, stock_data) {
  ns <- NS(id)
  tagList(
    h2("📦 View Stock"),
    actionButton(ns("refresh_stock"), "🔄 Refresh Stock"),
    DT::dataTableOutput(ns("stock_table")),
    br(),
    actionButton(ns("to_admin_home"), "⬅ Back to Admin Home")
  )
}
