from django.conf import settings
from django.db import models
from django.utils.crypto import get_random_string


class Profile(models.Model):
    class Role(models.TextChoices):
        STUDENT = "STUDENT", "Student"
        TRAINER = "TRAINER", "Trainer"
        ADMIN = "ADMIN", "Administrator"

    class Language(models.TextChoices):
        ENGLISH = "en", "English"
        HINDI = "hi", "Hindi"
        MARATHI = "mr", "Marathi"
        KANNADA = "kn", "Kannada"
        TAMIL = "ta", "Tamil"
        TELUGU = "te", "Telugu"

    public_id = models.CharField(max_length=20, unique=True, blank=True)
    referral_code = models.CharField(max_length=16, unique=True, blank=True)

    referred_by = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="direct_referrals",
    )

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

    def save(self, *args, **kwargs):
        if not self.public_id:
            self.public_id = self._generate_unique_id("SP", 10)

        if not self.referral_code:
            self.referral_code = self._generate_unique_id("", 8)

        super().save(*args, **kwargs)

    @staticmethod
    def _generate_unique_id(prefix, length):
        while True:
            value = prefix + get_random_string(
                length,
                allowed_chars="ABCDEFGHJKLMNPQRSTUVWXYZ23456789",
            )
            if not Profile.objects.filter(
                models.Q(public_id=value) |
                models.Q(referral_code=value)
            ).exists():
                return value

    def __str__(self):
        return f"{self.public_id} - {self.user.username}"


class CommissionLedger(models.Model):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        AVAILABLE = "AVAILABLE", "Available"
        PAID = "PAID", "Paid"
        REVERSED = "REVERSED", "Reversed"

    referrer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="commissions_received",
        on_delete=models.PROTECT,
    )

    referred_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="referral_commissions",
        on_delete=models.PROTECT,
    )

    course_id = models.PositiveBigIntegerField()

    payment_reference = models.CharField(max_length=100, unique=True)

    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=600,
    )

    status = models.CharField(
        max_length=12,
        choices=Status.choices,
        default=Status.PENDING,
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return (
            f"Commission {self.id}: {self.referrer} "
            f"- ₹{self.amount} ({self.status})"
        )