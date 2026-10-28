from django.contrib import admin
from .models import Profile


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "phone", "preferred_language", "created_at")
    list_filter = ("role", "preferred_language")
    search_fields = ("user__username", "user__email", "phone")
