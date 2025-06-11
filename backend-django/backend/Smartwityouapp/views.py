from uuid import UUID
from django import views
from rest_framework import status
from django.shortcuts import get_object_or_404, render
from rest_framework.response import Response
from .serializer import *
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import authenticate, login, logout
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated,AllowAny
from django.http import JsonResponse
from django.utils.timezone import localtime
from datetime import time, timedelta
from .serializer import *
from django.db.models import Q
from .utils import *
from .managecalendar import *
from datetime import datetime
import json
from django.utils.timezone import make_aware,is_naive
from pytz import timezone 
import time
from django.db.models import Sum, Count, Avg
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.conf import settings
from django.contrib.auth.hashers import make_password
from django.utils.encoding import force_str



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
               return Response({"Message":"Login was succsesed","token":str(refreshtoken),'access_token':str(refreshtoken.access_token),"id":user.id},status=status.HTTP_200_OK)
        else:
             return Response({'Message':'Login failed'},status=status.HTTP_400_BAD_REQUEST)

class verification(APIView):
     template_name='Smartwithyouapp/verifyemail.html'
     template_name2='Smartwithyouapp/verifysuccess.html'
     def get(self, request, user_id):
            user = CustomUser.objects.get(id=user_id)
            if not user.email_verified:
                context = {
                    "user_id": user.id,
                    "username": user.username,
                }
                return render(request, self.template_name, context)

            # ถ้ายืนยันแล้ว แสดงหน้าสำเร็จเลย
            return render(request, self.template_name2, {"username": user.username})

     def post(self, request, user_id):
            user = CustomUser.objects.get(id=user_id)
            user.email_verified = True
            user.save()

            context = {
                "username": user.username,
            }

            return render(request, self.template_name2, context)
          
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
            return Response({'status': 'verified', 'message': 'Email is verified'}, status=201)
        else:
            print('Email is not verified')
            return Response({'status': 'unverified', 'message': 'Email is not verified'}, status=404)
            
