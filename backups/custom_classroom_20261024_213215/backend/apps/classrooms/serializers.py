from rest_framework import serializers
from .models import Classroom


class ClassroomSerializer(serializers.ModelSerializer):
    class Meta:
        model = Classroom
        fields = [
            "id", "course", "title", "trainer", "scheduled_at",
            "duration_minutes", "meeting_url", "is_active", "created_at",
        ]
        read_only_fields = ["id", "created_at"]
        extra_kwargs = {"trainer": {"required": False}}
