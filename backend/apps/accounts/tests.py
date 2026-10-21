from django.test import TestCase
from django.contrib.auth import get_user_model


class AccountsTests(TestCase):
    def test_user_gets_student_profile(self):
        user = get_user_model().objects.create_user(
            username="teststudent",
            password="TestPass123!"
        )
        self.assertEqual(user.profile.role, "STUDENT")