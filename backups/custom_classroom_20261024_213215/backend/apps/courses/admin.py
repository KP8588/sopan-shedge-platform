from django.contrib import admin
from .models import Course


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("title", "language", "is_active", "created_at")
    list_filter = ("language", "is_active")
    search_fields = ("title", "description")