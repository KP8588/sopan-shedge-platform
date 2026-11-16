import os
import json
import base64
from django.contrib.auth import get_user_model
from rest_framework.test import APIRequestFactory, force_authenticate
from apps.classrooms.livekit_views import livekit_token

User = get_user_model()
user = User.objects.filter(pk=2).first()

if user is None:
    print("ERROR: User ID 2 does not exist.")
else:
    factory = APIRequestFactory()
    request = factory.post("/api/classrooms/4/livekit-token/")
    force_authenticate(request, user=user)

    response = livekit_token(request, classroom_id=4)
    print("Endpoint HTTP status:", response.status_code)

    data = getattr(response, "data", {})
    if response.status_code != 200:
        print("Endpoint error:", data)
    else:
        token = data.get("token", "")
        print("Returned URL:", data.get("serverUrl"))
        print("Room name:", data.get("roomName"))
        print("Identity:", data.get("identity"))
        print("Is trainer:", data.get("isTrainer"))
        print("Token present:", bool(token))

        parts = token.split(".")
        print("JWT structure valid:", len(parts) == 3)

        if len(parts) == 3:
            payload = parts[1] + "=" * (-len(parts[1]) % 4)
            claims = json.loads(base64.urlsafe_b64decode(payload))
            video = claims.get("video", {})
            print("Issuer matches configured key:",
                  claims.get("iss") == os.environ.get("LIVEKIT_API_KEY", "").strip())
            print("Token identity:", claims.get("sub"))
            print("Token room:", video.get("room"))
            print("Room join granted:", video.get("roomJoin"))
            print("Can publish:", video.get("canPublish"))
            print("Token expiry:", claims.get("exp"))
