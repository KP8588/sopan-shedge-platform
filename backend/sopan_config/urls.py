from apps.classrooms.livekit_views import livekit_token
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path
from django.urls import include, path

def health_check(request):
    return JsonResponse({
        "success": True,
        "message": "Sopan Shedge Platform API is running",
        "service": "backend",
        "version": "0.1.0",
    })


urlpatterns = [
    path('api/classrooms/<int:classroom_id>/livekit-token/', livekit_token, name='classroom-livekit-token'),
    path("api/classrooms/", include("apps.classrooms.urls")),
    path("admin/", admin.site.urls),
    path("api/health/", health_check, name="health-check"),
    path("api/auth/", include("apps.accounts.urls")),
path("api/courses/", include("apps.courses.urls")),
]

