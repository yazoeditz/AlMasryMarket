view_cart_ui <- function(id, cart_data) {
  ns <- NS(id)
  tagList(
    h2("🛒 Your Cart"),
    DTOutput(ns("cart_table")),
    br(),
    h4(textOutput(ns("total_price_display"))),
    br(),
    actionButton(ns("to_checkout"), "Proceed to Checkout"),
    actionButton(ns("back_to_home"), "Back to Home")
  )
}
