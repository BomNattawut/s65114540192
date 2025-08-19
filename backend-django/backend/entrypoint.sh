#!/bin/sh

# รอให้ database พร้อมก่อน (optional แต่แนะนำ)
echo "Waiting for database..."
sleep 5  # ปรับเวลาให้พอดีถ้าจำเป็น

# รัน migrate
python manage.py migrate

# รัน server ตามปกติ
exec "$@"