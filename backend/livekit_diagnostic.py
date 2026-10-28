import os
import json
import base64
from datetime import timedelta
from livekit import api

key = os.environ.get("LIVEKIT_API_KEY", "").strip()
secret = os.environ.get("LIVEKIT_API_SECRET", "").strip()

print("Key configured:", bool(key))
print("Secret configured:", bool(secret))

try:
    token = (
        api.AccessToken(key, secret)
        .with_identity("diagnostic-user")
        .with_grants(api.VideoGrants(
            room_join=True,
            room="sopan-class-4",
            can_publish=False,
            can_subscribe=True,
        ))
        .with_ttl(timedelta(minutes=5))
        .to_jwt()
    )

    if hasattr(token, "__await__"):
        import asyncio
        token = asyncio.run(token)

    parts = token.split(".")
    print("JWT structure valid:", len(parts) == 3)

    if len(parts) == 3:
        payload = parts[1] + "=" * (-len(parts[1]) % 4)
        claims = json.loads(base64.urlsafe_b64decode(payload))
        print("Issuer matches configured key:", claims.get("iss") == key)
        print("Identity present:", bool(claims.get("sub")))
        print("Room join granted:", claims.get("video", {}).get("roomJoin"))
        print("Room name:", claims.get("video", {}).get("room"))
        print("Token generated successfully.")
except Exception as exc:
    print("Token test failed:", type(exc).__name__, str(exc))
