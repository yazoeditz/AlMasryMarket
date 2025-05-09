# ------------------------------
# 📚 Load Required Libraries
# ------------------------------
library(shiny)
library(shinyWidgets)
library(digest)
library(DT)
library(reticulate)
library(png)
library(grid)
library(gridExtra)
library(barcode)
library(dplyr)
library(filelock)

# ------------------------------
# 🐍 Load Python Script
# ------------------------------
Sys.setenv(RETICULATE_PYTHON = "~/.virtualenvs/r-reticulate/bin/python")
Sys.setenv(ZBAR_LIB_PATH = "/opt/homebrew/lib/libzbar.dylib")
Sys.setenv(DYLD_LIBRARY_PATH = "/opt/homebrew/lib")
source_python("email_utils.py")
source_python("scanner.py")
source("modules/login_ui.R")
source("modules/signup_ui.R")
source("modules/user_home_ui.R")
source("modules/admin_home_ui.R")
source("modules/forgot_password_ui.R")
source("modules/forgot_password_otp_ui.R")
source("modules/reset_password_ui.R")
source("modules/admin_signup_otp_ui.R")
source("modules/admin_otp_ui.R")
source("modules/view_cart_ui.R")
source("modules/checkout_ui.R")
source("modules/view_prices_ui.R")
source("modules/add_to_cart_ui.R")
source("modules/add_product_ui.R")
source("modules/view_stock_ui.R")
source("modules/remove_stock_ui.R")
source("modules/send_offers_ui.R")
source("modules/view_offers_ui.R")
source("modules/vendor_request_ui.R")


# ------------------------------
# 📂 Initialize CSV Databases
# ------------------------------
if (!file.exists("users.csv")) {
  write.csv(data.frame(Name=character(), Email=character(), Phone=character(), Password=character(), stringsAsFactors=FALSE), "users.csv", row.names=FALSE)
}
if (!file.exists("admins.csv")) {
  write.csv(data.frame(Name=character(), Email=character(), Phone=character(), Password=character(), stringsAsFactors=FALSE), "admins.csv", row.names=FALSE)
}
if (!file.exists("stock.csv")) {
  write.csv(data.frame(
    Code = character(),
    Item = character(),
    Price = numeric(),
    Quantity = numeric(),
    stringsAsFactors = FALSE
  ), "stock.csv", row.names = FALSE)
}
if (!file.exists("offers.csv")) {
  write.csv(data.frame(
    Title = character(),
    Description = character(),
    ViewCount = numeric(),
    EmailSentCount = numeric(),
    stringsAsFactors = FALSE
  ), "offers.csv", row.names = FALSE)
}

# ------------------------------
# 🧠 Global State
# ------------------------------
logged_user <- reactiveVal(NULL)
admin_pending_otp <- reactiveVal(NULL)
pending_admin_signup <- reactiveVal(NULL)
admin_signup_otp <- reactiveVal(NULL)
reset_email <- reactiveVal(NULL)
reset_pending_otp <- reactiveVal(NULL)
current_page <- reactiveVal("login")
cart_data <- reactiveVal(data.frame(Item=character(), Price=numeric(), Quantity=numeric(), stringsAsFactors=FALSE))
stock_data <- reactiveVal(read.csv("stock.csv", stringsAsFactors = FALSE))

scan_code_in_r <- function() {
  tryCatch({
    code <- scan_code()
    return(code)
  }, error = function(e) {
    showNotification("Error scanning code", type = "error")
    return("")
  })
}

# ------------------------------
# 🔐 Auth Helpers
# ------------------------------
hash_password <- function(password) {
  digest(password, algo="sha256")
}

load_users <- function() {
  lock <- lock("users.csv")
  on.exit(unlock(lock))
  read.csv("users.csv", stringsAsFactors = FALSE)
}

save_users <- function(df) {
  lock <- lock("users.csv")
  on.exit(unlock(lock))
  write.csv(df, "users.csv", row.names = FALSE)
}

load_admins <- function() {
  lock <- lock("admins.csv")
  on.exit(unlock(lock))
  read.csv("admins.csv", stringsAsFactors = FALSE)
}

save_admins <- function(df) {
  lock <- lock("admins.csv")
  on.exit(unlock(lock))
  write.csv(df, "admins.csv", row.names = FALSE)
}

