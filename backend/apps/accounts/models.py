from django.conf import settings
from django.db import models


class Profile(models.Model):
    class Role(models.TextChoices):
        STUDENT = "STUDENT", "Student"
        TRAINER = "TRAINER", "Trainer"
        ADMIN = "ADMIN", "Administrator"

    class Language(models.TextChoices):
        ENGLISH = "en", "English"
        HINDI = "hi", "Hindi"
        MARATHI = "mr", "Marathi"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile",
    )
    role = models.CharField(
        max_length=10,
        choices=Role.choices,
        default=Role.STUDENT,
    )
    phone = models.CharField(max_length=20, blank=True)
    preferred_language = models.CharField(
        max_length=5,
        choices=Language.choices,
        default=Language.ENGLISH,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} - {self.get_role_display()}"
