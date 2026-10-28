from django.test import TestCase
from rest_framework.test import APIClient
from .models import Course


class CourseAPITests(TestCase):
    def test_only_active_courses_are_listed(self):
        Course.objects.create(title="Active Course", is_active=True)
        Course.objects.create(title="Inactive Course", is_active=False)

        response = APIClient().get("/api/courses/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["title"], "Active Course")