
from rest_framework import generics, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Course
from .serializers import CourseSerializer
from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from .models import RecordedLecture, LectureProgress
from .serializers import (
    RecordedLectureSerializer,
    LectureProgressSerializer,
)

def require_admin(user):
    profile = getattr(user, "profile", None)

    if not user.is_staff and (
        profile is None or profile.role != "ADMIN"
    ):
        raise PermissionDenied(
            "Only administrators can perform this action."
        )


class CourseListView(generics.ListAPIView):
    queryset = Course.objects.filter(is_active=True).order_by("title")
    serializer_class = CourseSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class CourseDetailView(generics.RetrieveAPIView):
    queryset = Course.objects.filter(is_active=True)
    serializer_class = CourseSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class CourseCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        require_admin(request.user)

        serializer = CourseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        course = serializer.save()

        return Response(
            {
                "success": True,
                "message": "Course created successfully.",
                "course": CourseSerializer(course).data,
            },
            status=status.HTTP_201_CREATED,
        )


class CourseManagementListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        require_admin(request.user)

        courses = Course.objects.all().order_by("title")
        serializer = CourseSerializer(courses, many=True)

        return Response(serializer.data)


class CourseUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        require_admin(request.user)

        try:
            course = Course.objects.get(pk=pk)
        except Course.DoesNotExist:
            return Response(
                {"detail": "Course not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = CourseSerializer(
            course,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        course = serializer.save()

        return Response(
            {
                "success": True,
                "message": "Course updated successfully.",
                "course": CourseSerializer(course).data,
            }
        )


class RecordedLectureListView(generics.ListAPIView):
    serializer_class = RecordedLectureSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = RecordedLecture.objects.filter(
            is_published=True,
            course__is_active=True,
        ).select_related("course")

        course_id = self.request.query_params.get("course")

        if course_id:
            queryset = queryset.filter(course_id=course_id)

        return queryset.order_by("course_id", "order", "created_at")


class RecordedLectureDetailView(generics.RetrieveAPIView):
    serializer_class = RecordedLectureSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return RecordedLecture.objects.filter(
            is_published=True,
            course__is_active=True,
        ).select_related("course")


class LectureProgressListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        progress = LectureProgress.objects.filter(
            user=request.user
        ).select_related("lecture")

        serializer = LectureProgressSerializer(
            progress,
            many=True,
        )

        return Response(serializer.data)


class LectureProgressUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, lecture_id):
        lecture = get_object_or_404(
            RecordedLecture,
            pk=lecture_id,
            is_published=True,
            course__is_active=True,
        )

        position = request.data.get("position_seconds", 0)
        completed = request.data.get("completed", False)

        try:
            position = int(position)
        except (TypeError, ValueError):
            return Response(
                {"detail": "Invalid video position."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if position < 0:
            return Response(
                {"detail": "Video position cannot be negative."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not isinstance(completed, bool):
            return Response(
                {"detail": "Completed must be true or false."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        progress, created = LectureProgress.objects.update_or_create(
            user=request.user,
            lecture=lecture,
            defaults={
                "position_seconds": position,
                "completed": completed,
            },
        )

        serializer = LectureProgressSerializer(progress)

        return Response(
            {
                "success": True,
                "message": "Lecture progress saved.",
                "progress": serializer.data,
            },
            status=status.HTTP_200_OK,
        )
