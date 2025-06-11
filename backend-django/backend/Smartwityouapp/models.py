from django.db import models
import uuid
from django.contrib.auth.models import BaseUserManager, AbstractBaseUser, PermissionsMixin
from datetime import datetime
from django.utils.timezone import now
class CustomUserManager(BaseUserManager): # type: ignore
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, username, password, **extra_fields)

# โมเดล CustomUser ที่สืบทอดจาก AbstractBaseUser และ PermissionsMixin
class CustomUser(AbstractBaseUser, PermissionsMixin): # type: ignore
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=100, unique=True)
    birth_date = models.DateField(null=True, blank=True)
    password = models.CharField(max_length=128)
    profile_image = models.ImageField(upload_to="profile_images/", null=True, blank=True)
    description = models.CharField(max_length=255, null=True, blank=True)
    gender=models.CharField(choices=[('man','Man'),('women','Women')],max_length=20)
    email_verified = models.BooleanField(default=False)
    leader_score = models.FloatField(default=0.0)
    
    
    # กำหนดให้ใช้ 'email' แทน 'username' สำหรับการยืนยันตัวตน
    USERNAME_FIELD = 'email'
    
    # ฟิลด์ที่จำเป็นเมื่อสร้างบัญชีใหม่
    REQUIRED_FIELDS = ['username']

    is_active = models.BooleanField(default=True)  # ฟิลด์ที่บ่งชี้ว่าใช้งานได้หรือไม่
    is_staff = models.BooleanField(default=False)  # ฟิลด์ที่บ่งชี้ว่าเป็นแอดมินหรือไม่

    objects = CustomUserManager()
    def __str__(self):
        return self.email


class ExerciseType(models.Model):
    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=50)
    description = models.TextField()
    nummerber =models.IntegerField(default=0)
def update_opening_status():
    current_time = now().time()
    current_day = now().strftime('%a').upper()  # เช่น 'MON', 'TUE'
    
    opening_hours = OpeningHours.objects.all()
    for hour in opening_hours:
        if hour.day_of_week == 'Everyday' or hour.day_of_week == current_day:
            if hour.open_time and hour.close_time:
                if hour.open_time <= current_time <= hour.close_time:
                    hour.status = 'Open'
                else:
                    hour.status = 'Closed'
            else:
                hour.status = 'Always Open'
            hour.save()
class OpeningHours(models.Model):
    id = models.AutoField(primary_key=True)
    exercise_place = models.ForeignKey(
        'ExercisePlace', 
        on_delete=models.CASCADE, 
        related_name='opening_hours'
    )  # เชื่อมกับ ExercisePlace
    day_of_week = models.CharField(
        max_length=10, 
        choices=[
            ('Sunday', 'อาทิตย์'), 
            ('Monday', 'จันทร์'), 
            ('Tuesday', 'อังคาร'), 
            ('wednesday', 'พุทธ'), 
            ('Thursday', 'พฤหัส'), 
            ('Friday', 'ศุกร์'), 
            ('Saturday', 'เสาร์'),
            ('Everyday', 'ทุกวัน')
        ]
    )  # วันในสัปดาห์
    open_time = models.TimeField(null=True, blank=True)  # เวลาที่เปิด
    close_time = models.TimeField(null=True, blank=True)  # เวลาที่ปิด
    status = models.CharField(
        max_length=10, 
        choices=[
            ('Open', 'Open'), 
            ('Closed', 'Closed')
        ], 
        default='Open'
    )  # สถานะเปิดหรือปิด

    def __str__(self):
        return f"{self.day_of_week}: {self.open_time} - {self.close_time} ({self.status})"
class ExercisePlace(models.Model):
    id = models.AutoField(primary_key=True)
    location_name = models.CharField(max_length=100)  # ชื่อสถานที่
    city = models.CharField(max_length=100)  # เมือง
    province = models.CharField(max_length=100)  # จังหวัด
    address = models.TextField()  # ที่อยู่
    latitude = models.DecimalField(max_digits=20, decimal_places=15)
    longitude = models.DecimalField(max_digits=20, decimal_places=15)  # ลองจิจูด  # ลองจิจูด
    description = models.TextField()  # รายละเอียด
    exercise_type = models.ForeignKey(
        'Exerciseplacetype', 
        on_delete=models.CASCADE
    )  # ประเภทสถานที่ออกกำลังกาย
    place_image = models.ImageField(
        upload_to="exercise_places/", 
        null=True, 
        blank=True
    )  # รูปภาพสถานที่
    def __str__(self):
        return self.location_name
