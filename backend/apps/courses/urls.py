
from django.urls import path

from .views import (
    CourseCreateView,
    CourseDetailView,
    CourseListView,
    CourseManagementListView,
    CourseUpdateView,
    RecordedLectureListView,
    RecordedLectureDetailView,
    LectureProgressListView,
    LectureProgressUpdateView,
)

urlpatterns = [
    path("", CourseListView.as_view(), name="course-list"),

    path("create/", CourseCreateView.as_view(), name="course-create"),
    path("manage/", CourseManagementListView.as_view(), name="course-manage-list"),
    path("<int:pk>/manage/", CourseUpdateView.as_view(), name="course-update"),

    path("lectures/", RecordedLectureListView.as_view(), name="lecture-list"),
    path("lectures/<int:pk>/", RecordedLectureDetailView.as_view(), name="lecture-detail"),

    path("lecture-progress/", LectureProgressListView.as_view(), name="lecture-progress-list"),
    path(
        "lectures/<int:lecture_id>/progress/",
        LectureProgressUpdateView.as_view(),
        name="lecture-progress-update",
    ),

    path("<int:pk>/", CourseDetailView.as_view(), name="course-detail"),
]
