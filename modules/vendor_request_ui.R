
vendor_request_ui <- function(id, stock_data) {
  ns <- NS(id)
  tagList(
    h2("📦 Vendor Stock Request"),
    selectInput(ns("item_select"), "Select Item", choices = stock_data()$Item),
    numericInput(ns("quantity_input"), "Quantity to Order", value = 10, min = 1),
    textInput(ns("vendor_email"), "Vendor Email"),
    br(),
    actionButton(ns("send_request"), "📨 Send Vendor Request", class = "btn btn-primary"),
    br(), br(),
    actionButton(ns("back_to_admin"), "Back to Admin Home", class = "btn btn-secondary")
  )
}
