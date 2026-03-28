Here is a detailed, professional `README.md` file tailored for your project based on the provided files. You can copy and paste this directly into a `README.md` file in your repository.

***

# 🛒 Al Masry Market - POS & Store Management System

**Al Masry Market** is a comprehensive, interactive Point of Sale (POS) and inventory management web application built using **R (Shiny)** and **Python**. Designed for supermarkets and retail stores, this platform bridges a robust R-based frontend and analytical engine with a Python-powered backend for real-time camera barcode scanning and automated email communications.

---

## ✨ Key Features

### 🔐 Secure Authentication & Authorization
* **Role-Based Access Control (RBAC):** Distinct dashboards and capabilities for **Admins** and **Users**.
* **Password Hashing:** Passwords are encrypted using SHA-256 (`digest` package) before being stored.
* **OTP Email Verification:** Multi-factor authentication via email One-Time Passwords (OTPs) for admin logins, new admin signups, and password resets.

### 👤 User/Customer Portal
* **Browse Stock:** View available items and real-time prices.
* **Smart Shopping Cart:** Add items manually or by **scanning barcodes** via the device camera.
* **Checkout & Receipts:** Automatically calculate sub-totals, taxes (14%), and grand totals. Generates and downloads a custom **PDF receipt** with a dynamically generated barcode.

### 🏪 Admin Dashboard
* **Inventory Management:** Add new stock (with barcode mapping), remove stock, and view real-time inventory tables.
* **Vendor Restock Requests:** Automatically draft and send email requests to vendors when stock is low.
* **Marketing & Offers:** Draft promotional offers and blast them via email to all registered users.
* **Live Scanning Engine:** Admins can scan physical items to instantly add them to the system's database.

### 📸 Real-Time Barcode Scanning
* Integrated Python script (`scanner.py`) utilizing **OpenCV** and **PyZbar** to capture video feed, decode barcodes/QR codes, and pass the normalized data back to the R application via the `reticulate` package.

---

## 🛠️ Tech Stack

**Frontend / UI:**
* **R Shiny:** Core web framework (`app.R`).
* **HTML/CSS/JS:** Custom-styled interfaces leveraging iframes for modular authentication pages (`www/` directory).
* **shinyWidgets & DT:** Enhanced UI inputs and interactive data tables.

**Backend / Logic:**
* **R:** Application state management, PDF generation (`grid`, `png`), and data handling (`dplyr`).
* **Python:** * `cv2` (OpenCV) & `pyzbar` for barcode processing.
  * `smtplib` & `email.mime` for automated SMTP email handling.
* **reticulate:** Seamless integration between the R environment and Python scripts.

**Database:**
* **Local CSV Storage:** Lightweight data persistence using localized CSV files (`users.csv`, `admins.csv`, `stock.csv`, `offers.csv`) managed with file locking (`filelock`) to prevent race conditions.

---

## 📂 Project Architecture

```text
AlMasryMarket/
│
├── app.R                   # Main Shiny application script (UI & Server logic)
├── scanner.py              # Python OpenCV/PyZbar barcode scanning engine
├── email_utils.py          # Python SMTP email notification functions
│
├── modules/                # Modularized R scripts for UI components
│   ├── login_ui.R
│   ├── admin_home_ui.R
│   ├── checkout_ui.R
│   └── ...                 # (Various other UI modules)
│
├── www/                    # Static web assets
│   ├── index.html          # Custom HTML layouts
│   ├── styles.css          # Global stylesheets
│   └── *.png / *.jpg       # UI graphics and logos
│
├── assets/                 # Generated assets (e.g., receipt barcodes)
├── receipts/               # Directory for generated PDF invoices
│
└── *.csv                   # Flat-file databases (stock, users, admins, offers)
```

---

## 🚀 Installation & Setup

### Prerequisites
You will need both **R** and **Python 3.x** installed on your system. 

### 1. Python Setup
Create a virtual environment (recommended) and install the required Python libraries.
```bash
# It is recommended to use the path specified in app.R: "~/.virtualenvs/r-reticulate"
python -m venv ~/.virtualenvs/r-reticulate
source ~/.virtualenvs/r-reticulate/bin/activate

pip install opencv-python pyzbar
```
*(Note for Mac users: You may need to install zbar via Homebrew: `brew install zbar`)*

### 2. R Setup
Open your R console or RStudio and install the required R packages:
```R
install.packages(c(
  "shiny", "shinyWidgets", "digest", "DT", 
  "reticulate", "png", "grid", "gridExtra", 
  "barcode", "dplyr", "filelock"
))
```

### 3. Environment Configuration
The application uses a dedicated Gmail account to send OTPs and offers. Update the credentials in `email_utils.py` if you wish to use your own SMTP server:
```python
SENDER_EMAIL = "your_email@gmail.com"
SENDER_PASSWORD = "your_app_password"
```

---

## 💻 Running the Application

1. Open `AlMasryMarket.Rproj` in RStudio or navigate to the project folder in your terminal.
2. Run the application:
```R
shiny::runApp("app.R")
```
3. The app will launch in your default web browser.

---

## 🔒 Default Data Setup
If starting fresh, the application will automatically generate empty `.csv` files (`users.csv`, `admins.csv`, `stock.csv`, `offers.csv`). You can sign up as an Admin via the UI, which will require OTP verification sent to the designated admin email.

---

## ⚠️ Notes on Camera Permissions
Because this app accesses the device webcam for barcode scanning (`scanner.py`), ensure that the environment running the R application (e.g., your terminal or RStudio) has the necessary OS-level permissions to access the camera.
