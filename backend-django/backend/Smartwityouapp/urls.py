from django.contrib import admin
from django.urls import path
from .views import *

urlpatterns = [
    path("Register/",Register().as_view(),name="register-page"),
    path("verifyemail/<str:user_id>/",verification().as_view(),name="verify email"),
    path('check_verify/', VerifyEmailStatus().as_view(),name="Check-verify"),
    path('Login/',Login().as_view(),name='login-page'),
     path('logout/', LogoutView.as_view(), name='logout'),
]