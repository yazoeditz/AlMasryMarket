checkout_ui <- function(id, cart_data) {
  ns <- NS(id)
  tagList(
    h2("🧾 Invoice"),
    
    # Cart Table
    tableOutput(ns("receipt_table")),
    tags$hr(),
    
    # Optional Scan for last item (if needed)
    fluidRow(
      column(6, actionButton(ns("scan_item"), "📷 Scan Item", class = "btn-success")),
      column(6, actionButton(ns("stop_scanning_button"), "🛑 Stop Camera", class = "btn-danger"))
    ),
    textOutput(ns("scanned_code_checkout")),
    tags$hr(),

    # Receipt Summary
    uiOutput(ns("receipt_ui")),

    # Final Actions
    fluidRow(
      column(6, actionButton(ns("print_receipt"), "🖨️ Print", class = "btn-primary")),
      column(6, actionButton(ns("back_to_home"), "⬅ Back to Home", class = "btn-secondary"))
    )
  )
}
