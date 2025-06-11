import os
import django
from datetime import timedelta
from django.utils.timezone import now
from Smartwityouapp.models import PartyPost  # เปลี่ยนเป็นชื่อแอปของคุณ

# ตั้งค่า Django environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")  # เปลี่ยนเป็นชื่อโปรเจกต์ของคุณ
django.setup()

def delete_old_posts():
    """ ลบโพสต์ที่มีอายุเกิน 10 วัน """
    cutoff_date = now() - timedelta(days=10)
    deleted_count, _ = PartyPost.objects.filter(created_at__lt=cutoff_date).delete()
    print(f"Deleted {deleted_count} old posts.")

if __name__ == "__main__":
    delete_old_posts()