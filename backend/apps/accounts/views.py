from django.contrib.auth import authenticate, get_user_model
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Sum
from apps.accounts.models import Profile, CommissionLedger

from apps.accounts.serializers import (
    RegisterSerializer,
    CreateTrainerSerializer,
    UserProfileSerializer,
    CreateStudentSerializer,
    UpdateStudentSerializer,
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
        return Response(UserProfileSerializer(students, many=True).data)


class StudentCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        require_admin(request.user)
        serializer = CreateStudentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        student = serializer.save()
        return Response(
            {
                "success": True,
                "message": "Student created successfully.",
                "student": UserProfileSerializer(student).data,
            },
            status=status.HTTP_201_CREATED,
        )


class StudentManageView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        require_admin(request.user)
        try:
            student = User.objects.get(pk=pk, profile__role="STUDENT")
        except User.DoesNotExist:
            return Response(
                {"detail": "Student not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = UpdateStudentSerializer(
            student, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        student = serializer.save()
        return Response(
            {
                "success": True,
                "message": "Student details updated successfully.",
                "student": UserProfileSerializer(student).data,
            }
        )


class StudentStatusUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        require_admin(request.user)
        is_active = request.data.get("is_active")
        if not isinstance(is_active, bool):
            return Response(
                {"detail": "is_active must be true or false."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            student = User.objects.get(pk=pk, profile__role="STUDENT")
        except User.DoesNotExist:
            return Response(
                {"detail": "Student not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        student.is_active = is_active
        student.save(update_fields=["is_active"])
        return Response(
            {
                "success": True,
                "message": "Student account updated successfully.",
                "student": UserProfileSerializer(student).data,
            }
        )

class MyReferralView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = Profile.objects.get(user=request.user)

        referrals = Profile.objects.filter(
            referred_by=profile
        ).select_related("user").order_by("-created_at")

        commissions = CommissionLedger.objects.filter(
            referrer=request.user
        )

        summary = commissions.values("status").annotate(
            total=Sum("amount")
        )

        totals = {
            row["status"]: row["total"] or 0
            for row in summary
        }

        return Response({
            "success": True,
            "user_id": profile.public_id,
            "referral_code": profile.referral_code,
            "referral_link_suffix": "?ref=" + profile.referral_code,
            "direct_referral_count": referrals.count(),
            "referrals": [
                {
                    "user_id": item.public_id,
                    "public_id": item.public_id,
                    "username": item.user.username,
                    "joined_at": item.created_at,
                }
                for item in referrals
            ],
            "commission_summary": {
                "pending": totals.get("PENDING", 0),
                "available": totals.get("AVAILABLE", 0),
                "paid": totals.get("PAID", 0),
            },
        })


class ReferralTreeAdminView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        require_admin(request.user)

        profiles = Profile.objects.select_related(
            "user", "referred_by"
        ).order_by("created_at")

        children = {}
        for profile in profiles:
            parent_id = profile.referred_by_id
            children.setdefault(parent_id, []).append(profile)

        def build_node(profile, visited):
            if profile.pk in visited:
                return {
                    "public_id": profile.public_id,
                    "username": profile.user.username,
                    "children": [],
                }

            next_visited = visited | {profile.pk}

            return {
                "public_id": profile.public_id,
                "username": profile.user.username,
                "role": profile.role,
                "referral_code": profile.referral_code,
                "joined_at": profile.created_at,
                "children": [
                    build_node(child, next_visited)
                    for child in children.get(profile.pk, [])
                ],
            }

        roots = children.get(None, [])

        return Response({
            "success": True,
            "count": profiles.count(),
            "tree": [build_node(root, set()) for root in roots],
        })


class CommissionAdminView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        require_admin(request.user)

        queryset = CommissionLedger.objects.select_related(
            "referrer", "referred_user"
        ).order_by("-created_at")

        status_filter = request.query_params.get("status")
        if status_filter:
            allowed = {choice[0] for choice in CommissionLedger.Status.choices}
            if status_filter not in allowed:
                return Response(
                    {"detail": "Invalid commission status."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            queryset = queryset.filter(status=status_filter)

        return Response({
            "success": True,
            "count": queryset.count(),
            "commissions": [
                {
                    "id": item.pk,
                    "referrer": item.referrer.username,
                    "referred_user": item.referred_user.username,
                    "course_id": item.course_id,
                    "payment_reference": item.payment_reference,
                    "amount": item.amount,
                    "status": item.status,
                    "created_at": item.created_at,
                    "updated_at": item.updated_at,
                }
                for item in queryset
            ],
        })

