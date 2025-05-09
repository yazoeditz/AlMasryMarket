admin_otp_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$iframe(
      src = "admin_otp.html",
      width = "100%",
      height = "850px",
      frameborder = "0",
      style = "border: none;"
    ),
    tags$script(HTML(glue::glue('
      window.addEventListener("message", function(event) {{
        if (event.data?.type === "verify_admin_otp") {{
          Shiny.setInputValue("{ns("otp_input")}", event.data.otp, {{ priority: "event" }});
          Shiny.setInputValue("{ns("verify_otp_button")}", true, {{ priority: "event" }});
        }}
        if (event.data?.type === "go_back") {{
          Shiny.setInputValue("{ns("to_login")}", true, {{ priority: "event" }});
        }}
      }});
    ')))
  )
}
