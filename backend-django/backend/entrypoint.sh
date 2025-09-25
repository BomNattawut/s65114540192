#!/bin/sh

# ✅ รอให้ database พร้อมก่อน (optional แต่แนะนำ)
echo "Waiting for database..."
# sleep 5  # ถ้า DB ช้าลองเพิ่ม sleep

# ✅ migrate database
python manage.py migrate

# ✅ collect static
echo "Collecting static files..."
python manage.py collectstatic --noinput

# ✅ create default user + exercises
echo "Creating default CustomUser and ExerciseTypes if not exists..."
python manage.py shell << END
from django.contrib.auth import get_user_model
from datetime import date
from Smartwityouapp.models import ExerciseType   # 🔥 เปลี่ยนชื่อแอปให้ตรงกับโปรเจกต์คุณ

User = get_user_model()

# ----------------------
# Default CustomUser
# ----------------------
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
    print("✅ CustomUser created:", email)
else:
    print("ℹ️ CustomUser already exists:", email)


# ----------------------
# Default ExerciseTypes (Grouped)
# ----------------------
default_exercises = [
    # Cardio
    {"name": "Running", "description": "การวิ่งเพื่อสุขภาพ", "nummerber": 1},
    {"name": "Cycling", "description": "การปั่นจักรยานเพื่อออกกำลังกาย", "nummerber": 2},
    {"name": "Swimming", "description": "การว่ายน้ำเพื่อเสริมความแข็งแรง", "nummerber": 3},
    {"name": "Walking", "description": "การเดินเพื่อสุขภาพ", "nummerber": 4},
    {"name": "HIIT", "description": "การออกกำลังกายแบบเข้มข้นสั้น ๆ", "nummerber": 5},

    # Strength
    {"name": "Weight Training", "description": "การยกน้ำหนักเพื่อเพิ่มกล้ามเนื้อ", "nummerber": 6},
    {"name": "Bodyweight Exercise", "description": "การออกกำลังกายโดยใช้น้ำหนักตัว เช่น push-up, pull-up", "nummerber": 7},
    {"name": "Yoga", "description": "โยคะเพื่อยืดกล้ามเนื้อและผ่อนคลาย", "nummerber": 8},
    {"name": "Pilates", "description": "พิลาทิสเพื่อแกนกลางลำตัว", "nummerber": 9},

    # Team Sports
    {"name": "Football", "description": "ฟุตบอลเพื่อความสนุกและทีมเวิร์ค", "nummerber": 10},
    {"name": "Basketball", "description": "บาสเกตบอลเสริมความฟิตและความคล่องตัว", "nummerber": 11},
    {"name": "Badminton", "description": "แบดมินตันช่วยพัฒนาการทรงตัวและความเร็ว", "nummerber": 12},
    {"name": "Volleyball", "description": "วอลเลย์บอลเพิ่มทักษะการทำงานเป็นทีม", "nummerber": 13},
]

for ex in default_exercises:
    if not ExerciseType.objects.filter(name=ex["name"]).exists():
        ExerciseType.objects.create(**ex)
        print("✅ ExerciseType created:", ex["name"])
    else:
        print("ℹ️ ExerciseType already exists:", ex["name"])
END

# ✅ run server ตามปกติ
exec "$@"