class Exerciseplacetype(models.Model):
    id=models.AutoField(primary_key=True)
    name=models.CharField(max_length=100)


class ExerciseTime(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    available_time_start = models.TimeField()
    available_time_end = models.TimeField()
    available_day = models.CharField(
        max_length=10, choices=[("SUN", "Sunday"), ("MON", "Monday"), ("TUE", "Tuesday"), 
                                ("WED", "Wednesday"), ("THU", "Thursday"), ("FRI", "Friday"), ("SAT", "Saturday")])


class Party(models.Model):
    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=100)
    exercise_type = models.ForeignKey(ExerciseType, on_delete=models.CASCADE)
    description = models.TextField()
    location = models.ForeignKey(ExercisePlace, on_delete=models.CASCADE)
    date = models.DateField()
    start_time = models.TimeField()
    finish_time = models.TimeField()
    timestamp = models.DateTimeField(auto_now_add=True)
    leader = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    google_event_id = models.CharField(max_length=255, blank=True, null=True) 
    STATUS_CHOICES = [
        ("waiting","รอการดำเนินการ"),
        ("ongoing", "กำลังดำเนินการ"),
        ("completed", "จบแล้ว"),
        ("archived", "เก็บถาวร"),
    ]
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default="waiting")
    
   

class PartyMember(models.Model):
    id = models.AutoField(primary_key=True)
    party = models.ForeignKey(Party, on_delete=models.CASCADE)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    join_date = models.DateTimeField(auto_now_add=True)
    has_liked = models.BooleanField(default=False)  
    has_reviewed = models.BooleanField(default=False)
    checkin_status = models.BooleanField(default=False)
    checkin_time = models.DateTimeField(null=True, blank=True)  
    finish_workout=models.BooleanField(default=False)
    class Meta:
        unique_together = ('user', 'party')

class PartyInvitation(models.Model):
    party = models.ForeignKey(Party, on_delete=models.CASCADE)
    sender = models.ForeignKey(CustomUser, related_name="sent_invitations", on_delete=models.CASCADE)
    receiver = models.ForeignKey(CustomUser, related_name="received_invitations", on_delete=models.CASCADE)
    send_date = models.DateField()
    send_time = models.TimeField()
    status = models.CharField(
        max_length=10, choices=[("pending", "Pending"), ("accepted", "Accepted"), ("rejected", "Rejected")])


class Friend(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(CustomUser, related_name="friends", on_delete=models.CASCADE)
    friend_user = models.ForeignKey(CustomUser, related_name="friend_of", on_delete=models.CASCADE)
    status = models.BooleanField(default=False)  # True for online, False for offline
    class Meta:
     unique_together = ("user", "friend_user")

class FriendRequest(models.Model):
    sender = models.ForeignKey(CustomUser, related_name="sent_friend_requests", on_delete=models.CASCADE)
    receiver = models.ForeignKey(CustomUser, related_name="received_friend_requests", on_delete=models.CASCADE)
    send_date = models.DateField()
    send_time = models.TimeField()
    status = models.CharField(
        max_length=10, choices=[("pending", "Pending"), ("accepted", "Accepted"), ("rejected", "Rejected")])


class JoinRequest(models.Model):
    party = models.ForeignKey(Party, on_delete=models.CASCADE)
    sender = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    send_date = models.DateField()
    send_time = models.TimeField()
    status = models.CharField(
        max_length=10, choices=[("pending", "Pending"), ("accepted", "Accepted"), ("rejected", "Rejected")])
    reviewed_by = models.ForeignKey(
        CustomUser, null=True, blank=True, on_delete=models.SET_NULL, related_name="reviewed_requests"
    ) 
    review_date = models.DateTimeField(null=True, blank=True)

class Notifications(models.Model):
    reciever=models.ForeignKey(CustomUser,related_name="receive_notifications",on_delete=models.CASCADE)
    sender_time=models.DateTimeField(auto_now_add=True)
    title=models.CharField(max_length=50)
    message=models.TextField(max_length=500)
    read_status = models.SmallIntegerField(choices=[(0, 'Unread'), (1, 'Read')], default=0)
class UserFCMToken(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    fcm_token = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)
class UserExerciseType(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='exercise_times')
    exercise_type = models.ForeignKey(ExerciseType, on_delete=models.SET_NULL, null=True, blank=True, related_name='exercise_times')  # ประเภทการออกกำลังกาย

    def __str__(self):
        return f"{self.user.username} - {self.exercise_type.name if self.exercise_type else 'No Type'}"
class BackgroundProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name="backgroudprofile")
    background_image = models.ImageField(upload_to='background_images/', null=True, blank=True)
