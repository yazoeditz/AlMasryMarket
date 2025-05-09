import smtplib
from email.mime.text import MIMEText

SENDER_EMAIL = "elmasrymarketstore@gmail.com"
SENDER_PASSWORD = "cuzfkbeoclsqtjbu"
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

def send_email(receiver_email, subject, body):
    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = SENDER_EMAIL
    msg["To"] = receiver_email

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.sendmail(SENDER_EMAIL, receiver_email, msg.as_string())
        server.quit()
        print(f"✅ Email sent to {receiver_email}!")
    except Exception as e:
        print(f"❌ Error sending email: {e}")

def send_otp_email(receiver_email, otp_code):
    subject = "Al Masry Market - OTP Verification"
    body = f"""Hello,

Your One-Time Password (OTP) is: {otp_code}

Please enter this code to verify your login.

Best regards,
Al Masry Market Team
"""
    send_email(receiver_email, subject, body)

def send_password_reset_email(receiver_email, otp_code):
    subject = "Al Masry Market - Password Reset OTP"
    body = f"""Hello,

Your password reset OTP is: {otp_code}

If you didn't request a password reset, please ignore this email.

Best regards,
Al Masry Market Team
"""
    send_email(receiver_email, subject, body)

def send_vendor_request_email(vendor_email, item_name, quantity):
    subject = f"Stock Reorder Request: {item_name}"
    body = f"""Dear Vendor,

We would like to place an order for {quantity} units of {item_name}.

Please confirm availability as soon as possible.

Thank you,
Al Masry Market Management
"""
    send_email(vendor_email, subject, body)
