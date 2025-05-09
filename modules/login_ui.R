login_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$iframe(
      src = "login.html",
      width = "100%",
      height = "100vh",
      frameborder = "0",
      style = "border: none; position: fixed; top: 0; left: 0; width: 100%; height: 100vh;"
    ),
    tags$script(HTML(glue::glue("
      window.addEventListener('message', function(event) {{
        if (event.data && typeof event.data === 'object') {{
          if (event.data.login_user !== undefined) {{
            Shiny.setInputValue('{ns('login-login_user')}', event.data.login_user, {{priority: 'event'}});
          }}
          if (event.data.login_pass !== undefined) {{
            Shiny.setInputValue('{ns('login-login_pass')}', event.data.login_pass, {{priority: 'event'}});
          }}
          if (event.data.to_signup) {{
            Shiny.setInputValue('{ns('login-to_signup')}', true, {{priority: 'event'}});
          }}
          if (event.data.to_forgot) {{
            Shiny.setInputValue('{ns('login-to_forgot_password')}', true, {{priority: 'event'}});
          }}
        }}
      }});
    ")))
  )
}
