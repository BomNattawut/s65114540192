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

        print(user.email)
        send_mail(subject, message, from_email, recipient_list, fail_silently=False)

class exercisetypeSerializer(serializers.ModelSerializer):
     class Meta:
          model=ExerciseType
          fields=['id','name','description','nummerber']

class OpeningHoursSerializer(serializers.ModelSerializer):
    class Meta:
        model = OpeningHours
        fields = ['day_of_week', 'open_time', 'close_time', 'status']

class ExercisePlaceSerializer(serializers.ModelSerializer):
    opening_hours = OpeningHoursSerializer(many=True, read_only=True)  # ดึงข้อมูล OpeningHours

    class Meta:
        model = ExercisePlace
        fields = [
            'id', 
            'location_name', 
            'city', 
            'province', 
            'address', 
            'latitude', 
            'longitude', 
            'description', 
            'exercise_type', 
            'place_image', 
            'opening_hours'  # เพิ่มข้อมูล OpeningHours
        ]
class exerciseplacetypeSerializer(serializers.ModelSerializer):
     class Meta:
          model=Exerciseplacetype
          fields=[ 'id','name']
class partyserializer(serializers.ModelSerializer):
        ##location = serializers.SerializerMethodField() 
        ##location=ExercisePlaceSerializer()#เพิ่มตรงนี้
        location = serializers.PrimaryKeyRelatedField(queryset=ExercisePlace.objects.all())
        class Meta:
            model=Party
            fields=['id','name','exercise_type','location','description','date','start_time','finish_time','leader','google_event_id','status']
        def create(self, validated_data):
              party = Party.objects.create(**validated_data)
              return party
        def to_representation(self, instance):
        # ใช้ Nested Serializer สำหรับการแสดงผล (GET)
            representation = super().to_representation(instance)
            representation['location'] = ExercisePlaceSerializer(instance.location).data
            representation['exercise_type'] = exerciseplacetypeSerializer(instance.exercise_type).data
        
            return representation

        '''
        def get_location(self, obj):
            if obj.location:
                return {
                    'id': obj.location.id,
                    'location_name': obj.location.location_name,
                    'city': obj.location.city,
                    'province': obj.location.province,
                    'address': obj.location.address,
                    'latitude': obj.location.latitude,
                    'longitude': obj.location.longitude,
                    'description': obj.location.description,
                }
            return None
            '''
class PartyInvitationserializer(serializers.ModelSerializer):
     sender_username=serializers.CharField(source='sender.username',read_only=True)
     sender_user_profile=serializers.ImageField(source='sender.profile_image',read_only=True)
     party_detail=serializers.SerializerMethodField()
     class Meta:
          model=PartyInvitation
          fields=['id','party','sender','receiver','send_date','send_time','status','sender_username','sender_user_profile','party_detail']
     def create(self, validated_data):
         invitation=PartyInvitation.objects.create(**validated_data)
         return invitation 
     def get_party_detail(self,obj):
          party=obj.party
          if party:
               party_serializer=partyserializer(party)
               return party_serializer.data
          return None
          
class JoinRequestserializer(serializers.ModelSerializer):
     sender_username=serializers.CharField(source='sender.username',read_only=True)
     sender_user_profile=serializers.ImageField(source='sender.profile_image',read_only=True)
     party_name=serializers.CharField(source='party.name',read_only=True)
     location = serializers.SerializerMethodField()
     
     class Meta:
          model=JoinRequest
          fields=['id','party','sender','send_date','send_time','status','reviewed_by','review_date','sender_username','sender_user_profile','party_name','location']
     def create(self, validated_data):
          joinrequest=JoinRequest.objects.create(**validated_data)
          return joinrequest
     def get_location(self, obj):
        location = obj.party.location  # เข้าถึง object Location ที่เกี่ยวข้อง
        if location:  # ตรวจสอบว่ามี location หรือไม่ (อาจเป็น null ได้)
            location_serializer = ExercisePlaceSerializer(location)
            return location_serializer.data
        return None
class Friendserializer(serializers.ModelSerializer):
     friend_username = serializers.CharField(source='friend_user.username',read_only=True)
     frined_profile=serializers.ImageField(source='friend_user.profile_image',read_only=True)
     class Meta:
          model=Friend
          fields=['id','friend_user','user','status','friend_username','frined_profile']
     def create(self, validated_data):
          friend=Friend.objects.create(**validated_data)
          return friend
     
class Memberserializer(serializers.ModelSerializer):
     class Meta:
          model=PartyMember
          fields=['party','user','join_date']
     def create(self, validated_data):
          return PartyMember.objects.create(**validated_data)
class Friendrequestserializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender.username', read_only=True)
    sender_profile_image = serializers.ImageField(source='sender.profile_image', read_only=True)
    receiver_username = serializers.CharField(source='receiver.username', read_only=True)
    receiver_profile_image = serializers.ImageField(source='receiver.profile_image', read_only=True)

    class Meta:
          model=FriendRequest
          fields = ['id', 'sender', 'receiver', 'sender_username', 'sender_profile_image', 
                  'receiver_username', 'receiver_profile_image', 'status', 'send_date', 'send_time']
    def create(self, validated_data):
          return FriendRequest.objects.create(**validated_data)
class Backgroundprofile(serializers.ModelSerializer):
    class Meta:
          model=BackgroundProfile
          fields = ['user','background_image']
    def create(self, validated_data):
          return BackgroundProfile.objects.create(**validated_data)
class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = [
            'id', 'email', 'username', 'birth_date',
            'profile_image', 'description', 'gender', 'email_verified'
        ]
class PartymemberEventserializer(serializers.ModelSerializer):
     class Meta:
          model=PartyMemberEvent
          fields=['id','member','google_event_id','created_at']
     def create(self, validated_data):
          return PartyMemberEvent.objects.create(**validated_data)
class PartyhistorySerializer(serializers.ModelSerializer):
     class Meta:
          model=PartyHistory
          fields=['user','leader_name','party_name','date','completed_at','party_rating','leader_rating',]
     def create(self, validated_data):
          return PartyHistory.objects.create(**validated_data)
class PartyMemorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PartyMemory
        fields = ['id', 'user', 'party_history', 'image', 'uploaded_at']
class PartyPostSerializer(serializers.ModelSerializer):
     class Meta:
          model=PartyPost
          fields=['id','user','party_history','text','created_at']
class CommentSerializer(serializers.ModelSerializer):
    user = serializers.CharField(source='user.username')  # ✅ ส่งชื่อผู้ใช้แทน ID

    class Meta:
        model = PartyComment
        fields = ['user','post','text', 'created_at']
class PartyPostLikeSerializer(serializers.ModelSerializer):
     
     class Meta:
          model=PartyPostLike
          fields=['post','user']

class UserforadminSerializer(serializers.ModelSerializer):
     class Meta:
          model=CustomUser
          fields = [
            'id', 'email', 'username', 'birth_date',
            'profile_image', 'description', 'gender', 'email_verified','is_staff'
        ]
          
class SystemUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemUpdate
        fields = "__all__"