signup_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      style = "width: 100%; height: 850px; overflow-y: auto; border: none;",
      tags$iframe(
        src = "signup.html",
        width = "100%",
        height = "1200px",  # keep enough content height
        frameborder = "0",
        style = "border: none;"
      )
    ),
    tags$script(HTML(glue::glue("
      window.addEventListener('DOMContentLoaded', function () {{
        const signupBtn = document.querySelector('.signup-btn');
        if (signupBtn) {{
          signupBtn.addEventListener('click', function () {{
            const username = document.getElementById('username')?.value || '';
            const email = document.getElementById('email')?.value || '';
            const phone = document.getElementById('phone')?.value || '';
            const pass = document.getElementById('password')?.value || '';
            const confirm = document.getElementById('confirm-password')?.value || '';

            Shiny.setInputValue('{ns('signup-signup_name')}', username);
            Shiny.setInputValue('{ns('signup-signup_email')}', email);
            Shiny.setInputValue('{ns('signup-signup_phone')}', phone);
            Shiny.setInputValue('{ns('signup-signup_password')}', pass);
            Shiny.setInputValue('{ns('signup-signup_confirm')}', confirm);
            Shiny.setInputValue('{ns('signup-signup_role')}', 'user');
            Shiny.setInputValue('{ns('signup-signup_button')}', true, {{priority: 'event'}});
          }});
        }}
      }});
    ")))
  )
}
