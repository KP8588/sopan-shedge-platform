from pathlib import Path
import re

root = Path("backend/apps/accounts")
serializers_path = root / "serializers.py"
views_path = root / "views.py"
urls_path = root / "urls.py"

# 1. Add dedicated student serializers
serializers = serializers_path.read_text(encoding="utf-8")
if "class CreateStudentSerializer" not in serializers:
    serializers += '''

class CreateStudentSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
    )
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    preferred_language = serializers.ChoiceField(
        choices=(("en", "English"), ("hi", "Hindi"), ("mr", "Marathi")),
        required=False,
        default="en",
    )

    class Meta:
        model = User
        fields = ("username", "email", "password", "phone", "preferred_language")

    def validate_email(self, value):
        value = value.strip().lower()
        if not value:
            raise serializers.ValidationError("Email is required.")
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def create(self, validated_data):
        phone = validated_data.pop("phone", "")
        language = validated_data.pop("preferred_language", "en")
        password = validated_data.pop("password")
        user = User.objects.create_user(password=password, **validated_data)
        profile = user.profile
        profile.role = "STUDENT"
        profile.phone = phone
        profile.preferred_language = language
        profile.save(update_fields=("role", "phone", "preferred_language", "updated_at"))
        return user


class UpdateStudentSerializer(serializers.Serializer):
    email = serializers.EmailField(required=False)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    preferred_language = serializers.ChoiceField(
        choices=(("en", "English"), ("hi", "Hindi"), ("mr", "Marathi")),
        required=False,
    )

    def validate_email(self, value):
        value = value.strip().lower()
        user = self.instance
        if User.objects.filter(email__iexact=value).exclude(pk=user.pk).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def update(self, instance, validated_data):
        if "email" in validated_data:
            instance.email = validated_data["email"]
            instance.save(update_fields=("email",))

        profile = instance.profile
        changed = []
        for field in ("phone", "preferred_language"):
            if field in validated_data:
                setattr(profile, field, validated_data[field])
                changed.append(field)
        if changed:
            profile.save(update_fields=tuple(changed + ["updated_at"]))
        return instance
'''
    serializers_path.write_text(serializers, encoding="utf-8")

# 2. Update the views imports and replace duplicate student view definitions
views = views_path.read_text(encoding="utf-8")
views = re.sub(
    r'from apps\.accounts\.serializers import \([\s\S]*?\)',
    '''from apps.accounts.serializers import (
    RegisterSerializer,
    CreateTrainerSerializer,
    UserProfileSerializer,
    CreateStudentSerializer,
    UpdateStudentSerializer,
)''',
    views,
    count=1,
)

student_views = '''

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
'''

if "class StudentListView(APIView):" not in views:
    raise SystemExit("Could not find StudentListView. No views were rewritten.")
views = re.sub(r'\nclass StudentListView\(APIView\):[\s\S]*\Z', student_views, views, count=1)
views = views.replace(
    "    StudentStatusUpdateView,\nStudentListView,\nStudentStatusUpdateView,\n",
    "    StudentStatusUpdateView,\n",
)
views_path.write_text(views, encoding="utf-8")

# 3. Register clean, non-duplicated URL routes
urls_path.write_text('''from django.urls import path

from apps.accounts.views import (
    LoginView,
    LogoutView,
    MeView,
    RegisterView,
    TrainerCreateView,
    TrainerListView,
    StudentListView,
    StudentCreateView,
    StudentManageView,
    StudentStatusUpdateView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("me/", MeView.as_view(), name="me"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("users/", TrainerListView.as_view(), name="users"),
    path("trainers/create/", TrainerCreateView.as_view(), name="trainer-create"),
    path("students/", StudentListView.as_view(), name="student-list"),
    path("students/create/", StudentCreateView.as_view(), name="student-create"),
    path("students/<int:pk>/manage/", StudentManageView.as_view(), name="student-manage"),
    path("students/<int:pk>/", StudentStatusUpdateView.as_view(), name="student-status-update"),
]
''', encoding="utf-8")

print("Student API files updated. Backups:", Path("..") / "backup")