# 📷 Scanner Helper
scan_barcode <- function() {
  tryCatch({
    result <- py$scan_from_camera()
    cat("Scanned result: ", result, "\n")  # log to R console
    return(result)
  }, error = function(e) {
    showNotification("❌ Failed to scan barcode: Check your camera or Python env", type = "error")
    return(NULL)
  })
}

# 🛑 Stop Scanner Helper
stop_scan <- function() {
  tryCatch({
    py$stop_scanning()
  }, error = function(e) {
    showNotification("⚠️ Could not stop scanning", type = "warning")
  })
}

# 📏 Normalize barcode (handles UPC-A to EAN-13 conversion)
normalize_barcode <- function(code) {
  if (!is.null(code) && nchar(code) == 13 && startsWith(code, "0")) {
    return(substr(code, 2, 13))  # strip leading zero
  }
  return(code)
}

# ------------------------------
# 🌐 UI Wrapper
# ------------------------------
ui <- fluidPage(
  tags$head(tags$style(HTML("
    html, body, .container-fluid {
      margin: 0 !important;
      padding: 0 !important;
      height: 100% !important;
      overflow: hidden;
      background-color: #ffffff;
    }
  "))),
  uiOutput("main_page")
)

# ------------------------------
# 🚚 Server Logic
# ------------------------------
server <- function(input, output, session) {
  
  scanned_code <- reactiveVal(NULL)
  
  observeEvent(input$`checkout-scan_item`, {
    showNotification("🔍 Opening camera for scanning...", duration = 2)
    result <- scan_barcode()
    result <- normalize_barcode(result)  # 🔄 this replaces scan_qr_code()
    if (!is.null(result) && nzchar(result)) {
      showNotification(paste("✅ Scanned:", result), type = "message")
      scanned_code(result)
      
      # Lookup stock and add to cart
      stock <- stock_data()
      matched <- stock[stock$Code == result, ]
      if (nrow(matched) > 0) {
        price <- matched$Price
        new_entry <- data.frame(Item = matched$Item, Price = price, Quantity = 1, stringsAsFactors = FALSE)
        cart_data(rbind(cart_data(), new_entry))
        showNotification(paste("✅", result, "added to cart."), type = "message")
      } else {
        showNotification("❌ Scanned item not found in stock.", type = "error")
      }
    } else {
      showNotification("❌ No QR/barcode detected.", type = "error")
    }
  })
  
  output$main_page <- renderUI({
    switch(current_page(),
           "login" = login_ui("login"),
           "signup" = signup_ui("signup"),
           "user_home" = user_home_ui("user_ui", logged_user),
           "admin_home" = admin_home_ui("admin_home_ui"),
           "admin_signup_otp" = admin_signup_otp_ui("admin_signup"),
           "admin_otp" = admin_otp_ui("admin_otp"),
           "forgot_password_request" = forgot_password_ui("forgot_password"),
           "forgot_password_otp" = forgot_password_otp_ui("otp_verify"),
           "reset_password" = reset_password_ui("reset_pass"),
           "view_cart" = view_cart_ui("cart_view", cart_data),
           "view_prices" = view_prices_ui("prices"),
           "checkout" = checkout_ui("checkout", cart_data),
           "add_to_cart" = {
             stock_data(read.csv("stock.csv", stringsAsFactors = FALSE))  # Force reload
             add_to_cart_ui("add_cart", stock_data)
           },
           "add_product" = add_product_ui("add_product", stock_data),
           "view_stock" = view_stock_ui("view_stock", stock_data),
           "remove_stock" = remove_stock_ui("remove_stock", stock_data),
           "send_offers" = send_offers_ui("send_offers"),
           "vendor_request" = vendor_request_ui("vendor", stock_data),
           "view_offers" = view_offers_ui("view_offers"),
           h2("Loading...")
    )
  })
  
  # Navigation Events
  observeEvent(input$`login-to_signup`, current_page("signup"))
  observeEvent(input$`login-to_forgot_password`, current_page("forgot_password_request"))
  observeEvent(input$`signup-to_login`, current_page("login"))
  observeEvent(input$`forgot-to_login`, current_page("login"))
  observeEvent(input$to_login, current_page("login"))

  
  # Admin Home Events
  observeEvent(input$`admin_home_ui-logout`, { logged_user(NULL); current_page("login") })
  observeEvent(input$`admin_home_ui-add_stock`, showNotification("\u2795 Add Stock clicked"))
  observeEvent(input$`admin_home_ui-remove_stock`, showNotification("\u2796 Remove Stock clicked"))
  observeEvent(input$`admin_home_ui-view_stock`, showNotification("\ud83d\udce6 View Stock clicked"))
  observeEvent(input$`admin_home_ui-send_vendor_email`, showNotification("\ud83d\udce8 Vendor email triggered"))
  observeEvent(input$`admin_home_ui-send_offers`, showNotification("\ud83c\udf89 Offers triggered"))
  
  # Forgot Password OTP
  observeEvent(input$`forgot_password-to_login`, current_page("login"))
  observeEvent(input$`forgot_password-send_reset_otp`, {
    email <- input$`forgot_password-forgot_email`
    users <- load_users()
    admins <- load_admins()
    
    if (email %in% users$Email || email %in% admins$Email) {
      reset_email(email)
      otp <- sprintf("%06d", sample(0:999999, 1))
      reset_pending_otp(list(otp=otp, timestamp=Sys.time()))
      send_password_reset_email(email, otp)
      showNotification("\u2705 OTP sent to your email")
      current_page("forgot_password_otp")
    } else {
      showNotification("\u274c Email not found", type="error")
    }
  })
  
  observeEvent(input$`add_product-stop_scanning_button`, {
    stop_scan()
    showNotification("🛑 Camera stopped", type = "message")
  })
  
  observeEvent(input$`otp_verify-verify_reset_otp_button`, {
    otp_input <- input$`otp_verify-reset_otp_input`
    otp_info <- reset_pending_otp()
    
    if (!is.null(otp_info) && otp_input == otp_info$otp && difftime(Sys.time(), otp_info$timestamp, units="mins") < 5) {
      current_page("reset_password")
    } else {
      showNotification("\u274c Invalid or expired OTP", type="error")
    }
  })
  
  observeEvent(input$`reset_pass-reset_password_button`, {
    pass1 <- input$`reset_pass-new_password`
    pass2 <- input$`reset_pass-confirm_new_password`
    email <- reset_email()
    
    if (pass1 != pass2) {
      showNotification("\u274c Passwords do not match", type="error")
      return()
    }
    if (nchar(pass1) < 8 || !grepl("[^A-Za-z0-9]", pass1)) {
      showNotification("\u274c Weak password", type="error")
      return()
    }
    
    users <- load_users()
    admins <- load_admins()
    
    if (email %in% users$Email) {
      users$Password[users$Email == email] <- hash_password(pass1)
      save_users(users)
    } else if (email %in% admins$Email) {
      admins$Password[admins$Email == email] <- hash_password(pass1)
      save_admins(admins)
    }
    
    showNotification("\u2705 Password reset successful")
    current_page("login")
  })
  
  # Admin Signup OTP Verification
  observeEvent(input$`admin_signup-to_login`, current_page("login"))
  observeEvent(input$`admin_signup-verify_admin_signup_otp_button`, {
    otp_info <- admin_signup_otp()
    if (!is.null(otp_info)) {
      if (input$`admin_signup-admin_signup_otp_input` == otp_info$otp &&
          difftime(Sys.time(), otp_info$timestamp, units = "mins") < 5) {
        admins <- load_admins()
        new_admin <- pending_admin_signup()
        
        # Normalize email for comparison
        new_admin_email <- tolower(trimws(new_admin$Email))
        admins$Email <- tolower(trimws(admins$Email))
        
        if (new_admin_email %in% admins$Email) {
          showNotification("⚠️ Admin already registered.", type = "warning")
        } else {
          new_admin_df <- data.frame(
            Name = new_admin$Name,
            Email = new_admin$Email,
            Phone = new_admin$Phone,
            Password = new_admin$Password,
            stringsAsFactors = FALSE
          )
          admins <- rbind(admins, new_admin_df)
          save_admins(admins)
          showNotification("✅ Admin Registered Successfully!", type = "message")
        }
        
        # Cleanup
        pending_admin_signup(NULL)
        admin_signup_otp(NULL)
        current_page("login")
        showNotification("\u2705 Admin Registered Successfully!", type="message")
        current_page("login")
      } else {
        showNotification("\u274c Invalid or expired OTP.", type="error")
      }
    } else {
      showNotification("\u274c No pending admin registration.", type="error")
    }
  })
  
  # Admin OTP Login Verification
  observeEvent(input$`admin_otp-to_login`, current_page("login"))
  observeEvent(input$`login-login_button`, {
    entered_email <- input$`login-login_email`
    entered_password <- hash_password(input$`login-login_password`)
    
    users <- load_users()
    admins <- load_admins()
    
    # First, check if user email exists and password matches
    user_row <- users[users$Email == entered_email & users$Password == entered_password, ]
    if (nrow(user_row) == 1) {
      logged_user(user_row)
      current_page("user_home")
      return()
    }
    
    # Then, check admin credentials
    admin_row <- admins[admins$Email == entered_email & admins$Password == entered_password, ]
    if (nrow(admin_row) == 1) {
      logged_user(admin_row)
      otp <- sprintf("%06d", sample(0:999999, 1))
      admin_pending_otp(list(email = entered_email, otp = otp, timestamp = Sys.time()))
      send_otp_email(entered_email, otp)
      current_page("admin_otp")
    } else {
      showNotification("❌ Invalid credentials!", type = "error")
    }
  })
  
  # Support for new HTML login buttons
  observeEvent(input$`login-ui-go_to_signup`, {
    current_page("signup")
  })
  
  observeEvent(input$`login-ui-go_to_forgot_password`, {
    current_page("forgot_password_request")
  })
  
  observeEvent(input$`login-login_user`, {
    entered_email <- tolower(trimws(input$`login-login_user`))
    entered_password <- hash_password(trimws(input$`login-login_pass`))
    
    users <- isolate(load_users())
    admins <- isolate(load_admins())
    
    users$Email <- tolower(trimws(users$Email))
    admins$Email <- tolower(trimws(admins$Email))
    
    admin_row <- admins[admins$Email == entered_email & admins$Password == entered_password, ]
    user_row  <- users[users$Email == entered_email & users$Password == entered_password, ]
    
    if (nrow(admin_row) == 1) {
      logged_user(admin_row)
      otp <- sprintf("%06d", sample(0:999999, 1))
      admin_pending_otp(list(email = entered_email, otp = otp, timestamp = Sys.time()))
      send_otp_email(entered_email, otp)
      current_page("admin_otp")
    } else if (nrow(user_row) == 1) {
      logged_user(user_row)
      current_page("user_home")
    } else {
      showNotification("❌ Invalid credentials!", type = "error")
    }
  })
  
  observeEvent(input$`signup-signup_button`, {
    name <- input$`signup-signup_name`
    email <- input$`signup-signup_email`
    phone <- input$`signup-signup_phone`
    pass1 <- input$`signup-signup_password`
    pass2 <- input$`signup-signup_confirm`
    role <- input$`signup-signup_role`
    
    if (pass1 != pass2) {
      showNotification("❌ Passwords do not match!", type = "error")
      return()
    }
    if (nchar(pass1) < 8 || !grepl("[^A-Za-z0-9]", pass1)) {
      showNotification("❌ Password must be at least 8 characters and include a special character!", type = "error")
      return()
    }
    
    if (role == "admin") {
      pending_admin_signup(list(
        Name = name,
        Email = email,
        Phone = phone,
        Password = hash_password(pass1)
      ))
      otp <- sprintf("%06d", sample(0:999999, 1))
      admin_signup_otp(list(otp = otp, timestamp = Sys.time()))
      send_otp_email("elmasrymarketstore@gmail.com", otp)
      current_page("admin_signup_otp")
    } else {
      users <- load_users()
      if (email %in% users$Email) {
        showNotification("❌ Email already registered as User.", type = "error")
        return()
      }
      new_user <- data.frame(Name = name, Email = email, Phone = phone, Password = hash_password(pass1), stringsAsFactors = FALSE)
      users <- rbind(users, new_user)
      save_users(users)
      showNotification("✅ User Registered Successfully!", type = "message")
      current_page("login")
    }
  })
  
  observeEvent(input$`user_ui-view_prices`, current_page("view_prices"))
  observeEvent(input$`prices-back_to_home`, current_page("user_home"))
  
  output$`prices-prices_table` <- DT::renderDataTable({
    read.csv("stock.csv", stringsAsFactors = FALSE)
  })
  
  observeEvent(input$`user_ui-add_to_cart`, current_page("add_to_cart"))
  
  output$`add_cart-item_selector_ui` <- renderUI({
    stock <- read.csv("stock.csv", stringsAsFactors = FALSE)
    if (nrow(stock) == 0) return("⚠ No items available")
    selectInput("add_cart-item", "Choose Item", choices = stock$Item)
  })
  
  observeEvent(input$`add_cart-add_button`, {
    code <- input$`add_cart-scanned_code`
    quantity <- input$`add_cart-quantity`
    
    stock <- stock_data()  # ✅ safe here
    matched <- stock[stock$Code == code, ]
    
    if (nrow(matched) == 0) {
      showNotification("❌ Product code not found", type = "error")
      return()
    }
    
    available_qty <- matched$Quantity
    if (quantity > available_qty) {
      showNotification(paste("❌ Only", available_qty, "available in stock."), type = "error")
      return()
    }
    
    item <- matched$Item
    price <- matched$Price
    new_entry <- data.frame(Item = item, Price = price, Quantity = quantity, stringsAsFactors = FALSE)
    cart_data(rbind(cart_data(), new_entry))
    
    showNotification(paste("✅", quantity, item, "added to cart"))
    updateTextInput(session, "add_cart-scanned_code", value = "")
  })
  
  observeEvent(input$`add_cart-to_user_home`, {
    current_page("user_home")
  })
  observeEvent(input$`user_ui-view_cart`, current_page("view_cart"))
  
  observeEvent(input$`cart_view-back_to_home`, current_page("user_home"))
  observeEvent(input$`cart_view-to_checkout`, current_page("checkout"))
  
  output$`cart_view-cart_table` <- renderDT({
    datatable(cart_data(), options = list(pageLength = 5))
  })
  
  output$`cart_view-total_price_display` <- renderText({
    df <- cart_data()
    if (nrow(df) == 0) return("Total: $0.00")
    total <- sum(df$Price * df$Quantity)
    paste0("Total: $", format(total, nsmall = 2))
  })
  
  observeEvent(input$`checkout-back_to_home`, {
    cart_data(data.frame(Item=character(), Price=numeric(), Quantity=numeric(), stringsAsFactors=FALSE))
    current_page("user_home")
  })
  
  observeEvent(input$`checkout-print_receipt`, {
    df <- cart_data()
    if (nrow(df) == 0) {
      showNotification("❌ Cart is empty.", type = "error")
      return()
    }
    
    # 👇 Add here
    stock <- stock_data()
    for (i in seq_len(nrow(df))) {
      item_name <- df$Item[i]
      qty_to_deduct <- df$Quantity[i]
      idx <- which(stock$Item == item_name)
      if (length(idx) == 1 && stock$Quantity[idx] >= qty_to_deduct) {
        stock$Quantity[idx] <- stock$Quantity[idx] - qty_to_deduct
      } else {
        showNotification(paste("❌ Not enough stock for:", item_name), type = "error")
        return()
      }
    }
    stock_data(stock)
    write.csv(stock, "stock.csv", row.names = FALSE)
    
    df$Total <- df$Price * df$Quantity
    subtotal <- sum(df$Total)
    tax <- round(subtotal * 0.14, 2)  # 14% tax
    grand_total <- subtotal + tax
    
    # Create receipts directory if it doesn't exist
    if (!dir.exists("receipts")) dir.create("receipts")
    
    # Generate barcode-safe numeric timestamp
    timestamp_code <- format(Sys.time(), "%Y%m%d%H%M%S")
    numeric_code <- as.numeric(substr(timestamp_code, 9, 14))  # use only HHMMSS
    
    pdf_file <- file.path("receipts", paste0("receipt_INV_", timestamp_code, ".pdf"))
    barcode_file <- file.path("assets", "barcode.png")
    
    # Save barcode as PNG
    png(barcode_file, width = 400, height = 100)
    par(mar = c(0, 0, 0, 0))
    # Generate barcode-safe numeric timestamp
    timestamp_code <- format(Sys.time(), "%Y%m%d%H%M%S")
    numeric_code <- as.numeric(substr(timestamp_code, 9, 14))  # Use only time portion
    
    pdf_file <- file.path("receipts", paste0("receipt_INV_", timestamp_code, ".pdf"))
    barcode_file <- file.path("assets", "barcode.png")
    
    # Generate fake barcode pattern manually (basic black-white stripes)
    barcode_matrix <- matrix(rep(c(0, 1), length.out = 400), ncol = 400, nrow = 100, byrow = TRUE)
    barcode_matrix <- barcode_matrix[sample(1:100, 100), ]  # Add randomness to simulate real barcode
    
    # Save manually as PNG
    png(barcode_file)
    par(mar = c(0, 0, 0, 0))
    grid::grid.raster(barcode_matrix, interpolate = FALSE)
    dev.off()
    
    # Generate PDF receipt
    pdf(pdf_file, width = 7, height = 10)
    grid.newpage()
    
    if (file.exists("assets/logo.png")) {
      logo <- png::readPNG("assets/logo.png")
      grid.raster(logo, x = 0.1, y = 0.93, width = 0.2)
    }
    
    grid.text("Al Masry Market Receipt", x = 0.5, y = 0.88, gp = gpar(fontsize = 18, fontface = "bold"))
    grid.text(paste("Date:", Sys.Date()), x = 0.5, y = 0.84, gp = gpar(fontsize = 12))
    
    table <- gridExtra::tableGrob(df[, c("Item", "Price", "Quantity", "Total")], rows = NULL)
    grid.draw(table)
    
    grid.text(paste("Subtotal: $", format(subtotal, nsmall = 2)), x = 0.5, y = 0.25, gp = gpar(fontsize = 12))
    grid.text(paste("Tax (14%): $", format(tax, nsmall = 2)), x = 0.5, y = 0.22, gp = gpar(fontsize = 12))
    grid.text(paste("Total: $", format(grand_total, nsmall = 2)), x = 0.5, y = 0.18, gp = gpar(fontsize = 14, fontface = "bold"))
    
    if (file.exists(barcode_file)) {
      barcode_img <- png::readPNG(barcode_file)
      grid.raster(barcode_img, x = 0.5, y = 0.01, width = 0.4)
    }
    
    dev.off()
    browseURL(pdf_file)
    showNotification(paste("✅ Receipt saved as", basename(pdf_file)), type = "message")
  })
  
  output$`checkout-receipt_table` <- renderTable({
    df <- cart_data()
    df$Total <- df$Price * df$Quantity
    df
  })
  
  observeEvent(input$`user_ui-checkout`, {
    current_page("checkout")
  })
  
  observeEvent(input$`user_ui-logout`, {
    logged_user(NULL)
    current_page("login")
  })
  
  observeEvent(input$`otp_verify-to_login`, {
    current_page("login")
  })
  
  observeEvent(input$`admin_home_ui-add_stock`, {
    current_page("add_product")
  })
  
  observeEvent(input$`add_product-submit_product`, {
    name <- input$`add_product-product_name`
    price <- input$`add_product-product_price`
    quantity <- input$`add_product-product_quantity`
    
    if (name == "" || is.na(price) || is.na(quantity) || price <= 0 || quantity <= 0) {
      output$`add_product-add_status` <- renderText("❌ Please enter valid product details.")
      return()
    }
    
    df <- stock_data()
    df <- rbind(df, data.frame(Item = name, Price = price, Quantity = quantity, stringsAsFactors = FALSE))
    write.csv(df, "stock.csv", row.names = FALSE)
    stock_data(df)  # update reactiveVal
    output$`add_product-add_status` <- renderText("✅ Product added successfully.")
  })
  
  observeEvent(input$`add_product-back_to_admin_home`, {
    current_page("admin_home")
  })
  
  observeEvent(input$`admin_otp-verify_otp_button`, {
    otp_info <- admin_pending_otp()
    if (!is.null(otp_info)) {
      if (input$`admin_otp-otp_input` == otp_info$otp &&
          difftime(Sys.time(), otp_info$timestamp, units = "mins") < 5) {
        current_page("admin_home")
        showNotification("✅ OTP Verified Successfully!", type = "message")
      } else {
        showNotification("❌ Invalid or expired OTP.", type = "error")
      }
    } else {
      showNotification("❌ No OTP pending.", type = "error")
    }
  })
  
  observeEvent(input$`admin_otp-to_login`, current_page("login"))
  
  observeEvent(input$`add_product-to_admin_home`, {
    current_page("admin_home")
  })
  
  observeEvent(input$`add_product-confirm_add`, {
    code <- input$`add_product-barcode`  # this must be scanned before confirming
    item <- input$`add_product-item_name`
    price <- input$`add_product-item_price`
    qty <- input$`add_product-item_quantity`
    
    # Validation
    if (item == "" || is.na(price) || is.na(qty) || price <= 0 || qty <= 0 || code == "") {
      output$`add_product-add_status` <- renderText("❌ Please enter all product fields and scan the code.")
      return()
    }
    
    # Load and append
    stock <- stock_data()
    new_row <- data.frame(Code = code, Item = item, Price = price, Quantity = qty, stringsAsFactors = FALSE)
    updated_stock <- rbind(stock, new_row)
    write.csv(updated_stock, "stock.csv", row.names = FALSE)
    stock_data(updated_stock)
    
    output$`add_product-add_status` <- renderText("✅ Product added successfully.")
  })
  
  observeEvent(input$`admin_home_ui-view_stock`, {
    current_page("view_stock")
  })
  
  observeEvent(input$`view_stock-to_admin_home`, {
    current_page("admin_home")
  })
  
  observeEvent(input$`view_stock-refresh_stock`, {
    updated_stock <- read.csv("stock.csv", stringsAsFactors = FALSE)
    stock_data(updated_stock)
    showNotification("🔄 Stock list refreshed from disk.", type = "message")
  })
  
  output$`view_stock-stock_table` <- DT::renderDataTable({
    stock_data()
  })
  
  observeEvent(input$`admin_home_ui-remove_stock`, {
    current_page("remove_stock")
  })
  
  observeEvent(input$`remove_stock-to_admin_home`, {
    current_page("admin_home")
  })
  
  observeEvent(input$`remove_stock-remove_button`, {
    code <- input$`remove_stock-remove_item`  # This is CODE now
    qty <- input$`remove_stock-remove_quantity`
    
    current_stock <- stock_data()
    idx <- which(current_stock$Code == code)
    
    if (length(idx) == 1) {
      current_qty <- current_stock$Quantity[idx]
      if (qty >= current_qty) {
        current_stock <- current_stock[-idx, ]
      } else {
        current_stock$Quantity[idx] <- current_qty - qty
      }
      stock_data(current_stock)
      write.csv(current_stock, "stock.csv", row.names = FALSE)
      output$`remove_stock-remove_status` <- renderText("✅ Stock updated.")
    } else {
      output$`remove_stock-remove_status` <- renderText("❌ Item not found.")
    }
  })
  
  observeEvent(input$`admin_home_ui-send_offers`, current_page("send_offers"))
  
  observeEvent(input$`send_offers-to_admin_home`, current_page("admin_home"))
  
  observeEvent(input$`send_offers-send_offer_button`, {
    title <- input$`send_offers-offer_title`
    desc <- input$`send_offers-offer_desc`
    
    if (nchar(title) == 0 || nchar(desc) == 0) {
      output$`send_offers-offer_status` <- renderText("❌ Both title and description required.")
      return()
    }
    
    users <- load_users()
    
    # Save to offers.csv
    offers <- read.csv("offers.csv", stringsAsFactors = FALSE)
    new_offer <- data.frame(
      Title = title,
      Description = desc,
      ViewCount = 0,
      EmailSentCount = nrow(users),
      stringsAsFactors = FALSE
    )
    offers <- rbind(offers, new_offer)
    write.csv(offers, "offers.csv", row.names = FALSE)
    
    # Email to users
    users <- load_users()
    for (email in users$Email) {
      subject <- paste("🛍️ New Offer:", title)
      body <- paste("Hello,", "\n\nWe have a new offer for you:\n\n", desc, "\n\nEnjoy shopping!\nAl Masry Market")
      send_email(email, subject, body)
    }
    
    output$`send_offers-offer_status` <- renderText("✅ Offer sent to all users.")
  })

# --- Vendor Request Logic ---
observeEvent(input$`admin_home_ui-send_vendor_email`, {
  current_page("vendor_request")
})

observeEvent(input$`vendor-send_request`, {
  item <- input$`vendor-item_select`
  quantity <- input$`vendor-quantity_input`
  email <- input$`vendor-vendor_email`
  
  if (!is.null(item) && !is.null(email) && email != "") {
    send_vendor_request_email(email, item, quantity)
    showNotification("✅ Vendor request sent!", type = "message")
    current_page("admin_home")
  } else {
    showNotification("❌ Please fill in all fields.", type = "error")
  }
})

# Show Offers Table in View Offers Page
output$`view_offers-offers_table` <- DT::renderDataTable({
  read.csv("offers.csv", stringsAsFactors = FALSE)
})

observeEvent(input$`vendor-back_to_admin`, {
  current_page("admin_home")
})

observeEvent(input$`admin_home_ui-view_offers`, {
  current_page("view_offers")
})

observeEvent(input$`view_offers-back_to_admin`, {
  current_page("admin_home")
})

observe({
  if (current_page() == "view_offers") {
    offers <- read.csv("offers.csv", stringsAsFactors = FALSE)
    offers$ViewCount <- offers$ViewCount + 1
    write.csv(offers, "offers.csv", row.names = FALSE)
  }
})

output$`checkout-receipt_ui` <- renderUI({
  df <- cart_data()
  if (nrow(df) == 0) return(h4("Your cart is empty."))
  
  df$Total <- df$Price * df$Quantity
  subtotal <- sum(df$Total)
  tax <- round(subtotal * 0.14, 2)
  grand_total <- round(subtotal + tax, 2)
  
  tagList(
    h4(paste("📦 Last Scanned:", scanned_code())),
    tableOutput(NS("checkout")("receipt_table")),
    tags$hr(),
    h5(paste0("Subtotal: $", format(subtotal, nsmall = 2))),
    h5(paste0("Tax (14%): $", format(tax, nsmall = 2))),
    h4(paste0("Total: $", format(grand_total, nsmall = 2)))
  )
})

observeEvent(input$`add_product-scan_barcode_button`, {
  result <- scan_barcode()
  result <- normalize_barcode(result)
  if (!is.null(result)) {
    updateTextInput(session, "add_product-barcode", value = result)
    output$`add_product-scanned_barcode_display` <- renderText(paste("✅ Barcode:", result))
  } else {
    output$`add_product-scanned_barcode_display` <- renderText("❌ No barcode detected.")
  }
})


observeEvent(input$`add_product-scan_item`, {
  showNotification("🔍 Scanning product code...", duration = 2)
  result <- scan_barcode()
  result <- normalize_barcode(result)
  if (!is.null(result) && nzchar(result)) {
    updateTextInput(session, "add_product-item_name", value = result)
    showNotification(paste("✅ Scanned:", result), type = "message")
  } else {
    showNotification("❌ No QR/barcode detected.", type = "error")
  }
})


observeEvent(input$`add_cart-start_scan`, {
  showNotification("🔍 Starting camera for scanning...", duration = 2)
  result <- scan_barcode()
  result <- normalize_barcode(result)
  if (!is.null(result)) {
    updateTextInput(session, "add_cart-scanned_code", value = result)
    output$`add_cart-scan_status` <- renderText(paste("✅ Scanned:", result))
    
    stock <- stock_data()
    if (result %in% stock$Code) {
      updateSelectInput(session, "add_cart-item", selected = result)
    }
  } else {
    output$`add_cart-scan_status` <- renderText("❌ No barcode detected.")
  }
})

observe({
  code <- input$`add_cart-scanned_code`
  stock <- stock_data()
  if (!is.null(code) && code %in% stock$Code) {
    updateSelectInput(session, "add_cart-item", selected = code)
  }
})

observeEvent(input$`add_cart-cancel_scan`, {
  stop_scan()
  output$`add_cart-scan_status` <- renderText("🛑 Scan cancelled.")
})

observeEvent(input$`remove_stock-scan_barcode_button`, {
  result <- scan_barcode()
  result <- normalize_barcode(result)
  stock <- stock_data()
  if (!is.null(result)) {
    updateTextInput(session, "remove_stock-manual_code", value = result)
    
    if (result %in% stock$Code) {
      updateSelectInput(session, "remove_stock-remove_item", selected = result)
      output$`remove_stock-scanned_code_display` <- renderText(paste("✅ Scanned:", result))
    } else {
      output$`remove_stock-scanned_code_display` <- renderText("❌ Code not found in stock.")
    }
  } else {
    output$`remove_stock-scanned_code_display` <- renderText("❌ No barcode detected.")
  }
})

observe({
  code <- input$`remove_stock-manual_code`
  stock <- stock_data()
  if (!is.null(code) && code %in% stock$Code) {
    updateSelectInput(session, "remove_stock-remove_item", selected = code)
  }
})

observe({
  code <- normalize_barcode(input$`add_cart-scanned_code`)
  stock <- stock_data()
  if (!is.null(code) && code %in% stock$Code) {
    updateSelectInput(session, "add_cart-item", selected = code)
  }
})

observeEvent(input$`user_ui-message`, {
  msg <- input$`user_ui-message`
  
  if (!is.null(msg$type)) {
    switch(msg$type,
           "view_prices" = current_page("view_prices"),
           "add_to_cart" = current_page("add_to_cart"),
           "view_cart" = current_page("view_cart"),
           "checkout" = current_page("checkout"),
           "logout" = {
             logged_user(NULL)
             current_page("login")
           }
    )
  }
})

}

# ------------------------------
# 🚀 Launch App
# ------------------------------
shinyApp(ui, server)