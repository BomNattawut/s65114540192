import random
from django.conf import settings
from rest_framework import serializers
from .models import *
from django.core.mail import send_mail
class Registerserializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['email', 'username', 'password', 'gender']

    def create(self, validated_data):
        # ใช้ create_user จาก CustomUserManager
        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            username=validated_data['username'],
            password=validated_data['password'],
            gender=validated_data['gender']
        )
        
        # ฟังก์ชันส่งอีเมลยืนยัน
        self.send_verify(user)
        return user

    def send_verify(self, user):
        verification_link = f"http://127.0.0.1:8000/Smartwityouapp/verifyemail/{user.id}/"  # กำหนดลิงค์ยืนยัน
        subject = "Email Verification"
        message = f"Thank you for registering, {user.username}. Please verify your email with this link: {verification_link}"
        from_email = settings.EMAIL_HOST_USER
        recipient_list = [user.email]

        send_mail(subject, message, from_email, recipient_list, fail_silently=False)
class partyserializer(serializers.ModelSerializer):
        class Meta:
            models=Party
            fields=['name',' exercise_type','location','description','date','start_time','finish_time','leader']
        def create(self, validated_data):
              party = Party.objects.create(**validated_data)
              return party

        

