reset_password_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$iframe(
      src = "reset_password.html",
      width = "100%",
      height = "900px",
      frameborder = "0",
      style = "border: none;"
    ),
    tags$script(HTML(glue::glue("
      window.addEventListener('message', function (event) {{
        const data = event.data;
        if (data && data.type === 'reset_password') {{
          Shiny.setInputValue('{ns('new_password')}', data.pass1, {{ priority: 'event' }});
          Shiny.setInputValue('{ns('confirm_new_password')}', data.pass2, {{ priority: 'event' }});
          Shiny.setInputValue('{ns('reset_password_button')}', true, {{ priority: 'event' }});
        }}
        if (data && data.type === 'go_back') {{
          Shiny.setInputValue('{ns('to_login')}', true, {{ priority: 'event' }});
        }}
      }});
    ")))
  )
}
