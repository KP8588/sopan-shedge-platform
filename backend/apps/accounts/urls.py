from django.urls import path

from apps.accounts.views import (
    LoginView,
    LogoutView,
    MeView,
    RegisterView,
    TrainerListView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("me/", MeView.as_view(), name="me"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("users/", TrainerListView.as_view(), name="users"),
]