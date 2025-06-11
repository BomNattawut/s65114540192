from django.contrib import admin
from .models import *

@admin.register(CustomUser)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ('email', 'username', 'is_active', 'is_staff')
    search_fields = ('email', 'username')
    list_filter = ('is_active', 'is_staff')
@admin.register(Exerciseplacetype)
class ExercisepalcetypeAdmin(admin.ModelAdmin):
    list_display=('id','name')
    search_fields=('name','id')
@admin.register(ExerciseType)
class ExerciseTypeAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    search_fields = ('name',)
@admin.register(OpeningHours)
class OpeningHoursAdmin(admin.ModelAdmin):
    list_display = ('exercise_place', 'day_of_week', 'open_time', 'close_time', 'status')
    search_fields = ('exercise_place__location_name', 'day_of_week')  # ค้นหาตามสถานที่หรือวันในสัปดาห์
    list_filter = ('day_of_week', 'status')
@admin.register(ExercisePlace)
class ExercisePlaceAdmin(admin.ModelAdmin):
    list_display = ('location_name', 'city', 'province', 'exercise_type', 'get_opening_hours')
    search_fields = ('location_name', 'city', 'province')
    list_filter = ('exercise_type',)

    def get_opening_hours(self, obj):
        # ดึงข้อมูลจากโมเดล OpeningHours ที่เกี่ยวข้องกับ ExercisePlace
        opening_hours = obj.opening_hours.all()
        hours_display = ", ".join([f"{o.day_of_week}: {o.open_time} - {o.close_time} ({o.status})" for o in opening_hours])
        return hours_display or "No hours set"
    get_opening_hours.short_description = 'Opening Hours'
@admin.register(Party)
class PartyAdmin(admin.ModelAdmin):
    list_display = ('name', 'exercise_type', 'date', 'location', 'leader')
    search_fields = ('name', 'exercise_type__name', 'leader__email')
    list_filter = ('exercise_type', 'date')

@admin.register(PartyMember)
class PartyMemberAdmin(admin.ModelAdmin):
    list_display = ('party', 'user', 'join_date')
    search_fields = ('party__name', 'user__email')

@admin.register(PartyInvitation)
class PartyInvitationAdmin(admin.ModelAdmin):
    list_display = ('party', 'sender', 'receiver', 'status')
    list_filter = ('status',)
    search_fields = ('party__name', 'sender__email', 'receiver__email')

@admin.register(Friend)
class FriendAdmin(admin.ModelAdmin):
    list_display = ('user', 'friend_user', 'status')
    search_fields = ('user__email', 'friend_user__email')

@admin.register(FriendRequest)
class FriendRequestAdmin(admin.ModelAdmin):
    list_display = ('sender', 'receiver', 'status', 'send_date')
    list_filter = ('status',)
    search_fields = ('sender__email', 'receiver__email')

@admin.register(JoinRequest)
class JoinRequestAdmin(admin.ModelAdmin):
    list_display = ('party', 'sender', 'status', 'reviewed_by', 'review_date')
    list_filter = ('status',)
    search_fields = ('party__name', 'sender__email', 'reviewed_by__email')

@admin.register(Notifications)
class NotificationsAdmin(admin.ModelAdmin):
    list_display = ('reciever', 'title', 'read_status', 'sender_time')
    list_filter = ('read_status',)
    search_fields = ('reciever__email', 'title')
# Register your models here.
@admin.register(ExerciseTime)
class ExerciseTimeAdmin(admin.ModelAdmin):
    list_display = ('user', 'available_time_start', 'available_time_end', 'available_day')
    search_fields = ('user__username', 'available_day')  # ใช้ user__username สำหรับการค้นหา
    list_filter = ('available_day',)

@admin.register(UserExerciseType)
class UserExerciseTypeAdmin(admin.ModelAdmin):
    list_display = ('user', 'exercise_type')  # แสดง user และ exercise_type ในตาราง
    search_fields = ('user__username', 'exercise_type__name')  # ใช้ user__username และ exercise_type__name
    list_filter = ('exercise_type',)
@admin.register(BackgroundProfile)
class BackgroundProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'background_image')  # แสดงคอลัมน์ใน Admin Panel
    list_filter = ['user']  # ✅ ต้องเป็น list หรือ tuple
    search_fields = ['user__username']  # ✅ ค้นหาผ่าน username
