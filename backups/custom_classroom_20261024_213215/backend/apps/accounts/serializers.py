
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


class CreateStudentSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
    )
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    preferred_language = serializers.ChoiceField(
        choices=(("en", "English"), ("hi", "Hindi"), ("mr", "Marathi")),
        required=False,
        default="en",
    )

    class Meta:
        model = User
        fields = ("username", "email", "password", "phone", "preferred_language")

    def validate_email(self, value):
        value = value.strip().lower()
        if not value:
            raise serializers.ValidationError("Email is required.")
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def create(self, validated_data):
        phone = validated_data.pop("phone", "")
        language = validated_data.pop("preferred_language", "en")
        password = validated_data.pop("password")
        user = User.objects.create_user(password=password, **validated_data)
        profile = user.profile
        profile.role = "STUDENT"
        profile.phone = phone
        profile.preferred_language = language
        profile.save(update_fields=("role", "phone", "preferred_language", "updated_at"))
        return user


class UpdateStudentSerializer(serializers.Serializer):
    email = serializers.EmailField(required=False)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    preferred_language = serializers.ChoiceField(
        choices=(("en", "English"), ("hi", "Hindi"), ("mr", "Marathi")),
        required=False,
    )

    def validate_email(self, value):
        value = value.strip().lower()
        user = self.instance
        if User.objects.filter(email__iexact=value).exclude(pk=user.pk).exists():
            raise serializers.ValidationError("An account with this email already exists.")
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
            profile.save(update_fields=tuple(changed + ["updated_at"]))
        return instance
