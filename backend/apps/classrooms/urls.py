
from django.urls import path

from .views import (
    ClassroomListCreateView,
    ClassroomDetailView,
    ClassroomManagementListView,
    ClassroomManagementDetailView,
)

urlpatterns = [
    path("", ClassroomListCreateView.as_view(), name="classroom-list-create"),
    path("manage/", ClassroomManagementListView.as_view(), name="classroom-management-list"),
    path(
        "<int:pk>/manage/",
        ClassroomManagementDetailView.as_view(),
        name="classroom-management-detail",
    ),
    path("<int:pk>/", ClassroomDetailView.as_view(), name="classroom-detail"),
]
