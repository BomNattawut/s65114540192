import os
import json
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from rest_framework.response import Response
from .loadtoken import load_credentials
from.models import Party,PartyMember,CustomUser
from.serializer import *
# 🔹 กำหนดไฟล์ Credential และ Token
CREDENTIALS_FILE = "D:/Seniaproject/backend-django/backend/Smartwityouapp/calender_api_service/client_secret_679774878907-bo7e2ropa8epijvmjfqqqsvtbq8ticqd.apps.googleusercontent.com.json"
TOKEN_FILE = "D:/Seniaproject/backend-django/backend/Smartwityouapp/tokens/"
SCOPES = ["https://www.googleapis.com/auth/calendar.events"]
REDIRECT_URI = "http://127.0.0.1:8000/Smartwityouapp/oauth2callback/"

def get_credentials(userid):
    """ รับและจัดการ Credentials สำหรับ Google Calendar API """
    creds = None

    # ✅ โหลดโทเค็นถ้ามีอยู่แล้ว
    if os.path.exists(TOKEN_FILE):
        try:
            creds = load_credentials(user_id=userid)
        except Exception as e:
            print("🔴 ERROR: Token ไม่ถูกต้อง ลบ token.json แล้วลองใหม่:", e)
            creds = None

    # ✅ ถ้าไม่มีโทเค็น หรือโทเค็นหมดอายุ ให้ขอใหม่
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())  # รีเฟรชโทเค็นอัตโนมัติ
        else:
            flow = Flow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            flow.redirect_uri = REDIRECT_URI
            auth_url,state = flow.authorization_url(
                prompt="consent",
                state=userid
                    
                                                 )

            print(f"🔹 กรุณาไปที่ URL นี้เพื่ออนุญาตให้เข้าถึง Google Calendar:\n{auth_url}")
            return auth_url  # คืน URL ให้ผู้ใช้ล็อกอินก่อน

    return creds

def get_calendar_service(userid):
    """ สร้าง Service สำหรับเชื่อมต่อ Google Calendar API """
    creds = get_credentials(userid=userid)
    if isinstance(creds, str):
        print("🔴 ERROR: ยังไม่ได้รับสิทธิ์ OAuth จากผู้ใช้")
        return creds

    service = build("calendar", "v3", credentials=creds)
    return service
def create_event(event_data,userid):
    """ สร้างอีเวนต์ใหม่ใน Google Calendar """
    service = get_calendar_service(userid=userid)
    
    if isinstance(service, str):  # 🔹 ถ้าได้ URL กลับมา แสดงว่ายังไม่ได้ให้สิทธิ์
        return {"auth_url": service}  # ✅ ส่ง URL กลับไปให้ Flutter

    event = {
        "summary": event_data["title"],
        "location": event_data.get("location", ""),
        "description": event_data.get("description", ""),
        "start": {
            "dateTime": event_data["start_time"],
            "timeZone": "Asia/Bangkok",
        },
        "end": {
            "dateTime": event_data["finish_time"],
            "timeZone": "Asia/Bangkok",
        },
        "attendees": [{"email": event_data["leader"]}],  # ✅ ใช้ List ถูกต้องแล้ว
    }

    event_result = service.events().insert(calendarId="primary", body=event).execute()
    party = Party.objects.get(id=event_data["party_id"])
    party.google_event_id = event_result["id"]  # ✅ บันทึก eventId
    party.save()
    return event_result
def update_event(party_id, updated_data, userid):
    service = get_calendar_service(userid=userid)
    party = Party.objects.get(id=party_id)
    event_id = party.google_event_id  # ✅ ตรวจสอบว่าได้ Event ID หรือไม่

    print(f'📌 Event ID ที่ได้: {event_id}')
    
    if not event_id:
        print('❌ ERROR: ไม่พบ Event ID ใน Database')
        return {"error": "Event ID not found for this party"}

    updated_event = {
        "summary": updated_data["title"],
        "location": updated_data["location"],
        "description": updated_data["description"],
        "start": {
            "dateTime": updated_data["start_time"],
            "timeZone": "Asia/Bangkok",
        },
        "end": {
            "dateTime": updated_data["finish_time"],
            "timeZone": "Asia/Bangkok",
        },
    }

    print(f'📌 กำลังอัปเดต Event: {updated_event}')

    try:
        updated_result = service.events().update(
            calendarId="primary", eventId=event_id, body=updated_event
        ).execute()
        print(f'✅ อัปเดตสำเร็จ: {updated_result}')
        return updated_result  # คืนค่าผลลัพธ์ที่อัปเดตแล้ว
    except Exception as e:
        print(f'❌ ERROR: อัปเดตล้มเหลว: {str(e)}')
        return {"error": str(e)}
