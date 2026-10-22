from datetime import timedelta
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from apps.courses.models import Course
from .models import Classroom


class ClassroomAPITests(TestCase):
    def setUp(self):
        User = get_user_model()
        self.trainer = User.objects.create_user(
            username="trainer_test", password="TestPass123!"
        )
        self.trainer.profile.role = "TRAINER"
        self.trainer.profile.save()

        self.student = User.objects.create_user(
            username="student_test", password="TestPass123!"
        )
        self.course = Course.objects.create(title="Test Course")
        self.client = APIClient()

    def test_classroom_list_is_public(self):
        Classroom.objects.create(
            course=self.course,
            title="Test Class",
            trainer=self.trainer,
            scheduled_at=timezone.now() + timedelta(days=1),
        )
        response = self.client.get("/api/classrooms/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)

    def test_student_cannot_create_classroom(self):
        self.client.force_authenticate(user=self.student)
        response = self.client.post("/api/classrooms/", {
            "course": self.course.id,
            "title": "Unauthorized Class",
            "scheduled_at": (timezone.now() + timedelta(days=1)).isoformat(),
        })
        self.assertEqual(response.status_code, 403)

    def test_trainer_can_create_classroom(self):
        self.client.force_authenticate(user=self.trainer)
        response = self.client.post("/api/classrooms/", {
            "course": self.course.id,
            "title": "Trainer Class",
            "scheduled_at": (timezone.now() + timedelta(days=1)).isoformat(),
        })
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["trainer"], self.trainer.id)
