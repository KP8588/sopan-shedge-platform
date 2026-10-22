
from django.urls import path

from apps.accounts.views import (
    LoginView,
    LogoutView,
    MeView,
    RegisterView,
    TrainerCreateView,
    TrainerListView,
    StudentListView,
    StudentStatusUpdateView,
StudentListView,
StudentStatusUpdateView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("me/", MeView.as_view(), name="me"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("users/", TrainerListView.as_view(), name="users"),
    path("trainers/create/", TrainerCreateView.as_view(), name="trainer-create"),
    path("students/", StudentListView.as_view(), name="student-list"),
    path(
        "students/<int:pk>/",
        StudentStatusUpdateView.as_view(),
        name="student-status-update",
    ),

]
