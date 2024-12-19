from django.db import models
import uuid
from django.contrib.auth.models import BaseUserManager, AbstractBaseUser, PermissionsMixin

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


class ExercisePlace(models.Model):
    id = models.AutoField(primary_key=True)
    location_name = models.CharField(max_length=100)
    city = models.CharField(max_length=100)
    province = models.CharField(max_length=100)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    open_time = models.TimeField()
    close_time = models.TimeField()
    opening_day = models.CharField(
        max_length=10, choices=[("SUN", "Sunday"), ("MON", "Monday"), ("TUE", "Tuesday"), 
                                ("WED", "Wednesday"), ("THU", "Thursday"), ("FRI", "Friday"), ("SAT", "Saturday")])
    description = models.TextField()
    exercise_type = models.ForeignKey(ExerciseType, on_delete=models.CASCADE)


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


class PartyMember(models.Model):
    id = models.AutoField(primary_key=True)
    party = models.ForeignKey(Party, on_delete=models.CASCADE)
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    join_date = models.DateTimeField(auto_now_add=True)


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