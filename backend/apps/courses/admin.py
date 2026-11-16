
from django.contrib import admin
from .models import Course, RecordedLecture, LectureProgress


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("title", "language", "price", "is_active", "created_at")
    list_filter = ("language", "is_active")
    search_fields = ("title", "description")


@admin.register(RecordedLecture)
class RecordedLectureAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "course",
        "duration_seconds",
        "order",
        "is_published",
        "created_at",
    )
    list_filter = ("is_published", "course")
    search_fields = ("title", "description", "course__title")
    list_editable = ("order", "is_published")


@admin.register(LectureProgress)
class LectureProgressAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "lecture",
        "position_seconds",
        "completed",
        "updated_at",
    )
    list_filter = ("completed",)
    search_fields = ("user__username", "lecture__title")
    readonly_fields = ("updated_at",)
