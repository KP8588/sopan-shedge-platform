from rest_framework import generics
from rest_framework.permissions import IsAuthenticatedOrReadOnly

from .models import Course
from .serializers import CourseSerializer


class CourseListView(generics.ListAPIView):
    queryset = Course.objects.filter(is_active=True).order_by("title")
    serializer_class = CourseSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class CourseDetailView(generics.RetrieveAPIView):
    queryset = Course.objects.filter(is_active=True)
    serializer_class = CourseSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]