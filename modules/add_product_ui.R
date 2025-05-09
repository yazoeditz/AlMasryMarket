add_product_ui <- function(id, stock_data) {
  ns <- NS(id)
  tagList(
    h2("➕ Add Product to Stock"),
    
    # --- Scan Section ---
    fluidRow(
      column(6, actionButton(ns("scan_barcode_button"), "📷 Start Scan", class = "btn-success")),
      column(6, actionButton(ns("stop_scanning_button"), "🛑 Stop Camera", class = "btn-danger"))
    ),
    textOutput(ns("scanned_barcode_display")),
    textInput(ns("barcode"), "Product Code (QR/Barcode)", value = "", placeholder = "Scan to auto-fill"),

    # --- Product Entry ---
    textInput(ns("item_name"), "Item Name"),
    numericInput(ns("item_price"), "Price", value = 0, min = 0),
    numericInput(ns("item_quantity"), "Quantity", value = 1, min = 1),

    # --- Actions ---
    actionButton(ns("confirm_add"), "➕ Confirm Add", class = "btn-primary"),
    br(), br(),
    actionButton(ns("to_admin_home"), "⬅ Back to Admin Home", class = "btn-secondary"),
    verbatimTextOutput(ns("add_status"))
  )
}
