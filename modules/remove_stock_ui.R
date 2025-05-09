remove_stock_ui <- function(id, stock_data) {
  ns <- NS(id)
  choices <- setNames(stock_data()$Code, stock_data()$Item)
  
  tagList(
    h2("➖ Remove Product from Stock"),
    
    actionButton(ns("scan_barcode_button"), "📷 Scan Barcode", class = "btn-primary"),
    verbatimTextOutput(ns("scanned_code_display")),
    
    textInput(ns("manual_code"), "Product Code", placeholder = "Scan or type code..."),
    
    selectInput(
      ns("remove_item"),
      "Select Item to Remove",
      choices = choices,
      selected = NULL
    ),
    
    numericInput(ns("remove_quantity"), "Quantity to Remove", value = 1, min = 1),
    actionButton(ns("remove_button"), "Remove", class = "btn-danger"),
    br(), br(),
    actionButton(ns("to_admin_home"), "⬅ Back to Admin Home"),
    verbatimTextOutput(ns("remove_status"))
  )
}