class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # รับ Refresh Token จากผู้ใช้
            refresh_token = request.data.get('refresh_token')
            token = RefreshToken(refresh_token)
            token.blacklist()  # ทำให้ Token นี้ใช้งานไม่ได้อีกต่อไป
            user = request.user
            UserFCMToken.objects.filter(user=user).update(fcm_token='')
            return Response({"message": "Successfully logged out."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": "Invalid token or token already blacklisted."}, status=status.HTTP_400_BAD_REQUEST)

class RecommendedPartyView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        user = request.user
        if not user.is_authenticated:
            return JsonResponse({"error": "Unauthorized"}, status=401)

        # ✅ ค้นหาว่าผู้ใช้สนใจประเภทออกกำลังกายอะไรบ้าง
        user_exercise_types = list(UserExerciseType.objects.filter(user=user).values_list('exercise_type', flat=True))
        if not user_exercise_types:
            return JsonResponse({"message": "No preferred exercise types found"}, status=200)

        # ✅ ค้นหาช่วงเวลาที่ผู้ใช้สามารถออกกำลังกายได้
        exercise_times = ExerciseTime.objects.filter(user=user)
        if not exercise_times.exists():
            return JsonResponse({"message": "No available exercise times found"}, status=200)

        # ✅ กรองปาร์ตี้ที่ตรงทุกเงื่อนไขก่อน (Exact Match)
        exact_match_parties = Party.objects.none()
        for time in exercise_times:
            filtered_parties = Party.objects.filter(
                Q(date__gte=localtime().date()) &  # ปาร์ตี้ต้องเกิดขึ้นในปัจจุบันหรืออนาคต
                Q(start_time__gte=time.available_time_start) &  # เริ่มภายในช่วงเวลาที่กำหนด
                Q(finish_time__lte=time.available_time_end) &  # จบภายในช่วงเวลาที่กำหนด
                Q(exercise_type_id__in=user_exercise_types) &  # ต้องเป็นประเภทออกกำลังกายที่ผู้ใช้สนใจ
                Q(location__opening_day=time.available_day)  # ต้องเปิดในวันนั้นๆ
            )
            exact_match_parties |= filtered_parties  # ✅ รวมผลลัพธ์เข้ากับ queryset หลัก

        if exact_match_parties.exists():
            exact_match_parties = exact_match_parties.distinct().order_by("date", "start_time")[:10]
            return JsonResponse(self.serialize_parties(exact_match_parties), safe=False)

        # ✅ ถ้าไม่มีปาร์ตี้ที่ตรงทุกเงื่อนไข ลองหาปาร์ตี้ที่ตรง "บางเงื่อนไข"
        similar_parties = Party.objects.filter(
            Q(date__gte=localtime().date()) &  # ปาร์ตี้ต้องเกิดขึ้นในปัจจุบันหรืออนาคต
            (Q(exercise_type_id__in=user_exercise_types) |  # ตรงประเภท
             Q(location__opening_day__in=[t.available_day for t in exercise_times]) |  # ตรงวันเปิดทำการ
             Q(start_time__gte=min(t.available_time_start for t in exercise_times)) |  # เริ่มในช่วงที่กำหนด
             Q(finish_time__lte=max(t.available_time_end for t in exercise_times)))  # จบในช่วงที่กำหนด
        ).distinct().order_by("date", "start_time")[:10]

        return JsonResponse(self.serialize_parties(similar_parties), safe=False)

    def serialize_parties(self, parties):
        """ แปลงข้อมูลปาร์ตี้ให้อยู่ในรูปแบบ JSON """
        return [
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

class CreatePartyView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        serializer = partyserializer(data=request.data)
        if serializer.is_valid():
            party = serializer.save() 
            if not party.date or not party.start_time or not party.finish_time:
                return Response({"error": "Date or time is missing"}, status=status.HTTP_400_BAD_REQUEST)
            
            start_datetime = datetime.combine(party.date, party.start_time).isoformat()
            finish_datetime = datetime.combine(party.date, party.finish_time).isoformat()
            event={
                 'party_id':party.id,
                 'title':party.name,
                 'location':party.location.location_name,
                 'description':party.description,
                  'start_time':start_datetime,
                  'finish_time':finish_datetime,
                  'leader':party.leader.email
            }
            print(event)
            print(f'userid:{party.leader.id}')
            result= create_event(event_data=event,userid=party.leader.id)
            if isinstance(result, dict) and "auth_url" in result:
                return Response(result, status=401)  # ✅ HTTP 401 Unauthorized เพื่อให้ Flutter เปิด URL
             # เรียก create ใน serializer
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
# Create your views here.
class FetchLocations(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        # ดึงข้อมูลสถานที่ทั้งหมดจากโมเดล ExercisePlace
        locations = ExercisePlace.objects.all()
        
        # ใช้ Serializer เพื่อแปลงข้อมูลสถานที่เป็น JSON
        serializer = ExercisePlaceSerializer(locations, many=True)
        
        # ส่งข้อมูลกลับในรูปแบบ JSON
        print(f'{serializer.data}')
        return Response(serializer.data, status=200)
class Fetchworkoutype(APIView):
     permission_classes = [AllowAny]
     def get(self,request):
          workouttype=ExerciseType.objects.all()
          serializers=exercisetypeSerializer(workouttype, many=True)
          return Response(serializers.data,status=200)
class fectexerciseplacetype(APIView):
      permission_classes = [AllowAny]
      def get(self,request):
           exerciseplacetype=Exerciseplacetype.objects.all()
           serializers=exerciseplacetypeSerializer(exerciseplacetype,many=True)
           return Response(serializers.data,status=200)
class filterlocation(APIView):
    
    permission_classes = [AllowAny]
    def post(self, request):
        # รับข้อมูลประเภทสถานที่จาก Body
        query = request.data.get('type')
        print(f"Received type: {query}") 
        
        try:
            # ดึงประเภทสถานที่จาก Exerciseplacetype
            exercise_type = Exerciseplacetype.objects.get(name=query)
        except Exerciseplacetype.DoesNotExist:
            return Response({"error": "Exercise type not found"}, status=404)

        # กรองข้อมูลสถานที่ตามประเภท
        locations = ExercisePlace.objects.filter(exercise_type=exercise_type)

        # ใช้ Serializer เพื่อแปลงข้อมูล
        serializer = ExercisePlaceSerializer(locations, many=True)

        # ส่งข้อมูลกลับในรูปแบบ JSON
        return Response(serializer.data, status=200)
class fecthcreatepaty(APIView):
     permission_classes = [AllowAny]
     def get(self, request):
        leader_id = request.headers.get('userid')
        if not leader_id:
            return Response({'error': 'User ID not provided'}, status=400)

        # ดึง Party ที่ leader เป็นเจ้าของ พร้อมข้อมูล location
        parties = Party.objects.filter(leader=leader_id)
        serializer = partyserializer(parties, many=True)
        print("Serialized Data:", serializer.data)
        return Response(serializer.data, status=200)
class fecthjoinparty(APIView):
      permission_classes = [AllowAny]

      def get(self, request):
            user_id = request.headers.get('userid')  # ดึง user ID จาก headers
            if not user_id:
                return Response({"error": "User ID is required"}, status=400)

            try:
                # ตรวจสอบว่าผู้ใช้งานมีในระบบหรือไม่
                user = CustomUser.objects.get(id=user_id)
            except CustomUser.DoesNotExist:
                return Response({"error": "User not found"}, status=404)

            # ดึง PartyMember ทั้งหมดที่เกี่ยวข้องกับผู้ใช้
            party_memberships = PartyMember.objects.filter(user=user)

            # ดึง Party ที่ผู้ใช้เข้าร่วม
            joined_parties = [membership.party for membership in party_memberships]

            # Serialize ข้อมูล
            serializer = partyserializer(joined_parties, many=True)
            return Response(serializer.data, status=200)
class fecthmember(APIView):
       
       def get(self, request):
       
        party = request.headers.get('partyid') 
        if not party:
            return Response({'error': 'Party ID not provided'}, status=400)
        
        members = PartyMember.objects.filter(party=party)
        join_member = [
            {   
                'id': member.user.id,
                'email':member.user.email,
                'username': member.user.username,
                'profile_image': member.user.profile_image.url if member.user.profile_image else None,
                'memberId':member.id
            } 
            for member in members
        ]
        print(f'ค่าที่ส่งไป: {join_member}')
        return Response(join_member, status=200)
class updatateparty(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request,party_id):
        party = get_object_or_404(Party, id=party_id)
        
        print(f'google_event:{party.google_event_id}')
        # ✅ ตรวจสอบว่า user เป็น leader ของปาร์ตี้
        if party.leader != request.user:
            return Response({"error": "You are not the leader of this party."}, status=403)

        serializer = partyserializer(party, data=request.data, partial=True)
        if serializer.is_valid():
            new = serializer.save()
            print(f'ข้อมูลที่อัพเดต{new}')
            start_datetime = datetime.combine(new.date, new.start_time).isoformat()
            finish_datetime = datetime.combine(new.date, new.finish_time).isoformat()

            update_data = {
                    "party_id": party.id,
                    "title": new.name,
                    "location": new.location.location_name,
                    'date':new.date,
                    "description": new.description,
                    "start_time": start_datetime,
                    "finish_time": finish_datetime,
                }

            print(f'📌 ข้อมูลที่อัปเดต: {update_data}')
            print(f'ไอดีของleader:{party.leader.id}');
                # ✅ เช็คว่าฟังก์ชันนี้ถูกเรียกไหม
            try:
                    update_results = update_event(
                        party_id=party_id, updated_data=update_data, userid=party.leader.id
                    )
                    print(f'✅ อัปเดตสำเร็จ: {update_results}')
                    tite=f'ปาร์ตี้ {party.name} มีการเปลี่ยนเเปลง'
                    body=f'มีการเปลี่ยนเเปลงปาร์ตี้จาก{party.leader.username}\nวัน {now().date()}\nเวลา {now().time()}'
                    data={
                         'type':'updateparty',
                         'party': str(party.id)
                    }
                    members = PartyMember.objects.filter(party=party.id).select_related('user')
                    fcm_tokens = [token.fcm_token
                            for member in members
                            for token in UserFCMToken.objects.filter(user=member.user)]
                    for token in fcm_tokens:
                        print(f'📌 ตรวจสอบ token: "{token}" - Type: {type(token)}')
                    print(f'fcmของmember:{fcm_tokens}')
                    updateparty_notification(tokens=fcm_tokens,title=tite,body=body,data=data)
            except Exception as e:
                    print(f'❌ ERROR: update_event() ไม่ทำงาน: {str(e)}')

            return Response(serializer.data, status=200)
        
                
           
       
class addmember(APIView):
        permission_classes = [IsAuthenticated]
        def post(self, request):
        # รับข้อมูลจาก request
            party_id = request.data.get('party')
            member_id = request.data.get('member')

            # ตรวจสอบว่าปาร์ตี้และผู้ใช้มีอยู่จริง
            party = get_object_or_404(Party, id=party_id)
            member = get_object_or_404(CustomUser, id=member_id)

            # ตรวจสอบว่ามีคำเชิญและสถานะเป็น "accepted"
            try:
                invitation = PartyInvitation.objects.get(party=party, receiver=member, status="accepted")
            except PartyInvitation.DoesNotExist:
                return Response({"error": "No accepted invitation found for this user."}, status=404)

            # ตรวจสอบว่าผู้ใช้อยู่ในปาร์ตี้แล้วหรือยัง
            if PartyMember.objects.filter(party=party, user=member).exists():
                return Response({"error": "User is already a member of this party."}, status=400)

            # เพิ่มผู้ใช้เข้าไปในปาร์ตี้
            PartyMember.objects.create(party=party, user=member)

            # ส่งข้อความตอบกลับ
            return JsonResponse({"message": "Member added successfully."}, status=201)
        '''
             inivitation=request.get.data()#มาเพิ่มตัวเเเปรค่าที่ส่งมาจากforntendทีหลัง
             serializer=PartyInvitationserializer(inivitation)
             if serializer.is_valid():
                party = serializer.save()  # เรียก create ใน serializer
                return Response(serializer.data, status=status.HTTP_201_CREATED)
             return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            '''
class Removemember(APIView):
         permission_classes = [IsAuthenticated]
         def post(self,request):
             memberid=request.data.get('memberId')
             try:
                 member=PartyMember.objects.get(id=memberid)
                 print(f'สมาชิกที่จะลบ{member}')
                 if member:
                      member.delete() 
                      print('ลบเเล้วเด้อ')
                      return Response({"message": "remove member successfully."}, status=200)
                 else:
                      return Response({"message": "not found member."}, status=404)
             except Exception as e: 
                    return Response({'message':f'Error{e}'})
       
class Deleteparty(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        user_id = request.headers.get('userId')
        party_id = request.headers.get('party')
        user = CustomUser.objects.get(id=user_id)
        party = Party.objects.filter(id=party_id, leader=user).first()

        if not party:
            return Response({"error": "คุณไม่มีสิทธิ์ลบปาร์ตี้นี้"}, status=403)

        # ✅ 1. ดึงสมาชิกที่อยู่ในปาร์ตี้นี้
        members = PartyMember.objects.filter(party=party.id).select_related('user')

        # ✅ 2. ดึง FCM Token ของสมาชิกแต่ละคน
        for member in members:
            fcm_token = UserFCMToken.objects.filter(user=member.user).values_list('fcm_token', flat=True).first()

            if fcm_token:
                print(f'📌 ส่งแจ้งเตือนไปยัง: {member.user.username} - Token: {fcm_token}')
                
                # ✅ 3. ส่งแจ้งเตือนให้สมาชิกแต่ละคน
                send_fcm_notification(
                    token=fcm_token,
                    title="ปาร์ตี้ถูกยกเลิก ❌",
                    body=f"ปาร์ตี้ '{party.name}' ถูกยกเลิกโดย {user.username}",
                    data={"type": "party_deleted", "party_id": str(party_id)}
                )

        # ✅ 4. ลบ Event ของ Leader จาก Google Calendar
        if party.google_event_id:
            service = get_calendar_service(userid=user.id)
            try:
                service.events().delete(calendarId="primary", eventId=party.google_event_id).execute()
                print(f"✅ ลบนัดหมายของ Leader สำเร็จ: {party.google_event_id}")
            except Exception as e:
                print(f"❌ ERROR: ไม่สามารถลบนัดหมายของ Leader - {str(e)}")

        # ✅ 5. ลบ Event ของสมาชิกจาก Google Calendar
        member_events = PartyMemberEvent.objects.filter(member__party=party)
        for memberevent in member_events:
            if memberevent.google_event_id:
                try:
                    service = get_calendar_service(userid=memberevent.member.user.id)
                    service.events().delete(calendarId="primary", eventId=memberevent.google_event_id).execute()
                    print(f"✅ ลบนัดหมายของสมาชิกสำเร็จ: {memberevent.google_event_id}")
                except Exception as e:
                    print(f"❌ ERROR: ไม่สามารถลบนัดหมายของสมาชิก - {str(e)}")

        # ✅ 6. ลบข้อมูลใน Database
        PartyMemberEvent.objects.filter(member__party=party).delete()  # ลบ Event ของสมาชิก
        PartyMember.objects.filter(party=party).delete()  # ลบสมาชิกทั้งหมด
        party.delete()  # ลบปาร์ตี้

        return Response({"message": "ลบปาร์ตี้สำเร็จ"}, status=200)


class SendInvitationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):

        party_id = request.data.get("party_id")
        receiver_id = request.data.get("receiver_id")
        try:
            
            party = Party.objects.get(id=party_id)
            print(f'เลขปาร์ตี้id:{party.id}')
            receiver = CustomUser.objects.get(id=receiver_id)
        except (Party.DoesNotExist, CustomUser.DoesNotExist):
            return Response({"error": "Party or receiver not found"}, status=status.HTTP_404_NOT_FOUND)

        if party.leader != request.user:
            return Response({"error": "You are not the leader of this party"}, status=status.HTTP_403_FORBIDDEN)

        data = {
        'party': party.id,  # Ensure party.id is included
        'sender': request.user.id,
        'receiver': receiver.id,
        'send_date': now().date(),
        'send_time': now().time(),
        'status': 'pending'
    }

        print(f"✅ Data ที่ส่งไป Serializer: {data}")

        serializer = PartyInvitationserializer(data=data)

        if serializer.is_valid():
            invitation = serializer.save()

            try: # เพิ่ม try-except block เพื่อจัดการกรณีที่ token ไม่มี
                token = UserFCMToken.objects.get(user=receiver) # เปลี่ยนจาก receiver.id เป็น receiver
                print(f'{token}')

                title = f'คุณได้รับคำเชิญเข้าร่วมปาร์ตี้'
                body = f'คุณได้รับคำเชิญจาก{party.leader.username}\nเวลา {now().date()} {now().time()}'
                data = {
                    'type': 'invitation'
                }
                send_fcm_notification(token=token.fcm_token, title=title, body=body, data=data)

                return Response({"message": "Invitation sent successfully", "invitation_id": invitation.id}, status=status.HTTP_200_OK)
            except UserFCMToken.DoesNotExist:
                return Response({"error": "FCM token not found for this user"}, status=status.HTTP_404_NOT_FOUND) # Handle token not found
        else:
            print(serializer.errors)  # พิมพ์ errors เพื่อตรวจสอบ
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST) # ส่ง errors กลับไปพร้อม status code 400
class RespondInvitationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        invitation_id = request.data.get("invitation_id")

        # ตรวจสอบคำเชิญ
        try:
            invitation = PartyInvitation.objects.get(id=invitation_id)
        except PartyInvitation.DoesNotExist:
            return Response({"error": "Invitation not found or you are not the receiver"}, status=404)
        invitation.status ='accepted'
        invitation.save()
        if invitation.status=='accepted':
             data={
                     'party':invitation.party.id,
                     'user':invitation.receiver.id,
                     'join_date':now().date(),

                }
             serializer=Memberserializer(data=data)
             if serializer.is_valid():
                  member=serializer.save()
                  print(f'member:{member}')
                  token=UserFCMToken.objects.get(user=invitation.sender.id)
                  title=f'คำเชิญของคุณได้รับการยืนยันเเล้ว'
                  body=f'คำเชิญเข้าร่วมปาร์ตี้ของคุณได้รับการยืนยันเเล้วจาก{invitation.receiver.username}\n เวลา {now().date()} {now().time()}'
                  data={
                       'type':'invitation'
                  }
                  invitation.delete()
                  send_fcm_notification(token=token.fcm_token,title=title,body=body,data=data)
                  return Response({'message':'ยอมรับคำขอเเล้ว'},status=200)
             else:
               print(serializer.errors)
               return Response(serializer.errors,status=status.HTTP_400_BAD_REQUEST)
        # อัปเดตสถานะ
        else:
            return Response({'message':'invitation is not accepted'},status=status.HTTP_404_NOT_FOUND)
        
class ReceivedInvitationsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user=request.headers.get('userId')
        invitations=PartyInvitation.objects.filter(receiver=user)
        serializer=PartyInvitationserializer(invitations,many=True)
        print(serializer.data)
        return Response(serializer.data, status=200)
class fecthallparty(APIView):
      
      def get(self,request):
        parties = Party.objects.exclude(leader=request.user)
        serializer = partyserializer(parties, many=True)
        print({f'data:{serializer.data}'})
        return Response(serializer.data, status=200)
class secarchparty(APIView):
     permission_classes = [AllowAny]
     def get(self,request):
            search_query = request.headers.get("search", "")
            party_type = request.headers.get("type", "All")

            # ค้นหาข้อมูลตามคำค้นหาและประเภท
            parties = Party.objects.all()
            if search_query:
                parties = parties.filter(Q(name__icontains=search_query))
            if party_type != "All":
                parties = parties.filter(type=party_type)

            # แปลงข้อมูลเป็น JSON
            result = parties
            serializer=partyserializer(result,many=True)
            return JsonResponse(serializer.data,status=200)
class filterParty(APIView):
     permission_classes = [AllowAny]
     def post(self, request):
        query = request.data.get('type')  # ประเภทของการออกกำลังกาย
        try:
            # ตรวจสอบว่า ExerciseType มีอยู่หรือไม่
            partytype = ExerciseType.objects.get(name=query)
        except ExerciseType.DoesNotExist:
            return Response({'message': "ไม่เจอประเภท"}, status=404)

        # กรองปาร์ตี้ตามประเภท และต้องไม่ใช่ปาร์ตี้ที่ผู้ใช้เป็น leader
        results = Party.objects.filter(exercise_type=partytype).exclude(leader=request.user)

        # Serialize ข้อมูล
        serializer = partyserializer(results, many=True)
        print(f'ข้อมูล: {serializer.data}')
        return Response(serializer.data, status=200)
          
class joinrequest(APIView):
    permission_classes = [IsAuthenticated]
    

    def post(self, request):
        party_id = request.data.get('party')
        sender_id = request.data.get('sender')
        receiver_id = request.data.get('receiver')

        # ตรวจสอบ party
        try:
            party = Party.objects.get(id=party_id)
        except Party.DoesNotExist:
            return Response({'error': 'Party does not exist.'}, status=404)

        # ตรวจสอบ sender
        try:
            sender = CustomUser.objects.get(id=sender_id)
        except CustomUser.DoesNotExist:
            return Response({'error': 'Sender does not exist.'}, status=404)

        # ตรวจสอบ receiver (ถ้ามี)
        receiver = None
        if receiver_id:
            try:
                receiver = CustomUser.objects.get(id=receiver_id)
            except CustomUser.DoesNotExist:
                return Response({'error': 'Receiver does not exist.'}, status=404)

        # เตรียมข้อมูล serializer
        data = {
            
            'party': party.id,
            'sender': sender.id,
            'send_date': now().date(),
            'send_time': now().time(),
            'status': 'pending',
            'reviewed_by': receiver.id if receiver else None,
        }

        serializer = JoinRequestserializer(data=data)
        if serializer.is_valid():
            join_request=serializer.save()#เเก้ให้serializer.saveเก็บในjoin_request
            token=UserFCMToken.objects.get(user=receiver_id)
            title=f'มีคำคอเข้าร่วมปาร์ตี้จาก{sender.username}'
            body=f'{sender.username} ต้องการเข้าร่วมปาร์ตี้ของคุณ\nส่งคำข้อเมื่อเวลา {now().date()}  {now().time()}'
            data={
                 'partyId':str(party_id),
                 'senderId':str(sender.id),
                 'joinrequestId':str(join_request.id),#เพิ่มjoirequestid
                 'type':'join_party'
            }
            send_join_request(token=token.fcm_token,title=title,body=body,data=data)
            return Response('message:joinrequest was sended',status=200)
        
            
          
           
        else:
            return Response(serializer.errors, status=400)
class responseRequest(APIView):
      permission_classes = [IsAuthenticated]
      def post(self,request):
           user=request.data.get('userid')
           party=request.data.get('party_id')
           joinrequest=request.data.get('joireqest_id')
           
           try:
                
                user=CustomUser.objects.get(id=user)
                print(f'userID:{user}')
                
           except CustomUser.DoesNotExist:
                return Response({'error': 'Receiver does not exist.'}, status=404)
           try:
                party=Party.objects.get(id=party)
                print(f'ปาร์ตี้ID{party}')
                
           except Party.DoesNotExist:
                return Response({'error': 'Receiver does not exist.'}, status=404)
           try:
                joinrequest_id=JoinRequest.objects.get(id=joinrequest)
                print(f'IDคำขอเข้าร่วม:{joinrequest_id}')
           except JoinRequest.DoesNotExist:
                    return Response({'error': 'Receiver does not exist.'}, status=404)
           joinreq=JoinRequest.objects.get(id=joinrequest_id.id)
           joinreq.status='accepted'
           joinreq.save()
           print(f'ค่าปาร์ตี้ก่อนส่งไปบันทึก{joinreq.party}')
           print(f'ค่าuserก่อนส่งไปบีนทึก{joinreq.reviewed_by}')
           if joinreq.status == 'accepted':
                data={
                     'party':joinreq.party.id,
                     'user':joinreq.sender.id,
                     'join_date':now().date(),

                }
                serializer=Memberserializer(data=data)
                if serializer.is_valid():
                     member=serializer.save()
                     token=UserFCMToken.objects.get(user=joinreq.sender.id)
                     print(f'tokenของuserที่จะได้รับเเจ้งเตือน:{token}')
                     title=f'คำขอเข้าร่วมปาร์ตี้ได้รับการยอมรับ'
                     body=f'คำขอเข้าร่วมปาร์ตี้ได้รับการยอมรับเเล้วจาก{joinreq.reviewed_by.username}\nเวลา {now().date()} {now().time()}'
                     data={
                          'memberid':str(member.id),
                     }
                     send_fcm_notification(token=token.fcm_token,title=title,body=body,data=data,)
                     joinreq.delete()#พิ่มส่วนนี้เพื่อลบคำขอที่ได้รับการตอบกลับเเล้ว
                     return Response({'message':'ยืนยันเข้าร่วมเเล้ว'},status=200)
                else:
                     print(f'ข้อมูลไม่ถูกต้อง')
                     return Response({'message':'ข้อฒูลไม่ถูกต้อง'},status=404)
           else:
                joinreq.delete()#พิ่มส่วนนี้เพื่อลบคำขอที่ได้รับการตอบกลับเเล้ว
                return Response({'message':'ปฏิเสธ'},status=200)
class Recievjoinrequest(APIView):
        permission_classes = [IsAuthenticated]
        def get(self,request):
            user=request.headrs.get('uerid')
            try:
                joinreq=JoinRequest.objects.filter(reviewed_by=user)
            except:
                 print('ไม่มีคำชวน')
            serializer=JoinRequestserializer(joinreq,many=True)
            if serializer.is_valid():
                 serializer.save()
                 return Response(serializer.data,status=200)
class fectallrequest(APIView):
     permission_classes = [AllowAny]
     def get(self, request):
        user_id = request.headers.get('userId')
        try:
            user = CustomUser.objects.get(id=user_id)
        except CustomUser.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        join_req = JoinRequest.objects.filter(reviewed_by=user)
        serializer = JoinRequestserializer(join_req, many=True)
        print(f'{serializer.data}')
         # ไม่จำเป็นต้องเรียก is_valid() ถ้าใช้ serializer กับ queryset
        return Response(serializer.data, status=status.HTTP_200_OK)

         
class feachallintavition(APIView):
    permission_classes = [AllowAny]
    
    def get(self,reqeust):
      user_id=reqeust.headers.get('user') 
      user=CustomUser.objects.get(id=user_id)
      join_req=JoinRequest.objects.filter(reviewed_by=user)
      serializer=JoinRequestserializer(join_req,many=True)
      if serializer.is_valid():
            serializer.save()
            return Response(serializer.data,status=200)
      else:
            return Response({'message':f'Error data not valid'})
class SaveFCMTokenAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        fcm_token = request.data.get('fcm_token')
        user_id = request.data.get('user_id')

        # ตรวจสอบว่า user_id เป็น UUID ที่ถูกต้อง
        try:
            user = CustomUser.objects.get(id=UUID(user_id))  # ใช้ UUID เพื่อค้นหาผู้ใช้

            # อัปเดตหรือสร้าง UserFCMToken
            UserFCMToken.objects.update_or_create(
                user=user,  # ใช้ instance ของ user
                defaults={"fcm_token": fcm_token},
            )

            return Response({"message": "FCM token saved successfully"}, status=status.HTTP_200_OK)

        except ValueError:
            return Response({"error": "Invalid UUID format for user_id"}, status=status.HTTP_400_BAD_REQUEST)
        #except ObjectDoesNotExist:
            #return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

class fecthallfriend(APIView):
      permission_classes = [AllowAny]
      def get(self,request):
           userid=request.headers.get('userId')
           try:
                user=CustomUser.objects.get(id=userid)
           except:
                return Response({'massage':'not found user!!!'})
           friends=Friend.objects.filter(user=user)
           serializer=Friendserializer(friends,many=True)
           print(f'ค่าที่ส่งไป{serializer.data}')
           return Response(serializer.data,status=200)
class SearchFriendView(APIView):
    

    def get(self, request):
        query = request.query_params.get('q', '')  # รับคำค้นหาจาก query string
        if not query:
            return Response({"error": "Please provide a search query."}, status=400)

        # ค้นหาผู้ใช้ที่มีชื่อผู้ใช้ (username) หรืออีเมลที่ตรงกับคำค้นหา
        results = CustomUser.objects.filter(
            Q(username__icontains=query) | Q(email__icontains=query)
        ).exclude(id=request.user.id)  # ไม่รวมตัวเอง

        # แปลงผลลัพธ์เป็น JSON
        data = [
            {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "profile_image": user.profile_image.url if user.profile_image else None
            }
            for user in results
        ]
        print(f'รายชื่อรายการค้นหา:{data}')
        return Response(data, status=200)

class FetchUserProfile(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user_id = request.headers.get('userId')
        if not user_id:
            return Response({'message': 'User ID is required'}, status=400)

        try:
            user = CustomUser.objects.get(id=user_id)

            # ✅ ป้องกัน Error ถ้าไม่มี BackgroundProfile
            backgroud = BackgroundProfile.objects.filter(user=user).first()

            # ✅ เช็คว่า backgroud มีค่า ไม่ใช่ None ก่อนเรียก background_image
            background_image_url = None
            if backgroud and backgroud.background_image:
                background_image_url = backgroud.background_image.url

            # ✅ Debugging Log
            if backgroud:
                print(f'✅ รูปพื้นหลัง: {backgroud.background_image}')
            else:
                print('❌ User ไม่มี BackgroundProfile')

            # ✅ จัดรูปแบบข้อมูลที่ส่งกลับ
            data = {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'gender':user.gender,
                'profile_image': user.profile_image.url if user.profile_image else None,
                'description': user.description,
                'background': background_image_url,  # ✅ ป้องกัน Error
                'exercise_times': [
                    {
                        'id': time.id,
                        'start_time': time.available_time_start,
                        'end_time': time.available_time_end,
                        'day': time.available_day,
                    }
                    for time in ExerciseTime.objects.filter(user=user)
                ],
                'exercise_types': [
                    {
                        'id': et.id,
                        'excercise_id':et.exercise_type.id, #เพิ่มส่วนนี้
                        'name': et.exercise_type.name if et.exercise_type else None
                    }
                    for et in UserExerciseType.objects.filter(user=user)
                ],
            }

            return Response(data, status=200)

        except Exception as e:
            print(f'Error: {e}')
            return Response({'message': 'An error occurred while fetching the profile'}, status=500)
class Friendrequest(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        friend_id = request.data.get('friend')
        user_id = request.data.get('user')
        print(f"Friend ID: {friend_id}, User ID: {user_id}")

        try:
            friend = CustomUser.objects.get(id=friend_id)
            user = CustomUser.objects.get(id=user_id)
            print(f"Friend: {friend}, User: {user}")

            data = {
                
                'sender': user.id,
                'receiver': friend.id,
                'send_date': now().date(),
                'send_time': now().time(),
                'status': 'pending'
            }
            print(f"Data: {data}")

            friend_req = Friendrequestserializer(data=data)
            if friend_req.is_valid():
                friend_req.save()
                print("Friend request saved successfully.")

                try:
                    token = UserFCMToken.objects.get(user=friend.id)
                    print(f"FCM Token: {token.fcm_token}")

                    title = f'คำขอเป็นเพื่อนจาก {friend.username}'
                    body = f'มีคำขอเป้นเพื่อนจาก {friend.username}\nเมื่อ {now().date()} เวลา {now().time()}'
                    data = {'friendreq': str(friend_id),'type':'friend_request'}

                    print(f"Token: {token.fcm_token}")
                    print(f"Title: {title}")
                    print(f"Body: {body}")
                    print(f"Data: {data}")

                    send_fcm_notification(token=token.fcm_token, title=title, body=body, data=data)
                except Exception as e:
                    print(f"Error retrieving FCM token or sending notification: {e}")

                return Response(friend_req.data, status=200)
            else:
                print("Friend request data is not valid.")
                return Response({'message': 'data not valid'})

        except Exception as e:
            print(f"Error in Friendrequest API: {e}")
            return Response({'message': 'user and friend not found', 'error': str(e)})
class acepceptfriend(APIView):
     permission_classes = [IsAuthenticated]
     def post(self,request):
          friendreq_id=request.data.get('friendreq')
          print(f'freind_id:{friendreq_id}')
          try:
               friendreq=FriendRequest.objects.get(id=friendreq_id)
               friendreq.status='accepted'
               friendreq.save()
               print(f'สถานะคำขอ:{friendreq.status}')
               if friendreq.status=='accepted':
                    data_receiver_to_sender={
                           'user': friendreq.receiver.id,
                           'friend_user':friendreq.sender.id,
                           'status': True
                    }
                    print(f'data:{data_receiver_to_sender}')
                    friend=Friendserializer(data=data_receiver_to_sender)
                    if friend.is_valid():
                         friend.save()
                         print('accept friend succesed')
                         data_sender_to_receiver={
                           'user': friendreq.sender.id,
                           'friend_user':friendreq.receiver.id,
                           'status': True
                         }
                         print(f'data_sender_to_receiver:{data_sender_to_receiver}');
                         friend_sender_to_receiver =Friendserializer(data=data_sender_to_receiver)
                         if friend_sender_to_receiver.is_valid():
                              friend_sender_to_receiver.save()
                              friendreq.delete()
                         return Response(friend.data,status=200)
                    else:
                        print('ข้อมูลไม่ถูกต้อง')
                        return Response({'message':'ข้อมูลไม่ถูกต้อง'},status=404)
               else: 
                    print('คำขอไม่ได้ accecpt')
                    return Response({'message':'friendrequest is not accepted'},status=404)   
                    
          except Exception as e:
               print('not found friendrequest')
               return Response({'message':f'{e}'},status=404)

class rejectfriend(APIView):
       permission_classes = [IsAuthenticated]
       def post(self,request):
           friendreq_id=request.data.get('friendreq')
           try:
                friendreq=FriendRequest.objects.get(id=friendreq_id)
                friendreq.status='rejected'
                print(f'{friendreq.status}');
                if friendreq.status=='rejected':
                     friendreq.delete()
                     print('ปฏิเสธเเล้ว')
                     return Response({'message':'ปฏิเสธเเล้ว'},status=200)
                else :
                    return Response({'message':'friendrequest status is not rejected '})
           except Exception as e:
                return Response({'message':f'Error{e}'},status=404)
class showfriendrequest(APIView):
          
           def get(self,request):
                user_id=request.headers.get('userId') 
                try:
                     user=CustomUser.objects.get(id=user_id)
                     frienrequest=FriendRequest.objects.filter(receiver=user.id).select_related('sender','receiver')
                     serializer=Friendrequestserializer(frienrequest,many=True)
                     print(f'คำขอเป้นเพื่อนทั้งหมด:{serializer.data}')
                     return Response(serializer.data,status=200)
                except Exception as e:
                     return Response({'message':f'{e}'},status=404)
class rejectedjointrequest(APIView):
     permission_classes = [IsAuthenticated]
     def post(self,request):
          senderid=request.data.get('senderId')
          jointreqid=request.data.get('joinreqestId')
          try:
               sender=CustomUser.objects.get(id=senderid)
               print(f'ผู้ส่งคำขอ:{sender}')
               joinreq=JoinRequest.objects.get(id=jointreqid)
               joinreq.status='rejected'
               joinreq.save()
               if joinreq.status == 'rejected':
                    token=UserFCMToken.objects.get(user=sender.id)
                    print(f'FCMToken:{token.fcm_token}')
                    title=f'คำขอของเข้าร่วมปาร์ตี้ของคุณถูกปฎิเสธ'
                    body=f'คำขอเข้าร่วมของคุณถูกปฎิเสธ'
                    send_fcm_notification(token=token.fcm_token,title=title,body=body)
                    joinreq.delete()
                    print('ปฎิเสธเเล้ว')
                    return Response({'message':'ปฎิเสธเเล้ว'},status=200)
               else:
                    return Response({'message':'request status was not rejected'})
          except Exception as e:
               print({e})
               return Response({'message':f'{e}'})
class leaveparty(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.data.get('user_id')  # ผู้ใช้ที่ทำการออกจากปาร์ตี้
        party_id = request.data.get("party_id")

        # ตรวจสอบว่าป้อน party_id หรือไม่
        if not party_id:
            return Response({"error": "Party ID is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            party = Party.objects.get(id=party_id)
        except Party.DoesNotExist:
            return Response({"error": "Party not found"}, status=status.HTTP_404_NOT_FOUND)

        # ตรวจสอบว่าผู้ใช้อยู่ในปาร์ตี้หรือไม่
        if not PartyMember.objects.filter(party=party, user=user).exists():
            return Response({"error": "You are not a member of this party"}, status=status.HTTP_403_FORBIDDEN)

        # ถ้าผู้ใช้เป็น Leader ของปาร์ตี้
        if party.leader == user:
            members = PartyMember.objects.filter(party=party).exclude(user=user)

            if members.exists():  # ถ้ามีสมาชิกเหลืออยู่ เปลี่ยน Leader ใหม่
                new_leader = members.first().user  # เลือกสมาชิกคนแรกเป็น Leader
                party.leader = new_leader
                party.save()
                response_message = f"You left the party. {new_leader.username} is the new leader."
            else:  # ถ้าไม่มีสมาชิกคนอื่น ลบปาร์ตี้
                party.delete()
                return Response({"message": "You were the last member. The party has been deleted."}, status=status.HTTP_200_OK)

        # ถ้าผู้ใช้เป็นสมาชิกธรรมดา ให้ออกจากปาร์ตี้
        PartyMember.objects.filter(party=party, user=user).delete()
        return Response({"message": "You have left the party."}, status=status.HTTP_200_OK)

class rejectedinvitetaion(APIView):
       permission_classes = [IsAuthenticated]
       def post(self,request):
                invitations_id=request.data.get('invitation_id')
                invitation=PartyInvitation.objects.get(id=invitations_id)
                invitation.status='rejected'
                invitation.save()
                if invitation.status=='rejected':
                     invitation.delete()
                     print('ปฏิเสธเเล้ว')
                     return Response({'message':'ปฏิเสธเเล้ว'},status=200)
                else :
                    return Response({'message':'friendrequest status is not rejected '})
          

class RefreshAccessTokenView(APIView):
    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response({"error": "Refresh token is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            refresh = RefreshToken(refresh_token)
            access_token = str(refresh.access_token)
            return Response({"access": access_token}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
                    
class UpdateProfile(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        userid=request.headers.get('userId')
        update_data=request.data.get('updateprofile')
        print(f'user:{userid}')
        print(f'ข้อมูลที่อัพเดต:{update_data}')
        user=CustomUser.objects.get(id=userid)

        user.username=update_data.get('username',user.username)
        user.email=update_data.get('email',user.email)
        user.description=update_data.get('description',user.description)

        if 'profile_image' in update_data and update_data["profile_image"]:
            new_profile_image = update_data["profile_image"].replace("/media/", "")
            if user.profile_image and user.profile_image.name != new_profile_image:
                user.profile_image = new_profile_image
        user.save()

        if "background_image" in update_data and update_data["background_image"]:
            new_background = update_data["background_image"].replace("/media/", "")
            bg_profile, created = BackgroundProfile.objects.get_or_create(user=user)
    
            if bg_profile.background_image and bg_profile.background_image.name != new_background:
                bg_profile.background_image = new_background
                bg_profile.save()
        if "exercise_types" in update_data and update_data["exercise_types"]:  # ✅ เช็คว่ามีข้อมูลใหม่
            UserExerciseType.objects.filter(user=user).delete()  # 🔥 ลบข้อมูลเก่าเฉพาะตอนที่มีข้อมูลใหม่
    
            for ex_type in update_data["exercise_types"]:
                try:
                    if isinstance(ex_type, str) and ex_type.startswith("{"):  # ✅ เช็คถ้าเป็น String JSON
                        ex_type_dict = json.loads(ex_type.replace("'", "\""))  
                        exercise_type_id = ex_type_dict["id"]
                    elif isinstance(ex_type, (int, str)) and str(ex_type).isdigit():  # ✅ เช็คถ้าเป็น int หรือ String ของตัวเลข
                        exercise_type_id = int(ex_type)
                    else:
                        print(f"❌ Invalid format: {ex_type}")
                        continue  

                    UserExerciseType.objects.create(user=user, exercise_type_id=exercise_type_id)  # ✅ สร้างข้อมูลใหม่
                except (json.JSONDecodeError, KeyError, TypeError) as e:
                    print(f"❌ JSON Error: {ex_type} - {e}")  # Debugging  # Debugging
        if "exercise_times" in update_data:
                ExerciseTime.objects.filter(user=user).delete()  # ลบข้อมูลเก่า
                
                for time in update_data["exercise_times"]:
                    ExerciseTime.objects.create(
                        user=user,
                        available_day=time["day"],
                        available_time_start=time["start_time"],
                        available_time_end=time["end_time"]
                    )

        return Response({"message": "โปรไฟล์อัปเดตเรียบร้อยแล้ว"}, status=200)  
class addTocalendar(APIView):
    permission_classes = [IsAuthenticated]
    def post(self,reqeust):
        user_id=reqeust.headers.get('userId')
        user=CustomUser.objects.get(id=user_id)
        party_id=reqeust.headers.get('partyId')
        party=Party.objects.get(id=party_id)
        member=PartyMember.objects.get(user=user.id,party=party.id)
        event_data=reqeust.data
        print(f'ข้อมูลนัดหมาย:{event_data}')
        data={
             'member': member.id,
             'created_at': datetime.now()

        }
        serializer=PartymemberEventserializer(data=data)
        if serializer.is_valid():
             serializer.save()
             result=member_event(party_id=party.id,userid=user.id,event_data=event_data)
             if isinstance(result, dict) and "auth_url" in result:
                return Response(result, status=401)
             return Response({'message':'เพิ่มนัดหมายเเล้ว'},status=200)
class getmemberevent(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, party_id):
        user_id = request.headers.get('userId')
        user = CustomUser.objects.get(id=user_id)
        party = Party.objects.get(id=party_id)
        member = PartyMember.objects.filter(user=user.id, party=party.id).first()

        if not member:
            return Response({"error": "คุณยังไม่ได้เข้าร่วมปาร์ตี้นี้"}, status=404)

        memberevent = PartyMemberEvent.objects.filter(member=member.id).first()
        
        if not memberevent:
            return Response(None, status=200)

        serializer = PartymemberEventserializer(memberevent)
        return Response(serializer.data, status=200)
class updatememberevent(APIView):
     permission_classes= [IsAuthenticated]
     def put(self,request,party_id):
           user_id=request.headers.get('userId')
           user=CustomUser.objects.get(id=user_id)
           party=Party.objects.get(id=party_id)
           event_data=request.data
           results=update_memberevent(userid=user.id,party_id=party.id,updated_data=event_data)
           return Response(results,status=200)
class upcomingparty(APIView):
     def get(self, request):
        current_time = now().date()  # ✅ เอาเฉพาะวันที่ปัจจุบัน
        next_day = current_time + timedelta(days=1)  # ✅ เอาวันถัดไป
        user = request.headers.get('userId')

        if not user:
            return Response({"error": "User ID ไม่ถูกต้อง"}, status=400)

        # ✅ ปาร์ตี้ที่ user เป็น leader และจะเกิดขึ้น "พรุ่งนี้"
        created_parties = Party.objects.filter(
            leader=user,
            date=current_time + timedelta(days=1),  # ⏳ คัดเฉพาะปาร์ตี้ที่ใกล้จะถึง (1 วันข้างหน้า)
            status="waiting"
        )

        # ✅ ปาร์ตี้ที่ user เข้าร่วมและจะเกิดขึ้น "พรุ่งนี้"
        joined_parties = Party.objects.filter(
            partymember__user=user,
            date=current_time + timedelta(days=1),  # ⏳ คัดเฉพาะปาร์ตี้ที่ใกล้จะถึง (1 วันข้างหน้า)
            status="waiting"
        )

        # ✅ รวมปาร์ตี้ที่ user สร้างและเข้าร่วม
        all_parties = (created_parties | joined_parties).distinct().order_by('date')

        print(f"📌 ปาร์ตี้ที่สร้าง: {created_parties.count()}")
        print(f"📌 ปาร์ตี้ที่เข้าร่วม: {joined_parties.count()}")
        print(f"✅ ปาร์ตี้ที่พบทั้งหมด: {all_parties.count()}")

        if all_parties.exists():
            serializer = partyserializer(all_parties, many=True)
            return Response(serializer.data, status=200)
        else:
            return Response({"message": "ไม่มีปาร์ตี้ที่กำลังจะเกิดขึ้นใน 1 วันข้างหน้า"}, status=200)
class recomenparty(APIView):
       def get(self, request):
        user_id = request.headers.get('userId')

        try:
            # ✅ ตรวจสอบว่าผู้ใช้มีอยู่ในระบบหรือไม่
            user = CustomUser.objects.get(id=user_id)

            # ✅ ดึงประเภทออกกำลังกายที่ผู้ใช้สนใจ
            workout_types = UserExerciseType.objects.filter(user=user).values_list('exercise_type', flat=True)
            if not workout_types:
                return Response({"error": "ผู้ใช้ยังไม่ได้ตั้งค่าประเภทการออกกำลังกาย"}, status=404)

            # ✅ ดึงปาร์ตี้ที่ตรงกับประเภทออกกำลังกายที่ผู้ใช้สนใจ
            recommended_parties = Party.objects.filter(
                exercise_type__in=workout_types,  # ✅ ใช้ประเภทที่ผู้ใช้สนใจเป็นเงื่อนไข
                status="waiting"
            ).exclude(
                Q(leader=user) | Q(partymember__user=user)  # ✅ ไม่รวมปาร์ตี้ที่ผู้ใช้เป็นหัวหน้าหรือเข้าร่วมแล้ว
            ).distinct().order_by('date', 'start_time')[:5]  # ✅ เรียงตามวันที่และเวลาเริ่มต้น

            # ✅ Debugging
            print(f"📌 ปาร์ตี้ที่ตรงกับประเภทออกกำลังกาย: {recommended_parties.count()}")

            if recommended_parties.exists():
                serializer = partyserializer(recommended_parties, many=True)
                return Response(serializer.data, status=200)
            else:
                return Response({"message": "ไม่มีปาร์ตี้แนะนำในขณะนี้"}, status=200)

        except CustomUser.DoesNotExist:
            return Response({"error": "ไม่พบผู้ใช้ในระบบ"}, status=404)
        except Exception as e:
            return Response({"error": str(e)}, status=500)
        


class check_status(APIView):
        permission_classes= [IsAuthenticated]
        def get(self,request):
          
          party_id=request.headers.get('partyId')
          leader_id=request.headers.get('leader')
          leader=CustomUser.objects.get(id=leader_id)
          party=Party.objects.get(id=party_id,leader=leader.id)
          partystatus=party.status
          return Response(partystatus,status=200) 
class NotiToMember(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        party_id = request.headers.get('partyId')
        user_id = request.headers.get('userId')  
        user = CustomUser.objects.get(id=user_id)
        party = Party.objects.get(id=party_id)

        # ✅ หัวข้อและเนื้อหาการแจ้งเตือน
        title = f'ปาร์ตี้ {party.name} เริ่มออกเดินทางแล้ว!'
        body = f'{user.username} ได้เริ่มออกเดินทางไปยังสถานที่นัดหมายแล้ว 🚶‍♂️\n' \
               f'วัน: {now().date()}  เวลา: {now().time()}'

        data = {
            'type': 'start_navigation',
            'party': str(party.id)
        }

        # ✅ ดึง FCM Token ของสมาชิกทั้งหมดรวมถึง Leader
        members = PartyMember.objects.filter(party=party.id)
        fcm_tokens = [token.fcm_token
                      for member in members
                      for token in UserFCMToken.objects.filter(user=member.user)]

        # ✅ ดึง Token ของ Leader ด้วย (ถ้า Leader ไม่ใช่คนกดเอง)
        if user.id != party.leader.id:
            leader_token = UserFCMToken.objects.filter(user=party.leader).values_list('fcm_token', flat=True)
            fcm_tokens.extend(leader_token)

        # ✅ ส่งการแจ้งเตือน
        if fcm_tokens:
            print(f'ประเภทของ body: {type(body)}')

            # ✅ วนลูปส่งแจ้งเตือนทีละ Token
            for token in fcm_tokens:
                send_fcm_notification(token=token, title=title, body=body, data=data)

        return Response({"message": "แจ้งเตือนส่งเรียบร้อยแล้ว"}, status=200)
class fecthcheckinmember(APIView):
      
    permission_classes = [IsAuthenticated]

    def get(self, request):
        party_id = request.headers.get('partyId')

        try:
            party = Party.objects.get(id=party_id)
            members = PartyMember.objects.filter(party=party)

            member_statuses = [
                {
                    "id": member.user.id,
                    "username": member.user.username,
                    "profile_image": member.user.profile_image.url if member.user.profile_image else None,
                    "checkin_status": member.checkin_status,
                    "checkin_time": member.checkin_time.strftime('%Y-%m-%d %H:%M:%S') if member.checkin_time else None
                }
                for member in members
            ]

            return Response(member_statuses, status=200)

        except Party.DoesNotExist:
            return Response({"error": "Party not found"}, status=404)
        except Exception as e:
            return Response({"error": str(e)}, status=500)
class CheckInToWorkout(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        user_id = request.headers.get('userId')
        party_id = request.headers.get('partyId')

        try:
            user = CustomUser.objects.get(id=user_id)
            party = Party.objects.get(id=party_id)
        except CustomUser.DoesNotExist:
            return Response({"error": "User not found"}, status=404)
        except Party.DoesNotExist:
            return Response({"error": "Party not found"}, status=404)

        try:
            member = PartyMember.objects.get(user=user, party=party)
        except PartyMember.DoesNotExist:
            return Response({"error": "You are not a member of this party"}, status=403)

        # 🔥 เช็คว่าผู้ใช้เช็คอินไปแล้วหรือยัง
        if member.checkin_status:
            return Response({'message': 'You have already checked in'}, status=200)

        # ✅ อัพเดตสถานะเช็คอิน
        member.checkin_status = True
        member.checkin_time = now()  # บันทึกเวลาปัจจุบันที่เช็คอิน
        member.save()

        # ✅ ส่งการแจ้งเตือน
        title = f'ปาร์ตี้ {party.name} เช็คอินแล้ว!'
        body = f'{user.username} ถึงสถานที่ออกกำลังกายแล้ว 🚶‍♂️\n' \
               f'วัน: {now().date()}  เวลา: {now().time()}'

        data = {
            'type': 'start_navigation',
            'party': str(party.id)
        }

        # ✅ ดึง FCM Token ของสมาชิกทั้งหมด
        members = PartyMember.objects.filter(party=party)
        fcm_tokens = [token.fcm_token
                      for member in members
                      for token in UserFCMToken.objects.filter(user=member.user)]
        leader_token = UserFCMToken.objects.filter(user=party.leader).values_list('fcm_token', flat=True)
        fcm_tokens.extend(leader_token)
        # ✅ ส่งการแจ้งเตือนทีละคน
        if fcm_tokens:
            for token in fcm_tokens:
                send_fcm_notification(token=token, title=title, body=body, data=data)

        return Response({'message': 'เช็คอินสำเร็จ'}, status=200)
class Checkoutoworkout(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        user_id = request.headers.get('userId')
        party_id = request.headers.get('partyId')

        try:
            user = CustomUser.objects.get(id=user_id)
            party = Party.objects.get(id=party_id)
        except CustomUser.DoesNotExist:
            return Response({"error": "User not found"}, status=404)
        except Party.DoesNotExist:
            return Response({"error": "Party not found"}, status=404)

        try:
            member = PartyMember.objects.get(user=user, party=party)
        except PartyMember.DoesNotExist:
            return Response({"error": "You are not a member of this party"}, status=403)

        # 🔥 เช็คว่าผู้ใช้ยังไม่ได้เช็คอิน
        if not member.checkin_status:
            return Response({'message': 'You have not checked in yet'}, status=400)

        # ✅ อัพเดตสถานะเช็คอินกลับเป็น False
        member.checkin_status = False
        member.checkin_time = now()  # บันทึกเวลาปัจจุบันที่ยกเลิกเช็คอิน
        member.save()

        # ✅ ส่งการแจ้งเตือน
        title = f'ปาร์ตี้ {party.name} ยกเลิกเช็คอิน!'
        body = f'{user.username} ได้ยกเลิกเช็คอิน 🚶‍♂️\n' \
               f'วัน: {now().date()}  เวลา: {now().time()}'

        data = {
            'type': 'cancel_checkin',
            'party': str(party.id)
        }

        # ✅ ดึง FCM Token ของสมาชิกทั้งหมดรวมถึง Leader
        members = PartyMember.objects.filter(party=party)
        fcm_tokens = [
            token.fcm_token
            for member in members
            for token in UserFCMToken.objects.filter(user=member.user)
        ]
        
        # ✅ เพิ่ม Token ของ Leader ด้วย
        leader_tokens = UserFCMToken.objects.filter(user=party.leader).values_list('fcm_token', flat=True)
        fcm_tokens.extend(leader_tokens)

        # ✅ ส่งการแจ้งเตือนทีละคน
        for token in fcm_tokens:
            send_fcm_notification(token=token, title=title, body=body, data=data)

        return Response({'message': 'ยกเลิกเช็คอินสำเร็จ'}, status=200)
class getcheckinstatus(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,request):
        party_id=request.headers.get('partyId')
        user_id=request.headers.get('userId')
        party=Party.objects.get(id=party_id)
        user=CustomUser.objects.get(id=user_id)
        member=PartyMember.objects.get(party=party.id,user=user.id)
        checkin_status=member.checkin_status
        print(f'ค่าstatusเช็คอินของ:{member.user.username}')
        return Response(checkin_status,status=200)
class StartWorkout(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        party_id = request.headers.get('partyId')
        user_id = request.headers.get('userId')

        try:
            user = CustomUser.objects.get(id=user_id)
            party = Party.objects.get(id=party_id)
        except CustomUser.DoesNotExist:
            return Response({"error": "User not found"}, status=404)
        except Party.DoesNotExist:
            return Response({"error": "Party not found"}, status=404)

        if user != party.leader:
            return Response({"error": "Only the leader can start the workout"}, status=403)

        # ✅ อัพเดตสถานะปาร์ตี้เป็น "in_progress"
        party.status = "ongoing"
        party.save()

        # ✅ ส่งการแจ้งเตือนให้สมาชิกทุกคนไปยังหน้า Timer
        title = f'ปาร์ตี้ {party.name} เริ่มออกกำลังกายแล้ว!'
        body = f'⏳ ปาร์ตี้ {party.name} กำลังเริ่มออกกำลังกาย 🎉'
        
        data = {
            'type': 'start_workout',
            'party': str(party.id)
        }

        members = PartyMember.objects.filter(party=party)
        fcm_tokens = [
            token.fcm_token
            for member in members
            for token in UserFCMToken.objects.filter(user=member.user)
        ]

        for token in fcm_tokens:
            send_fcm_notification(token=token, title=title, body=body, data=data)

        return Response({'message': 'ปาร์ตี้เริ่มออกกำลังกาย'}, status=200)
class GetpartyStatus(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,request):
        party_id=request.headers.get('partyId')
        party=Party.objects.get(id=party_id)
        party_status=party.status
        print(f'สถานะของปาร์ตี้{party_status}')
        return Response(party_status,status=200)
class FetchWorkoutTime(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
            party_id = request.headers.get('partyId')

            try:
                # ✅ ดึงข้อมูลปาร์ตี้
                party = Party.objects.get(id=party_id)

                # ✅ รวมวันและเวลาเป็น `datetime`
                date_str = str(party.date)  # เช่น "2025-02-20"
                finish_time_str = str(party.finish_time)  # เช่น "20:05:00"
                finish_datetime = datetime.strptime(f"{date_str} {finish_time_str}", "%Y-%m-%d %H:%M:%S")

                # ✅ ใช้โซนเวลา GMT+7 ที่ถูกต้อง
                bangkok_tz = timezone('Asia/Bangkok')

                # ✅ ตรวจสอบว่า `finish_datetime` เป็น naive หรือไม่
                if is_naive(finish_datetime):
                    finish_datetime = make_aware(finish_datetime, timezone=bangkok_tz)

                # ✅ แปลงให้แน่ใจว่าเป็น GMT+7
                finish_datetime = finish_datetime.astimezone(bangkok_tz)

                # ✅ แปลง `datetime` เป็น timestamp (Unix time)
                finish_timestamp = int(finish_datetime.timestamp())

                print(f"📌 finish_timestamp ที่ส่งไปยัง Flutter: {finish_timestamp}")

                # ✅ ส่งค่าให้ Flutter
                return Response({
                    "party_id": party.id,
                    "party_name": party.name,
                    "status": party.status,
                    "finish_timestamp": finish_timestamp  # ✅ ส่งเป็น timestamp แทน DateTime
                }, status=200)

            except Party.DoesNotExist:
                return Response({"error": "Party not found"}, status=404)
            except Exception as e:
                return Response({"error": str(e)}, status=500)

          
class finishparty(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        """
        ✅ Leader กดปิดปาร์ตี้ -> บันทึกประวัติ -> ลบปาร์ตี้
        """
        party_id = request.headers.get('partyId')

        try:
            # ✅ ค้นหาปาร์ตี้
            party = Party.objects.get(id=party_id)
            if party.status != 'ongoing':
                return Response({"error": "❌ ปาร์ตี้นี้ไม่ได้อยู่ในสถานะ 'ongoing'"}, status=status.HTTP_400_BAD_REQUEST)

            # ✅ ดึงสมาชิกทั้งหมดในปาร์ตี้
            members = PartyMember.objects.filter(party=party)
            party.status='completed'
            party.save()
            # ✅ บันทึกประวัติปาร์ตี้ลง PartyHistory
            for member in members:
                PartyHistory.objects.create(
                    user=member.user,
                    leader=party.leader,
                    party_id=party.id,
                    leader_name=party.leader.username,
                    party_name=party.name,
                    date=party.date,
                    completed_at=now(),
                    party_rating=None,  # สมาชิกสามารถให้คะแนนทีหลังได้
                    leader_rating=None  # สมาชิกสามารถให้คะแนน Leader ทีหลังได้
                )

            # ✅ ส่งการแจ้งเตือนให้สมาชิกทุกคน
            title = f'ปาร์ตี้ {party.name} จบแล้ว!'
            body = f'⏳ ปาร์ตี้ {party.name} จบการออกกำลังกายแล้ว'

            data = {
                'type': 'finish_workout',
                'party': str(party.id)
            }

            fcm_tokens = [
                token.fcm_token
                for member in members
                for token in UserFCMToken.objects.filter(user=member.user)
            ]

            for token in fcm_tokens:
                send_fcm_notification(token=token, title=title, body=body, data=data)

            # ✅ ลบปาร์ตี้หลังจากบันทึกประวัติเรียบร้อย
            

            return Response({"message": "✅ ปาร์ตี้จบแล้ว และถูกบันทึกเป็นประวัติ"}, status=status.HTTP_200_OK)

        except Party.DoesNotExist:
            return Response({"error": "❌ ไม่พบปาร์ตี้นี้"}, status=status.HTTP_404_NOT_FOUND)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
class getfinishworkout(APIView):
    permission_classes=[IsAuthenticated]
    def get(self, request):
        party_id = request.headers.get('partyId')

        try:
            party = Party.objects.get(id=party_id)
            members = PartyMember.objects.filter(party=party, checkin_status=True)

            total_members = members.count()
            completed_members = members.filter(finish_workout=True).count()
            
            # ✅ เช็คว่าปาร์ตี้จบหรือยังจาก database
            party_status = party.status  # ✅ ใช้ค่า `party.status` แทนการคำนวณเอง

            # ✅ ส่งเฉพาะสมาชิกที่ Check-in มาแล้ว
            member_statuses = [
                {
                    "id": member.user.id,
                    "username": member.user.username,
                    "profile_image": member.user.profile_image.url if member.user.profile_image else None,
                    "finish_workout": member.finish_workout
                }
                for member in members
            ]

            return Response({
                "total_members": total_members,
                "completed_members": completed_members,
                "status": party_status,  # ✅ ใช้ `party.status` จาก database
                "members": member_statuses
            }, status=200)

        except Party.DoesNotExist:
            return Response({"error": "Party not found"}, status=404)
        except Exception as e:
            return Response({"error": str(e)}, status=500)
class finishworkout(APIView):
    permission_classes=[IsAuthenticated]
    def put(self,request):
        party_id=request.headers.get('partyId')
        user_id=request.headers.get('userId')
        party=Party.objects.get(id=party_id)
        user=CustomUser.objects.get(id=user_id)
        member=PartyMember.objects.get(party=party.id,user=user.id)
        if member.finish_workout== False:
            member.finish_workout=True
            member.save()
            members = PartyMember.objects.filter(party=party)
            title = f'ปาร์ตี้ {party.name} !'
            body = f'{user.username} ออกเสร็จเเล้ว 🚶‍♂️\n' \
               f'วัน: {now().date()}  เวลา: {now().time()}'

            data = {
            'type': 'finish_workout',
            'party': str(party.id)
            }

            fcm_tokens = [token.fcm_token
                        for member in members
                        for token in UserFCMToken.objects.filter(user=member.user)]
            leader_token = UserFCMToken.objects.filter(user=party.leader).values_list('fcm_token', flat=True)
            fcm_tokens.extend(leader_token)
            # ✅ ส่งการแจ้งเตือนทีละคน
            if fcm_tokens:
                for token in fcm_tokens:
                    send_fcm_notification(token=token, title=title, body=body, data=data)
            return Response({'message':'finishworkout!'},status=200)

class fectworkoutstatus(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,reqeust):
        user_id=reqeust.headers.get('userId')
        user=CustomUser.objects.get(id=user_id)
        party_id=reqeust.headers.get('partyId')
        party=Party.objects.get(id=party_id)
        member=PartyMember.objects.get(party=party.id,user=user.id)
        workout_status=member.finish_workout
        return Response(workout_status,status=200)
class SubmitReview(APIView):
 permission_classes = [IsAuthenticated]

 def post(self, request):
        user_id = request.data.get("user_id")
        party_id = request.data.get("party_id")
        leader_rating = request.data.get("rating")
        leader_review= request.data.get('review')

        print(f"🟢 user_id: {user_id}, party_id: {party_id}")
        print(f"🟡 review_text:{leader_review} , leader_rating: {leader_rating}")

        try:
            user = CustomUser.objects.get(id=user_id)
    
    # ✅ ใช้ filter() แทน get() เพื่อป้องกันกรณีที่มีหลาย PartyHistory
            party_history = PartyHistory.objects.filter(user=user, party_id=party_id).first()

            if not party_history:
                return Response({"error": "ไม่พบประวัติปาร์ตี้"}, status=404)

            print(f'party_history:{party_history.id}')
            
            leader_id = party_history.leader.id
            print(f'leaderId:{leader_id}')
    
            leader = CustomUser.objects.get(id=leader_id)
            print(f'leader:{leader}')  # ดึง Leader ของปาร์ตี้นี้

    # ✅ บันทึกคะแนนโหวต Leader
            if leader_rating is not None:
                leader_vote, created = LeaderVote.objects.get_or_create(
                    party_history=party_history,
                    voter=user,
                    defaults={"leader": leader, "rating": leader_rating, "review_text": leader_review}
                )

                if not created:
                    leader_vote.rating = leader_rating
                    leader_vote.review_text = leader_review
                    leader_vote.save()

        # ✅ อัปเดตคะแนนของ Leader (เพิ่มคะแนนสะสม)
                leader.leader_score += leader_rating
                leader.save()

        # ✅ ตรวจสอบจำนวนคนโหวต
                total_members = PartyMember.objects.filter(party_id=party_id).count()
                voted_members = LeaderVote.objects.filter(party_history__party_id=party_id).count()

                print(f"🔎 Total Members: {total_members}, Voted Members: {voted_members}")

        # ✅ ถ้าทุกคนโหวตแล้ว ให้ลบปาร์ตี้
                if voted_members == total_members:
                    print("🚀 สมาชิกโหวตครบทุกคนแล้ว → ลบปาร์ตี้")
                    Party.objects.filter(id=party_id).delete()

            return Response({"message": "บันทึกคะแนนรีวิวสำเร็จ"}, status=200)

        except PartyHistory.DoesNotExist:
            return Response({"error": "ไม่พบประวัติปาร์ตี้"}, status=404)

        except CustomUser.DoesNotExist:
            return Response({"error": "ไม่พบผู้ใช้"}, status=404)

        except Exception as e:
            print(f'Error:{e}')
            return Response({"error": str(e)}, status=500)
class UploadPartyMemory(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)  # รองรับไฟล์และฟอร์ม

    def post(self, request):
        user = request.user
        print(f'user:{user}')  # ดึง user ที่ login อยู่
        party_id = request.data.get("party_id")
        print(f'partyid:{party_id}')
        image = request.FILES.get("image")  # รับไฟล์ภาพจาก request

        if not party_id or not image:
            return Response({"error": "ต้องระบุ party_id และอัปโหลดรูปภาพ"}, status=400)

        try:
            # ดึง PartyHistory ของปาร์ตี้นี้
            party_history = get_object_or_404(PartyHistory, party_id=party_id, user=user.id)

            # บันทึกข้อมูลใน PartyMemory (หรือ PartyPhoto ถ้าคุณใช้ model อื่น)
            party_memory = PartyMemory.objects.create(
                user=user,
                party_history=party_history,
                image=image
            )

            return Response({"message": "อัปโหลดรูปภาพสำเร็จ!", "image_url": party_memory.image.url}, status=200)

        except Exception as e:
            print(f'Error:{e}')
            return Response({"error": str(e)}, status=500)

      

class UserPartyHistory(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            user = request.user
            histories = PartyHistory.objects.filter(user=user).order_by("-date")

            data = []
            for history in histories:
                memories = PartyMemory.objects.filter(party_history=history)
                leader_votes = LeaderVote.objects.filter(party_history=history)  # ✅ ดึงรีวิวทุกคน
                
                leader = None
                leader_score = None
                reviews = []

                if leader_votes.exists():
                    leader = CustomUser.objects.get(id=leader_votes.first().leader.id)
                    leader_score = leader.leader_score
                    reviews = [
                        {"voter": vote.voter.username, "review": vote.review_text, "rating": vote.rating}
                        for vote in leader_votes
                    ]  # ✅ ดึงทุกรีวิวที่โหวต

                images = [mem.image.url for mem in memories]  # ✅ ดึงรูปทั้งหมดของปาร์ตี้นี้
                
                data.append({
                    "id": history.party_id,
                    "party_name": history.party_name,
                    "leader_name": history.leader_name,
                    "leader_score": leader_score,
                    "reviews": reviews,  # ✅ ส่งรีวิวทั้งหมดเป็น List
                    "date": history.date,
                    "images": images,
                      'completed_at':history.completed_at  # ✅ ใส่รูปที่เกี่ยวข้อง
                })

            return Response({"history": data}, status=200)
        except Exception as e:
            print(f'Error:{e}')
            return Response({"error": str(e)}, status=500)

class CreatupartyHistory(APIView):

    permission_classes=[IsAuthenticated]
    
    def get(self,request):
        user=request.user
        histories = PartyHistory.objects.filter(leader=user).order_by("-date")
        data = []
        try:
            for history in histories:
                memories = PartyMemory.objects.filter(party_history=history)
                leader_votes = LeaderVote.objects.filter(party_history=history)  # ✅ ดึงรีวิวทุกคน
                
                leader = None
                leader_score = None
                reviews = []

                if leader_votes.exists():
                    leader = CustomUser.objects.get(id=leader_votes.first().leader.id)
                    leader_score = leader.leader_score
                    reviews = [
                        {"voter": vote.voter.username, "review": vote.review_text, "rating": vote.rating}
                        for vote in leader_votes
                    ]  # ✅ ดึงทุกรีวิวที่โหวต

                images = [mem.image.url for mem in memories]  # ✅ ดึงรูปทั้งหมดของปาร์ตี้นี้
                
                data.append({
                    "id": history.party_id,
                    "party_name": history.party_name,
                    "leader_name": history.leader_name,
                    "leader_score": leader_score,
                    "reviews": reviews,  # ✅ ส่งรีวิวทั้งหมดเป็น List
                    "date": history.date,
                    "images": images,
                      'completed_at':history.completed_at  # ✅ ใส่รูปที่เกี่ยวข้อง
                })

            return Response({"created_parties": data}, status=200)
        except Exception as e:
            print(f'Error:{e}')
            return Response({"error": str(e)}, status=500)
class PartyPostView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """ ✅ ดึงโพสต์แยกจากรูปภาพ """
        posts = PartyPost.objects.all().order_by("-created_at")
        post_data = PartyPostSerializer(posts, many=True).data

        # ✅ สร้าง Dict เก็บข้อมูลผู้ใช้ (ดึงทีเดียว)
        user_ids = {post["user"] for post in post_data}  # ดึง user_id จากโพสต์
        users = CustomUser.objects.filter(id__in=user_ids)
        user_data = {str(user.id): CustomUserSerializer(user).data for user in users}

        # ✅ เพิ่ม images เข้าไปในแต่ละโพสต์
        for post in post_data:
            post_id = post["id"]
            party_history_id = post["party_history"]

            # 🔹 ดึงรูปจาก PartyMemory ที่เกี่ยวข้องกับโพสต์นี้
            #images = PartyMemory.objects.filter(party_history=party_history_id)ดึงมาทั้งmemmory
            #post["images"] = [mem.image.url for mem in images] ดึงมาทั้งmemmory
            images = PartyPostImage.objects.filter(post_id=post_id)
            post["images"] = [mem.image.url for mem in images]
            comments = PartyComment.objects.filter(post=post_id)
            likes=PartyPostLike.objects.filter(post=post_id)
            post['likes']=PartyPostLikeSerializer(likes,many=True).data
            post["comments"] = CommentSerializer(comments, many=True).data 
            # ✅ เพิ่มข้อมูลผู้ใช้เข้าไปในโพสต์
            post["user_data"] = user_data.get(str(post["user"]), {})

        return Response({"posts": post_data}, status=200)

    def post(self, request):
        """ สร้างโพสต์ใหม่ """
        user = request.user
        text = request.data.get("text")
        party_history_id = request.data.get("party_history_id")
        images = request.FILES.getlist("images")

        if not party_history_id:
            return Response({"error": "Missing party_history_id"}, status=400)

        post = PartyPost.objects.create(user=user, text=text, party_history_id=party_history_id)

        for image in images:
            PartyPostImage.objects.create(post=post, image=image)

        return Response({"message": "โพสต์สำเร็จ"}, status=200)
    
class PartyCommentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """ เพิ่มคอมเมนต์ """
        post_id=request.data.get('post_id')
        post = PartyPost.objects.get(id=post_id)
        text = request.data.get("comment")
        user_id=request.data.get('user_id')
        user=CustomUser.objects.get(id=user_id)
        comment = PartyComment.objects.create(user=user, post=post, text=text)

        return Response({"message": "คอมเมนต์สำเร็จ"}, status=200)
class ShareMemoryView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user_id = request.data.get("user_id")
        print(f'user_id:{user_id}')
        party_id = request.data.get("party_id")
        print(f'party_id:{party_id}')
        text = request.data.get("text", "")
        selected_images = request.data.get("selected_images", [])
        selected_images = [img.replace("/media/", "") for img in selected_images]
        print(f'รูปที่เลือก:{selected_images}')
          # ✅ ผู้ใช้เลือกเฉพาะรูปที่ต้องการแชร์

        try:
            # ✅ ตรวจสอบว่า PartyHistory มีอยู่จริง
            party_history = PartyHistory.objects.get(party_id=party_id, user_id=user_id)

            # ✅ สร้างโพสต์ใหม่
            post = PartyPost.objects.create(
                user=party_history.user,
                party_history=party_history,
                text=text
            )

            # ✅ ตรวจสอบว่าแต่ละภาพอยู่ใน PartyMemory ของปาร์ตี้นี้หรือไม่
            party_memories = PartyMemory.objects.filter(party_history=party_history, image__in=selected_images)
            if not party_memories.exists():
                return Response({"error": "❌ รูปที่เลือกไม่มีอยู่ใน memory ของปาร์ตี้นี้!"}, status=400)

            # ✅ เพิ่มเฉพาะรูปที่ผู้ใช้เลือกเข้าไปในโพสต์
            for memory in party_memories:
                PartyPostImage.objects.create(post=post, image=memory.image)

            return Response({"message": "✅ แชร์ความทรงจำสำเร็จ!"}, status=200)

        except PartyHistory.DoesNotExist:
            return Response({"error": "❌ ไม่พบปาร์ตี้นี้ หรือคุณไม่มีสิทธิ์แชร์"}, status=403)

        except Exception as e:
            return Response({"error": f"⚠️ เกิดข้อผิดพลาด: {str(e)}"}, status=500)

class ToggleLikePost(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        """ ✅ กดไลค์ หรือเอาไลค์ออก """
        try:
            user = request.user
            post = PartyPost.objects.get(id=post_id)

            # ✅ เช็คว่าผู้ใช้เคยไลค์โพสต์นี้ไหม
            like, created = PartyPostLike.objects.get_or_create(user=user, post=post)

            if created:
                # ✅ ถ้ายังไม่เคยไลค์ -> เพิ่มไลค์
                liked = True
            else:
                # ❌ ถ้าเคยไลค์แล้ว -> เอาไลค์ออก
                like.delete()
                liked = False

            # ✅ นับจำนวนไลค์ใหม่
            likes_count = PartyPostLike.objects.filter(post=post).count()

            return Response({"message": "Success", "liked": liked, "likes_count": likes_count}, status=200)

        except PartyPost.DoesNotExist:
            return Response({"error": "❌ ไม่พบโพสต์นี้"}, status=404)
        except Exception as e:
            return Response({"error": f"⚠️ เกิดข้อผิดพลาด: {str(e)}"}, status=500)

class ShareMemoryForLeaderView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user_id = request.data.get("user_id")
        party_id = request.data.get("party_id")
        text = request.data.get("text", "")
        selected_images = request.data.get("selected_images", [])
        selected_images = [img.replace("/media/", "") for img in selected_images]

        try:
            # ✅ ตรวจสอบว่า user เคยเป็น Leader ของปาร์ตี้นี้หรือไม่
            party_history = PartyHistory.objects.filter(leader=user_id, party_id=party_id).first()
            if not party_history:
                return Response({"error": "❌ คุณไม่ได้เป็น Leader ของปาร์ตี้นี้ หรือปาร์ตี้นี้ไม่มีในประวัติ"}, status=403)

            # ✅ สร้างโพสต์ใหม่
            post = PartyPost.objects.create(
                user=party_history.leader,  # Leader เป็นคนโพสต์
                party_history=party_history,  # เชื่อมโยงกับปาร์ตี้ที่เคยเป็น Leader
                text=text
            )

            # ✅ ตรวจสอบว่าแต่ละภาพอยู่ใน PartyMemory ของปาร์ตี้นี้หรือไม่
            party_memories = PartyMemory.objects.filter(party_history=party_history, image__in=selected_images)
            if not party_memories.exists():
                return Response({"error": "❌ รูปที่เลือกไม่มีอยู่ใน memory ของปาร์ตี้นี้!"}, status=400)

            # ✅ เพิ่มเฉพาะรูปที่ผู้ใช้เลือกเข้าไปในโพสต์
            for memory in party_memories:
                PartyPostImage.objects.create(post=post, image=memory.image)

            return Response({"message": "✅ แชร์ความทรงจำสำหรับ Leader สำเร็จ!"}, status=200)

        except Exception as e:
            return Response({"error": f"⚠️ เกิดข้อผิดพลาด: {str(e)}"}, status=500)
class DeletePostView(APIView):
    """
    API สำหรับลบโพสต์ของผู้ใช้ (เฉพาะเจ้าของโพสต์เท่านั้น)
    """
    permission_classes = [IsAuthenticated]  # ต้องล็อกอินก่อนถึงจะลบโพสต์ได้

    def delete(self, request):
        # ค้นหาโพสต์ ถ้าไม่มีจะคืนค่า 404
        user_id=request.headers.get('userId')
        print(f'useridที่ส่งมา{user_id}')
        user=CustomUser.objects.get(id=user_id)
        post_id=request.data.get('post_id')
        print(f'เลขไอดีของโพส:{post_id}')
        post = get_object_or_404(PartyPost, id=post_id)

        # ตรวจสอบว่าเป็นเจ้าของโพสต์หรือไม่
        if post.user != user:
            return Response({"error": "คุณไม่มีสิทธิ์ลบโพสต์นี้"}, status=status.HTTP_403_FORBIDDEN)

        post.delete()
        return Response({"message": "โพสต์ถูกลบเรียบร้อยแล้ว"}, status=status.HTTP_200_OK)
class FetchUserTopParty(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """ ✅ ดึงปาร์ตี้ของ Leader ที่มี `leader_score` สูงที่สุด """
        
        # ✅ หาผู้ใช้ที่มี leader_score สูงสุด
        top_leader = CustomUser.objects.order_by('-leader_score').first()

        if not top_leader:
            return Response({"message": "ไม่พบผู้ใช้ที่มีคะแนนสูงสุด"}, status=404)

        # ✅ ดึงปาร์ตี้ทั้งหมดที่ top_leader เป็น Leader
        top_parties = Party.objects.filter(leader=top_leader)

        if not top_parties.exists():
            return Response({"message": "Leader ที่มีคะแนนสูงสุดยังไม่ได้สร้างปาร์ตี้"}, status=404)

        serializer = partyserializer(top_parties, many=True)
        return Response({"top_leader": top_leader.username, "parties": serializer.data}, status=200)
        
class SearchPartyView(APIView):
    def get(self, request):
        query = request.GET.get('query', '').strip()
        print(f'ชื่อปาร์ตี้ที่ค้นหา{query}')  # รับค่าค้นหาจาก query parameter
        if not query:
            return Response({"error": "Please provide a search query"}, status=status.HTTP_400_BAD_REQUEST)

        # ค้นหาปาร์ตี้ที่มีชื่อตรงกับ query
        parties = Party.objects.filter(name__icontains=query)
        
        if not parties.exists():
            print('ไม่เจอปาร์ตี้')
            return Response({"message": "No parties found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = partyserializer(parties, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)       


class AdminLoginView(APIView):
    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")

        user = authenticate(username=username, password=password)
        if user and user.is_staff:  # ✅ ตรวจสอบว่าเป็น Admin (`is_staff=True`)
            refresh = RefreshToken.for_user(user)
            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "message": "Login successful"
            }, status=status.HTTP_200_OK)
        return Response({"error": "Invalid credentials or not an admin"}, status=status.HTTP_401_UNAUTHORIZED)
    
class AdminGetAllUser(APIView):
    permission_classes = [IsAuthenticated]  # ✅ ต้องเป็น Admin ที่ล็อกอินถึงเรียกใช้ได้

    def get(self, request):
        if not request.user.is_staff:  # ✅ เช็คว่าเป็น Admin หรือไม่
            return Response({"error": "Permission denied"}, status=status.HTTP_403_FORBIDDEN)

        users = CustomUser.objects.all()  # ✅ ดึง Users ทั้งหมด
        serializer = UserforadminSerializer(users, many=True)  # ✅ ใช้ Serializer แปลงข้อมูล

        return Response(serializer.data, status=status.HTTP_200_OK) 

class AdminEditUser(APIView):
    permission_classes = [IsAuthenticated]  # ต้องเป็นผู้ใช้ที่ล็อกอินแล้ว

    def put(self,request,user_id):
        
        if not user_id:
            return Response({"error": "User ID is required"}, status=status.HTTP_400_BAD_REQUEST)

        # เช็คสิทธิ์ว่าเป็น Admin หรือไม่
        if not request.user.is_staff:
            return Response({"error": "Permission denied"}, status=status.HTTP_403_FORBIDDEN)

        # ดึงข้อมูลผู้ใช้จากฐานข้อมูล
        user = get_object_or_404(CustomUser, id=user_id)

        # ใช้ Serializer เพื่ออัปเดตข้อมูล
        serializer = UserforadminSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "User profile updated successfully", "user": serializer.data}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AdminDeleteUser(APIView):
    permission_classes = [IsAuthenticated]  # ✅ ต้องเป็นผู้ใช้ที่ล็อกอินแล้ว

    def delete(self, request, user_id):
        # ✅ ตรวจสอบว่าเป็น Admin หรือไม่
        if not request.user.is_staff:
            return Response({"error": "Permission denied"}, status=status.HTTP_403_FORBIDDEN)

        # ✅ ตรวจสอบว่ามี user_id อยู่ในระบบหรือไม่
        user = get_object_or_404(CustomUser, id=user_id)

        # ✅ ป้องกันไม่ให้ Admin ลบตัวเอง
        if request.user.id == user.id:
            print('ลบไม่ได้')
            return Response({"error": "Admin cannot delete themselves"}, status=status.HTTP_400_BAD_REQUEST)

        user.delete()
        return Response({"message": "User deleted successfully"}, status=status.HTTP_200_OK)
class AdminUpdateLocation(APIView):
    permission_classes = [IsAuthenticated] 

    def put(self, request, location_id):
     
        if not request.user.is_staff:
            return Response({"error": "Permission denied"}, status=status.HTTP_403_FORBIDDEN)

       
        location = get_object_or_404(ExercisePlace, id=location_id)

       
        serializer = ExercisePlaceSerializer(location, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "✅ อัปเดตข้อมูลสำเร็จ", "data": serializer.data}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
class deletelocation(APIView):
    permission_classes=[IsAuthenticated]

    def delete(self,request,location_id):

        location=ExercisePlace.objects.get(id=location_id)
        location.delete()
        
        return Response({"message":"ลบสำเร็จ"},status=status.HTTP_200_OK)
class AdminCreateLocation(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        print(f'ข้อมูลสถานที่ท่ีจะเพิ่ม{request.data.get}')
        if not request.user.is_staff:
            return Response({"error": "Permission denied"}, status=status.HTTP_403_FORBIDDEN)

        serializer = ExercisePlaceSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save()
            return Response({"message": "✅ เพิ่มสถานที่สำเร็จ", "data": serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
class Addlocationtype(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        เพิ่มประเภทสถานที่ใหม่
        """
        data = {"name": request.data.get("location_name")}  # ✅ จัดรูปแบบข้อมูลให้ถูกต้อง
        serializer = exerciseplacetypeSerializer(data=data)  # ✅ ใช้ data=

        if serializer.is_valid():
            serializer.save()
            return Response({"message": "✅ เพิ่มประเภทสถานที่สำเร็จ", "data": serializer.data}, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)  # ✅ แสดง error ถ้าข้อมูลไม่ถูกต้อง)

class addExercisetype(APIView):
    permission_classes=[IsAuthenticated]
    def post(self,request):
        if not request.user.is_staff:
            return Response({"error": "Permission denied"}, status=status.HTTP_403_FORBIDDEN)

        exercise_name=request.data.get('name')
        description=request.data.get('description')

        data={"name":exercise_name,"description":description}

        exercisetype=exercisetypeSerializer(data=data)
        if exercisetype.is_valid():
            exercisetype.save()
            return Response({"message":"เพิ่มประเภทสำเร็จ"},status.HTTP_201_CREATED)
        else:
            return Response(exercisetype.errors,status.HTTP_400_BAD_REQUEST)
class deleteExcercisetype(APIView):
    permission_classes=[IsAuthenticated]
    def delete(self,reqeust,exercise_typeId):
        if not reqeust.user.is_staff:
            return Response({"error": "Permission denied"}, status=status.HTTP_403_FORBIDDEN)
        exercise_type=ExerciseType.objects.get(id=exercise_typeId)
        exercise_type.delete()
        return Response({'message':'ลบสำเร็จ'},status.HTTP_200_OK)

class adminfecthmember(APIView):
       permission_classes=[IsAuthenticated]
       def post(self, request):
       
        party = request.data.get('partyid') 
        if not party:
            return Response({'error': 'Party ID not provided'}, status=400)
        
        members = PartyMember.objects.filter(party=party)
        join_member = [
            {   
                'id': member.user.id,
                'email':member.user.email,
                'username': member.user.username,
                'profile_image': member.user.profile_image.url if member.user.profile_image else None,
                'memberId':member.id
            } 
            for member in members
        ]
        print(f'ค่าที่ส่งไป: {join_member}')
        return Response(join_member, status=200)

class SystemUpdateView(APIView):
    def get(self, request):
        updates = SystemUpdate.objects.all().order_by("-created_at")
        serializer = SystemUpdateSerializer(updates, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = SystemUpdateSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class DashboardDataView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        total_users = CustomUser.objects.count()
        total_parties = Party.objects.count()
        total_locations = ExercisePlace.objects.count()
        total_pose=PartyPost.objects.count()

        data = {
            "total_users": total_users,
            "total_parties": total_parties,
            "total_locations": total_locations,
            "total_pose": total_pose
        }
        return Response(data, status=200)  

class admindeletepost(APIView):
      permission_classes = [IsAuthenticated]
      def delete(self,reqest,post_id):
          
            target_post=PartyPost.objects.get(id=post_id)
            target_post.delete()
            return Response({'message':"ลบโพสเเล้ว"},status.HTTP_200_OK)

class admindeleteupdate(APIView):

    permission_classes=[IsAuthenticated]
    def delete(self,request,update_id):
        update_target=SystemUpdate.objects.get(id=update_id)
        update_target.delete()
        return Response({"message":"ลบอัพเดตเเล้ว"},status.HTTP_200_OK)
          
class AdminProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user  # ดึงข้อมูลผู้ใช้ที่ล็อกอินอยู่
        if not user.is_staff:  # ตรวจสอบว่าเป็น Admin หรือไม่
            return Response({"error": "Unauthorized"}, status=403)

        serializer = CustomUserSerializer(user)
        return Response(serializer.data, status=200)

class UpdateAdminProfile(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        user = request.user
        data = request.data
        admin=CustomUser.objects.get(id=user)
        admin.username = data.get("username", user.username)
        admin.email = data.get("email", user.email)
        admin.description = data.get("description", user.description)

        if "profile_image" in request.FILES:
             admin.profile_image= request.FILES["profile_image"]

        user.save()
        return Response({"message": "โปรไฟล์ถูกอัปเดตแล้ว"}, status=200)       

class gettallupdate(APIView):

    permission_classes = [IsAuthenticated]

    def get(self,reqesut):

        updates = SystemUpdate.objects.all()
        serializer = SystemUpdateSerializer(updates, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
        
class joinrequestcount(APIView):

    def get(self,request):

        user=request.headers.get("userId")
        joinrequest_count=JoinRequest.objects.filter(reviewed_by=user).count()
        print(joinrequest_count)
        return Response(joinrequest_count,status=200)

class invitationscont(APIView):

    def get(self,request):

        user=request.headers.get("userId")
        invitations=PartyInvitation.objects.filter(receiver=user).count()
        print(invitations)
        return Response(invitations,status=200)        
    

class deletehistoryparty(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        user_id = request.headers.get("userId")
        print(user_id)
        history_id = request.headers.get("albumId")
        print(history_id)
        partyhistory = get_object_or_404(PartyHistory, user=user_id,party_id=history_id)

        partyhistory.delete()
        return Response({"message": "ลบประวัติปาร์ตี้สำเร็จ"}, status=200)
    
class RequestPasswordResetView(APIView):##ไม่เอาคลาสนี้
    def post(self, request):
        email = request.data.get('email')
        try:
            user = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            return Response({'error': 'ไม่พบอีเมลนี้ในระบบ'}, status=status.HTTP_404_NOT_FOUND)

        # ✅ สร้าง Token สำหรับรีเซ็ตรหัสผ่าน
        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))

        reset_link = f"http://127.0.0.1:8000/Smartwityouapp/reset-password/{uid}/{token}"

        # ✅ ส่งอีเมลรีเซ็ตรหัสผ่าน
        send_mail(
            'รีเซ็ตรหัสผ่านของคุณ',
            f'กรุณาคลิกลิงก์นี้เพื่อรีเซ็ตรหัสผ่านของคุณ: {reset_link}',
            'noreply@smartwithyou.com',
            settings.EMAIL_HOST_USER
            [email],
            fail_silently=False,
        )

        return Response({'message': 'ส่งอีเมลรีเซ็ตรหัสผ่านเรียบร้อยแล้ว'}, status=status.HTTP_200_OK)
    
class ResetPasswordView(APIView):##ไม่เอาคลาสนี้
    template_name = "reset_password.html"  # 🔹 ใช้ Template HTML รีเซ็ตรหัสผ่าน

    def get(self, request, uidb64, token):
        """
        ✅ โหลดหน้า HTML สำหรับรีเซ็ตรหัสผ่านเมื่อผู้ใช้กดลิงก์จากอีเมล
        """
        try:
            uid = force_str(urlsafe_base64_encode(uidb64))
            user = CustomUser.objects.get(pk=uid)
        except (CustomUser.DoesNotExist, ValueError, TypeError):
            return JsonResponse({"error": "❌ ลิงก์ไม่ถูกต้องหรือหมดอายุ"}, status=400)

        if not default_token_generator.check_token(user, token):
            return JsonResponse({"error": "❌ Token ไม่ถูกต้องหรือหมดอายุ"}, status=400)

        return render(request, self.template_name)

    def post(self, request, uidb64, token):
        """
        ✅ รับค่ารหัสผ่านใหม่จากฟอร์ม และบันทึกลงฐานข้อมูล
        """
        try:
            uid = force_str(urlsafe_base64_encode(uidb64))
            user = CustomUser.objects.get(pk=uid)
        except (CustomUser.DoesNotExist, ValueError, TypeError):
            return JsonResponse({"error": "❌ ลิงก์ไม่ถูกต้อง"}, status=400)

        if not default_token_generator.check_token(user, token):
            return JsonResponse({"error": "❌ Token ไม่ถูกต้อง"}, status=400)

        new_password = request.POST.get("new_password")
        confirm_password = request.POST.get("confirm_password")

        if new_password != confirm_password:
            return JsonResponse({"error": "❌ รหัสผ่านไม่ตรงกัน"}, status=400)

        user.password = make_password(new_password)
        user.save()
        return JsonResponse({"message": "✅ เปลี่ยนรหัสผ่านสำเร็จ! กรุณาเข้าสู่ระบบใหม่ผ่านแอพ"}, status=200)
    
class RemoveFriendView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, friend_id):
        """
        API สำหรับลบเพื่อนโดยใช้ UUID
        """
        try:
            user = get_object_or_404(CustomUser, id=request.user.id)  # แปลง request.user เป็น Object
            friend = get_object_or_404(CustomUser, id=friend_id)  # แปลง friend_id เป็น Object
            print(f'กำลังลบเพื่อน ID: {friend_id} โดยผู้ใช้: {user.id}')

            # ลบจากมุมมองของ User (user -> friend_user)
            friendship = Friend.objects.filter(user=user, friend_user=friend)
            friendship.delete()

            # ลบจากมุมมองของ Friend (friend_user -> user)
            reverse_friendship = Friend.objects.filter(user=friend, friend_user=user)
            reverse_friendship.delete()

            return Response({"message": "ลบเพื่อนสำเร็จ"}, status=200)

        except Exception as e:
            print(f'เกิดข้อผิดพลาด: {e}')
            return Response({'message': f'เกิดข้อผิดพลาด: {str(e)}'}, status=400)
        

class AdminDeleteParty(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, party_id):
        # ตรวจสอบว่าผู้ใช้เป็น admin หรือไม่ (เปลี่ยนตามระบบ Role ของคุณ)
        if not request.user.is_staff:  # หรือเช็คจาก request.user.role == 'admin'
            return Response({"detail": "ไม่มีสิทธิ์ในการลบปาร์ตี้นี้"}, status=status.HTTP_403_FORBIDDEN)

        # ค้นหา Party ที่จะลบ
        party = get_object_or_404(Party, id=party_id)
        party.delete()

        return Response({"message": "ลบปาร์ตี้สำเร็จแล้ว"}, status=status.HTTP_200_OK)
