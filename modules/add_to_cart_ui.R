add_to_cart_ui <- function(id, stock_data) {
  ns <- NS(id)
  tagList(
    h2("🛒 Add to Cart"),
    actionButton(ns("start_scan"), "📷 Scan Barcode"),
    verbatimTextOutput(ns("scan_status")),
    textInput(ns("scanned_code"), "Product Code", placeholder = "Scan or type code..."),
    selectInput(ns("item"), "Select Item", choices = setNames(stock_data()$Code, stock_data()$Item)),
    numericInput(ns("quantity"), "Quantity", value = 1, min = 1),
    actionButton(ns("add_button"), "➕ Add", class = "btn-success"),
    actionButton(ns("cancel_scan"), "🛑 Cancel Scan", class = "btn-warning"),
    br(), br(),
    actionButton(ns("to_user_home"), "⬅ Back to Home")
  )
}
