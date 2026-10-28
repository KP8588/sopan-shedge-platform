import os
from django.conf import settings
from django.urls import resolve

print("DEBUG:", settings.DEBUG)
print("ALLOWED_HOSTS:", settings.ALLOWED_HOSTS)

for path in [
    "/api/auth/login/",
    "/api/classrooms/4/livekit-token/",
]:
    try:
        match = resolve(path)
        print(
            path,
            "->",
            match.func.__module__,
            match.func.__name__,
        )
    except Exception as exc:
        print(path, "-> URL resolution error:", str(exc))

url = os.environ.get("LIVEKIT_URL", "").strip()
print("LiveKit URL configured:", bool(url))
print("LiveKit URL scheme:", url.split(":", 1)[0] if ":" in url else "missing")
