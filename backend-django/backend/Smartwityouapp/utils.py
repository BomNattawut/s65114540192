from firebase_admin import messaging

def create_notification(title, body, data=None):
    """
    สร้างข้อความการแจ้งเตือน
    :param title: หัวข้อการแจ้งเตือน
    :param body: ข้อความการแจ้งเตือน
    :param data: ข้อมูลเพิ่มเติม (dict)
    :return: messaging.Notification object
    """
    return messaging.Notification(
        title=title,
        body=body,
    ), data if data else {}
def create_joirequest(title,body,data=None):
    return messaging.Notification(
        title=title,
        body=body,
    ), data if data else {}
    


def send_fcm_notification(token, title, body, data=None):
    """
    ส่งการแจ้งเตือนผ่าน Firebase Cloud Messaging (FCM)
    :param token: FCM Token ของอุปกรณ์ผู้รับ
    :param title: หัวข้อการแจ้งเตือน
    :param body: ข้อความการแจ้งเตือน
    :param data: ข้อมูลเพิ่มเติม (dict)
    """
    try:
        notification, notification_data = create_notification(title, body, data)
        
        message = messaging.Message(
            notification=notification,
            data=notification_data,  # ส่งข้อมูลเพิ่มเติมถ้ามี
            token=token,  # ระบุ FCM Token ของอุปกรณ์ผู้รับ
        )

        # ส่งข้อความ
        response = messaging.send(message)
        print(f"Notification sent successfully: {response}")
        return response
    except Exception as e:
        print(f"Error sending notification: {e}")
        return None

def send_join_request(token, title, body, data):
    try:
        notification, notification_data = create_notification(title, body, data)
        
        joinreq_message = messaging.Message(
            notification=notification,
            data=notification_data,
            token=token,  # เพิ่ม token สำหรับการส่ง
        )

        # ส่งข้อความ
        response = messaging.send(joinreq_message)
        print(f"Join request sent successfully: {response}")
        return response
    except Exception as e:
        print(f"Error sending join request notification: {e}")
        return None
def updateparty_notification(tokens, title, body, data=None):
    valid_tokens = [token.strip() for token in tokens if isinstance(token, str) and token.strip()]
    print(f"🔍 Tokens ที่จะใช้ส่ง: {valid_tokens}")

    if not valid_tokens:
        print("❌ ไม่มี FCM Tokens ที่ถูกต้อง")
        return

    for token in valid_tokens:
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data,  # ✅ แปลง `data` ให้เป็น String
                token=token
            )
            response = messaging.send(message)
            print(f"✅ ส่งการแจ้งเตือนไปยัง {token} สำเร็จ: {response}")
        except Exception as e:
            print(f"❌ ERROR: ไม่สามารถส่งการแจ้งเตือนได้: {e}")
def deleteparty_notification(tokens, title, body, data=None):
    valid_tokens = [token.strip() for token in tokens if isinstance(token, str) and token.strip()]
    print(f"🔍 Tokens ที่จะใช้ส่ง: {valid_tokens}")

    if not valid_tokens:
        print("❌ ไม่มี FCM Tokens ที่ถูกต้อง")
        return

    for token in valid_tokens:
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data,  # ✅ แปลง `data` ให้เป็น String
                token=token
            )
            response = messaging.send(message)
            print(f"✅ ส่งการแจ้งเตือนไปยัง {token} สำเร็จ: {response}")
        except Exception as e:
            print(f"❌ ERROR: ไม่สามารถส่งการแจ้งเตือนได้: {e}")