
from rest_framework import generics, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Course
from .serializers import CourseSerializer


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
