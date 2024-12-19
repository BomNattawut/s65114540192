from django import views
from rest_framework import status
from django.shortcuts import render
from rest_framework.response import Response
from .serializer import *
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import authenticate, login, logout
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse
from django.utils.timezone import localtime
from datetime import timedelta

class Register(APIView):
    def post(self,request,*arg,**kwargs):
        serializer=Registerserializer(data=request.data)
        if serializer.is_valid():
                user=serializer.save()
                refreshtoken=RefreshToken().for_user(user=user)
                return Response({"message":"message Register was successfully","id":user.id,'token':str(refreshtoken),'access_token':str(refreshtoken.access_token)},status=status.HTTP_201_CREATED)
        else:
            print(serializer.errors)
            return Response(serializer.errors,status=status.HTTP_400_BAD_REQUEST)
class Login(APIView):
    def post(self,request,*arg,**kwargs):
        email=request.data.get('email')
        password=request.data.get('password')
        user=authenticate(email=email, password=password)
        if user is not None :
               login(request,user)
               refreshtoken=RefreshToken().for_user(user=user)
               return Response({"Message":"Login was succsesed","token":str(refreshtoken),'access_token':str(refreshtoken.access_token)},status=status.HTTP_200_OK)
        else:
             return Response({'Message':'Login failed'},status=status.HTTP_400_BAD_REQUEST)

class verification(APIView):
     template_name='Smartwityouapp/verifyemail.html'
     def get(self,request,user_id):
          user=CustomUser.objects.get(id=user_id)
          if user.email_verified is not True:
                    context={
                         "user_id":user.id,
                         "username":user.username,
                    }
                    return render(request,self.template_name,context)
               # type: ignore
     def post(self,request,user_id):
          user=CustomUser.objects.get(id=user_id)
          user.email_verified=True
          user.save()
          refreshtoken=RefreshToken().for_user(user=user)
          return Response({'message':'verified succeses','token':str(refreshtoken),'acces_token':str(refreshtoken.access_token)})
class VerifyEmailStatus(APIView):
    # กำหนดให้ผู้ใช้ต้องล็อกอินก่อน

     def post(self, request):
        # ดึง userId จาก Headers
        userId = request.data.get('userId')
        user=CustomUser.objects.get(id=userId)
        if not userId:
            return Response(
                {'status': 'error', 'message': 'userId is required in headers'},
                status=400
            )
          # ดึงข้อมูลผู้ใช้จาก request
        if user.email_verified == True:
            return Response({'status': 'verified', 'message': 'Email is verified'}, status=200)
        else:
            return Response({'status': 'unverified', 'message': 'Email is not verified'}, status=400)
class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # รับ Refresh Token จากผู้ใช้
            refresh_token = request.data.get('refresh_token')
            token = RefreshToken(refresh_token)
            token.blacklist()  # ทำให้ Token นี้ใช้งานไม่ได้อีกต่อไป

            return Response({"message": "Successfully logged out."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": "Invalid token or token already blacklisted."}, status=status.HTTP_400_BAD_REQUEST)



class RecommendedPartyView(APIView):
    def get(self, request):
        user = request.user
        if not user.is_authenticated:
            return JsonResponse({"error": "Unauthorized"}, status=401)

        # ดึงข้อมูลเวลาออกกำลังกายของผู้ใช้
        exercise_times = ExerciseTime.objects.filter(user=user)
        if not exercise_times.exists():
            return JsonResponse({"message": "No available exercise times found"}, status=200)

        # ดึงปาร์ตี้ที่ตรงกับเวลา
        parties = Party.objects.none()  # เก็บผลรวม
        for time in exercise_times:
            filtered_parties = Party.objects.filter(
                date__gte=localtime().date(),
                start_time__gte=time.available_time_start,
                finish_time__lte=time.available_time_end,
                location__opening_day__icontains=time.available_day
            )
            parties = parties | filtered_parties  # รวมผล

        parties = parties.distinct().order_by("date", "start_time")[:10]  # จำกัด 10 รายการ
        result = [
            {
                "id": party.id,
                "name": party.name,
                "activity": party.exercise_type.name,
                "location": party.location.location_name,
                "time": f"{party.start_time} - {party.finish_time}",
                "date": party.date.strftime("%Y-%m-%d"),
            }
            for party in parties
        ]
        return JsonResponse(result, safe=False)

# Create your views here.
