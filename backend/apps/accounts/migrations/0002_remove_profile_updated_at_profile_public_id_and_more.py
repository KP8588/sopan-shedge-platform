import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models
from django.utils.crypto import get_random_string


def populate_profile_ids(apps, schema_editor):
    Profile = apps.get_model("accounts", "Profile")
    db_alias = schema_editor.connection.alias

    used = set()

    profiles = Profile.objects.using(db_alias).order_by("pk")

    for profile in profiles:
        public_id = profile.public_id
        referral_code = profile.referral_code

        if not public_id:
            while True:
                candidate = "SP" + get_random_string(
                    10,
                    allowed_chars="ABCDEFGHJKLMNPQRSTUVWXYZ23456789",
                )
                if candidate not in used:
                    public_id = candidate
                    used.add(candidate)
                    break
        else:
            used.add(public_id)

        if not referral_code:
            while True:
                candidate = get_random_string(
                    8,
                    allowed_chars="ABCDEFGHJKLMNPQRSTUVWXYZ23456789",
                )
                if candidate not in used:
                    referral_code = candidate
                    used.add(candidate)
                    break
        else:
            used.add(referral_code)

        Profile.objects.using(db_alias).filter(pk=profile.pk).update(
            public_id=public_id,
            referral_code=referral_code,
        )


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0001_initial"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.RemoveField(
            model_name="profile",
            name="updated_at",
        ),
        migrations.AddField(
            model_name="profile",
            name="public_id",
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.AddField(
            model_name="profile",
            name="referral_code",
            field=models.CharField(blank=True, max_length=16),
        ),
        migrations.AddField(
            model_name="profile",
            name="referred_by",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="direct_referrals",
                to="accounts.profile",
            ),
        ),
        migrations.RunPython(
            populate_profile_ids,
            migrations.RunPython.noop,
        ),
        migrations.AlterField(
            model_name="profile",
            name="public_id",
            field=models.CharField(blank=True, max_length=20, unique=True),
        ),
        migrations.AlterField(
            model_name="profile",
            name="referral_code",
            field=models.CharField(blank=True, max_length=16, unique=True),
        ),
        migrations.AlterField(
            model_name="profile",
            name="preferred_language",
            field=models.CharField(
                choices=[
                    ("en", "English"),
                    ("hi", "Hindi"),
                    ("mr", "Marathi"),
                    ("kn", "Kannada"),
                    ("ta", "Tamil"),
                    ("te", "Telugu"),
                ],
                default="en",
                max_length=5,
            ),
        ),
        migrations.CreateModel(
            name="CommissionLedger",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("course_id", models.PositiveBigIntegerField()),
                ("payment_reference", models.CharField(max_length=100, unique=True)),
                (
                    "amount",
                    models.DecimalField(
                        decimal_places=2,
                        default=600,
                        max_digits=10,
                    ),
                ),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("PENDING", "Pending"),
                            ("AVAILABLE", "Available"),
                            ("PAID", "Paid"),
                            ("REVERSED", "Reversed"),
                        ],
                        default="PENDING",
                        max_length=12,
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "referred_user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="referral_commissions",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "referrer",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="commissions_received",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
        ),
    ]
