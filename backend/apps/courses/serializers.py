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
            "price",
            "is_active",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def validate_price(self, value):
        if value <= 0:
            raise serializers.ValidationError(
                "Course price must be greater than zero."
            )
        return value

    
from .models import RecordedLecture, LectureProgress


class RecordedLectureSerializer(serializers.ModelSerializer):
    video_file_url = serializers.SerializerMethodField()

    class Meta:
        model = RecordedLecture
        fields = [
            "id",
            "course",
            "title",
            "description",
            "video_file_url",
            "video_url",
            "duration_seconds",
            "order",
            "is_published",
            "created_at",
        ]
        read_only_fields = ["id", "created_at", "is_published"]

    def get_video_file_url(self, obj):
        request = self.context.get("request")
        if obj.video_file:
            url = obj.video_file.url
            return request.build_absolute_uri(url) if request else url
        return None


class LectureProgressSerializer(serializers.ModelSerializer):
    lecture_title = serializers.CharField(
        source="lecture.title",
        read_only=True,
    )

    class Meta:
        model = LectureProgress
        fields = [
            "id",
            "lecture",
            "lecture_title",
            "position_seconds",
            "completed",
            "updated_at",
        ]
        read_only_fields = ["id", "lecture_title", "updated_at"]

    def validate_position_seconds(self, value):
        if value < 0:
            raise serializers.ValidationError(
                "Position cannot be negative."
            )
        return value
