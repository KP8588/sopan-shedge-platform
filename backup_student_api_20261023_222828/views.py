from django.contrib.auth import authenticate, get_user_model
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.serializers import (
    RegisterSerializer,
    CreateTrainerSerializer,
    UserProfileSerializer,
)

User = get_user_model()


def require_admin(user):
    profile = getattr(user, "profile", None)

    if not user.is_staff and (
        profile is None or profile.role != "ADMIN"
    ):
        raise PermissionDenied(
            "Only administrators can perform this action."
        )


class RegisterView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)

        return Response(
            {
                "success": True,
                "message": "Registration successful.",
                "token": token.key,
                "user": UserProfileSerializer(user).data,
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        username = request.data.get("username", "")
        password = request.data.get("password", "")

        if not isinstance(username, str) or not isinstance(password, str):
            return Response(
                {"success": False, "message": "Invalid credentials."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = authenticate(
            request,
            username=username,
            password=password,
        )

        if user is None or not user.is_active:
            return Response(
                {"success": False, "message": "Invalid credentials."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        token, _ = Token.objects.get_or_create(user=user)

        return Response(
            {
                "success": True,
                "token": token.key,
                "user": UserProfileSerializer(user).data,
            }
        )


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(
            {
                "success": True,
                "user": UserProfileSerializer(request.user).data,
            }
        )


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.auth.delete()

        return Response(
            {"success": True, "message": "Logged out successfully."}
        )


class TrainerListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        require_admin(request.user)

        trainers = User.objects.filter(
            is_active=True,
            profile__role="TRAINER",
        ).order_by("username")

        return Response(
            UserProfileSerializer(trainers, many=True).data
        )


class TrainerCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        require_admin(request.user)

        serializer = CreateTrainerSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        trainer = serializer.save()

        return Response(
            {
                "success": True,
                "message": "Trainer created successfully.",
                "trainer": UserProfileSerializer(trainer).data,
            },
            status=status.HTTP_201_CREATED,
        )


class StudentListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        require_admin(request.user)

        students = User.objects.filter(
            profile__role="STUDENT"
        ).order_by("username")

        return Response(
            UserProfileSerializer(students, many=True).data
        )


class StudentStatusUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        require_admin(request.user)

        try:
            student = User.objects.get(
                pk=pk,
                profile__role="STUDENT",
            )
        except User.DoesNotExist:
            return Response(
                {"detail": "Student not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        is_active = request.data.get("is_active")

        if not isinstance(is_active, bool):
            return Response(
                {"is_active": "A boolean value is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        student.is_active = is_active
        student.save(update_fields=["is_active"])

        return Response({
            "success": True,
            "message": (
                "Student activated successfully."
                if is_active
                else "Student deactivated successfully."
            ),
            "student": UserProfileSerializer(student).data,
            "is_active": student.is_active,
        })



class StudentListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        require_admin(request.user)

        students = User.objects.filter(
            is_active__in=[True, False],
            profile__role="STUDENT",
        ).order_by("username")

        return Response(
            UserProfileSerializer(students, many=True).data
        )


class StudentStatusUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        require_admin(request.user)

        if not isinstance(request.data.get("is_active"), bool):
            return Response(
                {"detail": "is_active must be true or false."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            student = User.objects.get(
                pk=pk,
                profile__role="STUDENT",
            )
        except User.DoesNotExist:
            return Response(
                {"detail": "Student not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        student.is_active = request.data["is_active"]
        student.save(update_fields=["is_active"])

        return Response({
            "success": True,
            "message": "Student account updated successfully.",
            "student": UserProfileSerializer(student).data,
        })
