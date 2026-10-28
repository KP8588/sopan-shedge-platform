from rest_framework import serializers
from .models import Course


class CourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = [
            "id",
            "title",
            "description",
            "language",
            "is_active",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]