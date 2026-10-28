from django.urls import re_path

from .consumers import ClassroomSignalingConsumer

websocket_urlpatterns = [
    re_path(
        r"^ws/classrooms/(?P<class_id>[0-9]+)/$",
        ClassroomSignalingConsumer.as_asgi(),
    ),
]