class PartyMemberEvent(models.Model):
    id = models.AutoField(primary_key=True)
    member = models.ForeignKey(PartyMember, on_delete=models.CASCADE)  # 🔹 เชื่อมกับ PartyMember
    google_event_id = models.CharField(max_length=255, null=True, blank=True)  # 🔹 ID อีเวนต์ของสมาชิกแต่ละคน
    created_at = models.DateTimeField(auto_now_add=True)
class PartyPhoto(models.Model):
    party = models.ForeignKey(Party, on_delete=models.CASCADE, related_name="photos")
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)  # ผู้ที่อัปโหลดรูป
    image = models.ImageField(upload_to="party_photos/")  # เก็บไฟล์รูป
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.party.name} - {self.user.username}"

class PartyHistory(models.Model):
    user = models.ForeignKey("CustomUser", on_delete=models.CASCADE)
    party_id = models.IntegerField(null=True, blank=True)
    leader = models.ForeignKey("CustomUser", on_delete=models.CASCADE, related_name="led_parties", null=True, blank=True)
    leader_name = models.CharField(max_length=255,null=True, blank=True)  
    party_name = models.CharField(max_length=255, null=True, blank=True)
    date = models.DateField()  
    completed_at = models.DateTimeField(default=now)  
    party_rating = models.FloatField(null=True, blank=True)  
    leader_rating = models.FloatField(null=True, blank=True)  

    def __str__(self):
        return f"{self.party_name} - {self.user.username}"
class LeaderVote(models.Model):
    leader = models.ForeignKey("CustomUser", on_delete=models.CASCADE)  # ✅ Leader ที่ได้รับโหวต
    voter = models.ForeignKey("CustomUser", on_delete=models.CASCADE, related_name="leader_votes")  # ✅ คนโหวต
    party_history = models.ForeignKey(PartyHistory, on_delete=models.CASCADE)  # ✅ เชื่อมกับประวัติปาร์ตี้
    rating = models.IntegerField(default=0)  # ⭐ คะแนนโหวต (1-5)
    review_text = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(default=now)

    class Meta:
        unique_together = ("party_history", "voter")
class PartyMemory(models.Model):
    party_history = models.ForeignKey(PartyHistory, on_delete=models.CASCADE, related_name="photos")  # ✅ เก็บประวัติปาร์ตี้แทน
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)  # ✅ ผู้ที่อัปโหลดรูป
    image = models.ImageField(upload_to="party_photos/")  # ✅ เก็บไฟล์รูป
    uploaded_at = models.DateTimeField(auto_now_add=True)  # ✅ วันที่อัปโหลด

    def __str__(self):
        return f"{self.party_history.party_name} - {self.user.username}"
class PartyPost(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)  # ผู้โพสต์
    party_history = models.ForeignKey('PartyHistory', on_delete=models.CASCADE)  # เชื่อมกับปาร์ตี้ที่เข้าร่วม
    text = models.TextField(blank=True, null=True)  # ข้อความโพสต์
    created_at = models.DateTimeField(auto_now_add=True)  # เวลาที่โพสต์
      # ระบบกดไลก์

    def __str__(self):
        return f"{self.user.username} - {self.party_history.party_name}"

   
class PartyPostImage(models.Model):
    post = models.ForeignKey(PartyPost, on_delete=models.CASCADE, related_name="images")  # รูปภาพที่แนบมากับโพสต์
    image = models.ImageField(upload_to="post_images/")

    def __str__(self):
        return f"Image for {self.post.id}"
class PartyComment(models.Model):
    post = models.ForeignKey(PartyPost, on_delete=models.CASCADE, related_name="comments")  # คอมเมนต์ของโพสต์
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Comment by {self.user.username} on {self.post.id}"
class PartyPostLike(models.Model):
    post = models.ForeignKey(PartyPost, on_delete=models.CASCADE)  # ✅ ลบโพสต์ -> ลบไลค์อัตโนมัติ
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)

class SystemUpdate(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    image = models.ImageField(upload_to="updates/", null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)