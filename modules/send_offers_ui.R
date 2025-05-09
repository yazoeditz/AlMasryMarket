
send_offers_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h2("🎉 Send Offer to All Users"),
    textInput(ns("offer_title"), "Offer Title"),
    textAreaInput(ns("offer_desc"), "Offer Description", height = "100px"),
    actionButton(ns("send_offer_button"), "Send Offer"),
    br(), br(),
    textOutput(ns("offer_status")),
    actionButton(ns("to_admin_home"), "⬅ Back to Admin Home")
  )
}
