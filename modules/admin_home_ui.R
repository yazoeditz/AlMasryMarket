admin_home_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h2("🏪 Welcome Admin"),
    actionButton(ns("add_stock"), "➕ Add Stock"),
    actionButton(ns("remove_stock"), "➖ Remove Stock"),
    actionButton(ns("view_stock"), "📦 View Stock"),
    actionButton(ns("send_vendor_email"), "📨 Send Vendor Request"),
    actionButton(ns("send_offers"), "🎉 Send Offers"),
    actionBttn(ns("view_offers"), "📜 View Offers", style="material-flat", color="primary", size="lg", block=TRUE),
    actionButton(ns("logout"), "Logout")
  )
}
