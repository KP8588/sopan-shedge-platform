
from django.contrib.auth import get_user_model
from rest_framework import serializers

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
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
        return User.objects.create_user(
            username=validated_data["username"],
            email=validated_data["email"],
            password=validated_data["password"],
        )


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

        # The profile signal creates the default STUDENT profile.
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

    class Meta:
        model = User
        fields = (
            "id",
            "username",
            "email",
            "role",
            "phone",
            "preferred_language",
            "is_active",
        )
