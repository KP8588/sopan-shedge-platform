
from django.urls import path

from .views import (
    CourseCreateView,
    CourseDetailView,
    CourseListView,
    CourseManagementListView,
    CourseUpdateView,
)

urlpatterns = [
    path("", CourseListView.as_view(), name="course-list"),
    path("create/", CourseCreateView.as_view(), name="course-create"),
    path("manage/", CourseManagementListView.as_view(), name="course-manage-list"),
    path("<int:pk>/manage/", CourseUpdateView.as_view(), name="course-update"),
    path("<int:pk>/", CourseDetailView.as_view(), name="course-detail"),
]
