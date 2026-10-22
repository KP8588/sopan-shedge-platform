from django.contrib import admin
from .models import Classroom


@admin.register(Classroom)
class ClassroomAdmin(admin.ModelAdmin):
    list_display = (
        "title", "course", "trainer", "scheduled_at", "is_active",
    )
    list_filter = ("is_active", "course")
    search_fields = ("title",)
