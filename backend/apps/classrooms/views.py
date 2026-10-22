
from rest_framework import generics, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import (
    BasePermission,
    SAFE_METHODS,
    IsAuthenticated,
)
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Classroom
from .serializers import ClassroomSerializer


def require_admin(user):
    profile = getattr(user, "profile", None)

    if not user.is_staff and (
        profile is None or profile.role != "ADMIN"
    ):
        raise PermissionDenied(
            "Only administrators can perform this action."
        )


class ClassroomPermission(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True

        user = request.user

        if not user or not user.is_authenticated:
            return False

        if user.is_staff or user.is_superuser:
            return True

        profile = getattr(user, "profile", None)
        return (
            profile is not None
            and profile.role in ("TRAINER", "ADMIN")
        )

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True

        user = request.user

        if user.is_staff or user.is_superuser:
            return True

        profile = getattr(user, "profile", None)

        return (
            profile is not None
            and (
                profile.role == "ADMIN"
                or (
                    profile.role == "TRAINER"
                    and obj.trainer_id == user.id
                )
            )
        )


class ClassroomListCreateView(generics.ListCreateAPIView):
    queryset = Classroom.objects.filter(
        is_active=True
    ).order_by("scheduled_at")
    serializer_class = ClassroomSerializer
    permission_classes = [ClassroomPermission]

    def perform_create(self, serializer):
        user = self.request.user
        profile = getattr(user, "profile", None)

        if user.is_staff or user.is_superuser:
            serializer.save()
        elif profile and profile.role == "ADMIN":
            serializer.save()
        else:
            serializer.save(trainer=user)


class ClassroomDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Classroom.objects.all()
    serializer_class = ClassroomSerializer
    permission_classes = [ClassroomPermission]


class ClassroomManagementListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        require_admin(request.user)

        classrooms = Classroom.objects.select_related(
            "course", "trainer"
        ).order_by("scheduled_at")

        serializer = ClassroomSerializer(classrooms, many=True)
        return Response(serializer.data)

    def post(self, request):
        require_admin(request.user)

        serializer = ClassroomSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        classroom = serializer.save()

        return Response(
            {
                "success": True,
                "message": "Classroom created successfully.",
                "classroom": ClassroomSerializer(classroom).data,
            },
            status=status.HTTP_201_CREATED,
        )


class ClassroomManagementDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        require_admin(request.user)

        try:
            classroom = Classroom.objects.get(pk=pk)
        except Classroom.DoesNotExist:
            return Response(
                {"detail": "Classroom not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = ClassroomSerializer(
            classroom,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        classroom = serializer.save()

        return Response(
            {
                "success": True,
                "message": "Classroom updated successfully.",
                "classroom": ClassroomSerializer(classroom).data,
            }
        )
