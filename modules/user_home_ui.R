user_home_ui <- function(id, logged_user) {
  ns <- NS(id)
  name <- isolate(logged_user()$Name)

  tagList(
    div(class = "dashboard-title", paste0("🛒 Welcome ", name)),
    fluidRow(
      column(6, div(class = "dashboard-card", actionBttn(ns("view_prices"), "💵 View Item Prices", style = "material-flat", color = "primary", size = "lg", block = TRUE))),
      column(6, div(class = "dashboard-card", actionBttn(ns("add_to_cart"), "➕ Add to Cart", style = "material-flat", color = "success", size = "lg", block = TRUE)))
    ),
    fluidRow(
      column(6, div(class = "dashboard-card", actionBttn(ns("view_cart"), "🛒 View Cart", style = "material-flat", color = "success", size = "lg", block = TRUE))),
      column(6, div(class = "dashboard-card", actionBttn(ns("checkout"), "🧾 Checkout", style = "material-flat", color = "primary", size = "lg", block = TRUE)))
    ),
    br(),
    actionButton(ns("logout"), "Logout", class = "btn btn-secondary btn-lg")
  )
}
