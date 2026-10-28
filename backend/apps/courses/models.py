from decimal import Decimal

from django.db import models


class Course(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    language = models.CharField(max_length=10, default="en")
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal("2100.00"),
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title