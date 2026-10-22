from rest_framework import generics
from rest_framework.permissions import BasePermission, SAFE_METHODS

from .models import Classroom
from .serializers import ClassroomSerializer


class ClassroomPermission(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True

        user = request.user
        if not user or not user.is_authenticated:
            return False

        if user.is_staff or user.is_superuser:
            return True

        try:
            return user.profile.role in ("TRAINER", "ADMIN")
        except (AttributeError, user.__class__.DoesNotExist):
            return False

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True

        user = request.user
        return (
            user.is_staff
            or user.is_superuser
            or (
                getattr(getattr(user, "profile", None), "role", None)
                in ("TRAINER", "ADMIN")
                and (user.profile.role == "ADMIN" or obj.trainer_id == user.id)
            )
        )


class ClassroomListCreateView(generics.ListCreateAPIView):
    queryset = Classroom.objects.filter(is_active=True).order_by("scheduled_at")
    serializer_class = ClassroomSerializer
    permission_classes = [ClassroomPermission]

    def perform_create(self, serializer):
        user = self.request.user
        if user.is_staff or user.is_superuser:
            serializer.save()
        elif user.profile.role == "ADMIN":
            serializer.save()
        else:
            serializer.save(trainer=user)


class ClassroomDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Classroom.objects.all()
    serializer_class = ClassroomSerializer
    permission_classes = [ClassroomPermission]
