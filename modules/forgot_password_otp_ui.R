forgot_password_otp_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$iframe(
      src = "forgot_password_otp.html",
      width = "100%",
      height = "900px",
      frameborder = "0",
      style = "border: none;"
    ),
    tags$script(HTML(glue::glue("
      document.addEventListener('DOMContentLoaded', function () {{
        const verifyBtn = document.querySelector('.verify-btn');
        if (verifyBtn) {{
          verifyBtn.addEventListener('click', function () {{
            const otp = document.getElementById('otp')?.value || '';
            Shiny.setInputValue('{ns('reset_otp_input')}', otp, {{ priority: 'event' }});
            Shiny.setInputValue('{ns('verify_reset_otp_button')}', true, {{ priority: 'event' }});
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
