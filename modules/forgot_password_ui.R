forgot_password_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$iframe(
      src = "forgot_password.html",
      width = "100%",
      height = "900px",
      frameborder = "0",
      style = "border: none;"
    ),
    tags$script(HTML(glue::glue("
      document.addEventListener('DOMContentLoaded', function () {{
        const sendBtn = document.querySelector('.send-btn');
        if (sendBtn) {{
          sendBtn.addEventListener('click', function () {{
            const email = document.getElementById('forgot_email')?.value || '';
            Shiny.setInputValue('{ns('forgot_email')}', email, {{ priority: 'event' }});
            Shiny.setInputValue('{ns('send_reset_otp')}', true, {{ priority: 'event' }});
          }});
        }}

        const backBtn = document.querySelector('.back-btn');
        if (backBtn) {{
          backBtn.addEventListener('click', function () {{
            Shiny.setInputValue('{ns('to_login')}', true, {{ priority: 'event' }});
          }});
        }}
      }});
    ")))
  )
}
