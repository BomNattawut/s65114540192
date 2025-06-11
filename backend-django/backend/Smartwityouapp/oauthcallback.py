from django.http import JsonResponse, HttpResponseRedirect
from google_auth_oauthlib.flow import Flow
import json
import os

# 🔹 กำหนดไฟล์ Credentials และโฟลเดอร์สำหรับเก็บ Token
CREDENTIALS_FILE = "D:/Seniaproject/backend-django/backend/Smartwityouapp/calender_api_service/client_secret_679774878907-bo7e2ropa8epijvmjfqqqsvtbq8ticqd.apps.googleusercontent.com.json"
SCOPES = ["https://www.googleapis.com/auth/calendar.events"]
REDIRECT_URI = "http://127.0.0.1:8000/Smartwityouapp/oauth2callback/"

# 🔹 ตั้งค่าโฟลเดอร์เก็บ Token
TOKEN_DIR = "D:/Seniaproject/backend-django/backend/Smartwityouapp/tokens/"
TOKEN_FILE = os.path.join(TOKEN_DIR, "token.json")

# ✅ ตรวจสอบและสร้างโฟลเดอร์หากยังไม่มี
os.makedirs(TOKEN_DIR, exist_ok=True)

def google_auth_callback(request):
    """ รับค่า code และบันทึก Token แยกตามผู้ใช้ """
    code = request.GET.get("code")
    user_id = request.GET.get("state")  # ✅ รับ user_id จาก Flutter (ต้องส่ง user_id มาด้วย)

    if not code or not user_id:
        return JsonResponse({"error": "Missing authorization code or user ID"}, status=400)

    try:
        flow = Flow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
        flow.redirect_uri = REDIRECT_URI
        flow.fetch_token(code=code)

        credentials = flow.credentials
        token_data = {
            "token": credentials.token,
            "refresh_token": credentials.refresh_token,
            "token_uri": credentials.token_uri,
            "client_id": credentials.client_id,
            "client_secret": credentials.client_secret,
        }

        # ✅ บันทึก Token ตาม User ID
        token_path = f"D:/Seniaproject/backend-django/backend/Smartwityouapp/tokens/user_{user_id}.json"
        with open(token_path, "w") as token_file:
            json.dump(token_data, token_file)

        return HttpResponseRedirect("http://127.0.0.1:8000/Smartwityouapp/success")
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
