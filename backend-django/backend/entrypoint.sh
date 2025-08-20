#!/bin/sh

# รอให้ database พร้อมก่อน (optional แต่แนะนำ)
echo "Waiting for database..."
 # ปรับเวลาให้พอดีถ้าจำเป็น

# รัน migrate
python manage.py migrate

echo "Creating default CustomUser if not exists..."
python manage.py shell << END
from django.contrib.auth import get_user_model
from datetime import date

User = get_user_model()

email = "default@example.com"
username = "defaultuser"
password = "password123"

if not User.objects.filter(email=email).exists():
    User.objects.create_user(
        email=email,
        username=username,
        password=password,
        birth_date=date(2000,1,1),
        gender='man',
        description='Default user',
        email_verified=True,
        leader_score=0.0,
        is_staff=True,
        is_active=True
    )
    print("CustomUser created:", email)
else:
    print("CustomUser already exists:", email)
END

# รัน server ตามปกติ
exec "$@"