def delete_event(party_id,userid):
    service=get_calendar_service(userid=userid)
    party=Party.objects.get(id=party_id);
    event_id=party.google_event_id

    if event_id:
            service.events().delete(calendarId="primary", eventId=event_id).execute()
            party.google_event_id = None  # ล้างค่าในฐานข้อมูล
            party.save()
            return {"message": "Event deleted from Google Calendar"}
        
    return {"error": "No eventId found"}
def member_event(party_id,userid,event_data):

    service = get_calendar_service(userid=userid)
    
    if isinstance(service, str):  # 🔹 ถ้าได้ URL กลับมา แสดงว่ายังไม่ได้ให้สิทธิ์
        return {"auth_url": service}  # ✅ ส่ง URL กลับไปให้ Flutter
    user=CustomUser.objects.get(id=userid)
    event_date = datetime.strptime(event_data['date'], "%Y-%m-%d").date()
    start_time = datetime.strptime(event_data['start_time'], "%H:%M:%S").time()
    finish_time = datetime.strptime(event_data['finish_time'], "%H:%M:%S").time()

        # ✅ ใช้ `datetime.combine()` อย่างถูกต้อง
    start_datetime = datetime.combine(event_date, start_time).isoformat()
    finish_datetime = datetime.combine(event_date, finish_time).isoformat()
    event = {
        "summary": event_data["title"],
        "location": event_data.get("location", ""),
        "description": event_data.get("description", ""),
        "start": {
            "dateTime": start_datetime,
            "timeZone": "Asia/Bangkok",
        },
        "end": {
            "dateTime": finish_datetime,
            "timeZone": "Asia/Bangkok",
        },
        "attendees": [{"email": user.email}],  # ✅ ใช้ List ถูกต้องแล้ว
    }

    event_result = service.events().insert(calendarId="primary", body=event).execute()
    member=PartyMember.objects.get(user=userid,party=party_id)
    memberevent=PartyMemberEvent.objects.get(member=member)
    memberevent.google_event_id=event_result['id']
    memberevent.save()
    return event_result
def update_memberevent(party_id, updated_data, userid):
    service = get_calendar_service(userid=userid)
    user=CustomUser.objects.get(id=userid)
    party = Party.objects.get(id=party_id)
    member=PartyMember.objects.get(user=user.id,party=party.id) # ✅ ตรวจสอบว่าได้ Event ID หรือไม่
    memberevent=PartyMemberEvent.objects.get(member=member.id)
    event_id=memberevent.google_event_id
    print(f'📌 Event ID ที่ได้: {event_id}')
    
    if not event_id:
        print('❌ ERROR: ไม่พบ Event ID ใน Database')
        return {"error": "Event ID not found for this party"}
    event_date = datetime.strptime(updated_data['date'], "%Y-%m-%d").date()
    start_time = datetime.strptime(updated_data['start_time'], "%H:%M:%S").time()
    finish_time = datetime.strptime(updated_data['finish_time'], "%H:%M:%S").time()

        # ✅ ใช้ `datetime.combine()` อย่างถูกต้อง
    start_datetime = datetime.combine(event_date, start_time).isoformat()
    finish_datetime = datetime.combine(event_date, finish_time).isoformat()
    updated_event = {
        "summary": updated_data["title"],
        "location": updated_data["location"],
        "description": updated_data["description"],
        "start": {
            "dateTime": start_datetime,
            "timeZone": "Asia/Bangkok",
        },
        "end": {
            "dateTime": finish_datetime,
            "timeZone": "Asia/Bangkok",
        },
    }

    print(f'📌 กำลังอัปเดต Event: {updated_event}')

    try:
        updated_result = service.events().update(
            calendarId="primary", eventId=event_id, body=updated_event
        ).execute()
        print(f'✅ อัปเดตสำเร็จ: {updated_result}')
        return updated_result  # คืนค่าผลลัพธ์ที่อัปเดตแล้ว
    except Exception as e:
        print(f'❌ ERROR: อัปเดตล้มเหลว: {str(e)}')
        return {"error": str(e)}
