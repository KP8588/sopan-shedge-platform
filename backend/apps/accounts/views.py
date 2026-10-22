
from django.contrib.auth import authenticate, get_user_model
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.serializers import (
    RegisterSerializer,
    UserProfileSerializer,
)

User = get_user_model()


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
        profile = getattr(request.user, "profile", None)

        if not request.user.is_staff and (
            profile is None or profile.role != "ADMIN"
        ):
            raise PermissionDenied(
                "Only administrators can view trainers."
            )

        trainers = User.objects.filter(
            is_active=True,
            profile__role="TRAINER",
        ).order_by("username")

        return Response(
            UserProfileSerializer(trainers, many=True).data
        )
