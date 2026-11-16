
from django.contrib.auth import get_user_model
from django.db import transaction
from rest_framework import serializers

User = get_user_model()


LANGUAGE_CHOICES = (
    ("en", "English"),
    ("hi", "Hindi"),
    ("mr", "Marathi"),
    ("kn", "Kannada"),
    ("ta", "Tamil"),
    ("te", "Telugu"),
)


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
    )
    phone = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=20,
    )
    preferred_language = serializers.ChoiceField(
        choices=LANGUAGE_CHOICES,
        required=False,
        default="en",
    )
    referral_code = serializers.CharField(
        required=False,
        allow_blank=True,
        write_only=True,
    )

    class Meta:
        model = User
        fields = (
            "username",
            "email",
            "password",
            "phone",
            "preferred_language",
            "referral_code",
        )

    def validate_email(self, value):
        value = value.strip().lower()

        if not value:
            raise serializers.ValidationError("Email is required.")

        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "An account with this email already exists."
            )

        return value

    def validate_referral_code(self, value):
        value = value.strip().upper()

        if not value:
            return ""

        from apps.accounts.models import Profile

        if not Profile.objects.filter(referral_code=value).exists():
            raise serializers.ValidationError("Invalid referral code.")

        return value

    def create(self, validated_data):
        from apps.accounts.models import Profile

        referral_code = validated_data.pop("referral_code", "")
        phone = validated_data.pop("phone", "")
        preferred_language = validated_data.pop(
            "preferred_language", "en"
        )

        with transaction.atomic():
            user = User.objects.create_user(**validated_data)

            profile = Profile.objects.select_for_update().get(user=user)
            profile.phone = phone
            profile.preferred_language = preferred_language

            if referral_code:
                referrer = Profile.objects.get(
                    referral_code=referral_code
                )
                if referrer.user_id == user.id:
                    raise serializers.ValidationError(
                        {"referral_code": "You cannot use your own referral code."}
                    )
                profile.referred_by = referrer

            profile.save()

        return user


class CreateTrainerSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
    )

    class Meta:
        model = User
        fields = ("username", "email", "password")

    def validate_email(self, value):
        value = value.strip().lower()

        if not value:
            raise serializers.ValidationError("Email is required.")

        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "An account with this email already exists."
            )

        return value

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)

        user.profile.role = "TRAINER"
        user.profile.save(update_fields=["role"])

        return user


class UserProfileSerializer(serializers.ModelSerializer):
    role = serializers.CharField(
        source="profile.role",
        read_only=True,
    )
    preferred_language = serializers.CharField(
        source="profile.preferred_language",
        read_only=True,
    )
    phone = serializers.CharField(
        source="profile.phone",
        read_only=True,
    )
    is_active = serializers.BooleanField(read_only=True)
    public_id = serializers.CharField(
        source="profile.public_id",
        read_only=True,
    )
    referral_code = serializers.CharField(
        source="profile.referral_code",
        read_only=True,
    )
    referred_by_username = serializers.SerializerMethodField()

    def get_referred_by_username(self, obj):
        profile = getattr(obj, "profile", None)
        referrer = getattr(profile, "referred_by", None)
        return referrer.user.username if referrer else None

    class Meta:
        model = User
        fields = (
            "id",
            "username",
            "email",
            "role",
            "phone",
            "preferred_language",
            "public_id",
            "referral_code",
            "referred_by_username",
            "is_active",
        )


class CreateStudentSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
    )
    phone = serializers.CharField(
        max_length=20,
        required=False,
        allow_blank=True,
    )
    preferred_language = serializers.ChoiceField(
        choices=LANGUAGE_CHOICES,
        required=False,
        default="en",
    )

    class Meta:
        model = User
        fields = (
            "username",
            "email",
            "password",
            "phone",
            "preferred_language",
        )

    def validate_email(self, value):
        value = value.strip().lower()

        if not value:
            raise serializers.ValidationError("Email is required.")

        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "An account with this email already exists."
            )

        return value

    def create(self, validated_data):
        phone = validated_data.pop("phone", "")
        language = validated_data.pop("preferred_language", "en")
        password = validated_data.pop("password")

        with transaction.atomic():
            user = User.objects.create_user(
                password=password,
                **validated_data,
            )
            profile = user.profile
            profile.role = "STUDENT"
            profile.phone = phone
            profile.preferred_language = language
            profile.save(
                update_fields=(
                    "role",
                    "phone",
                    "preferred_language",
                )
            )

        return user


class UpdateStudentSerializer(serializers.Serializer):
    email = serializers.EmailField(required=False)
    phone = serializers.CharField(
        max_length=20,
        required=False,
        allow_blank=True,
    )
    preferred_language = serializers.ChoiceField(
        choices=LANGUAGE_CHOICES,
        required=False,
    )

    def validate_email(self, value):
        value = value.strip().lower()
        user = self.instance

        if User.objects.filter(
            email__iexact=value
        ).exclude(pk=user.pk).exists():
            raise serializers.ValidationError(
                "An account with this email already exists."
            )

        return value

    def update(self, instance, validated_data):
        if "email" in validated_data:
            instance.email = validated_data["email"]
            instance.save(update_fields=("email",))

        profile = instance.profile
        changed = []

        for field in ("phone", "preferred_language"):
            if field in validated_data:
                setattr(profile, field, validated_data[field])
                changed.append(field)

        if changed:
            profile.save(update_fields=tuple(changed))

        return instance
