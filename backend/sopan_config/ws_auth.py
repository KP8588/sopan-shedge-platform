from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware
from django.contrib.auth.models import AnonymousUser
from rest_framework.authtoken.models import Token


@database_sync_to_async
def get_user_from_token(token_key):
    try:
        return Token.objects.select_related("user").get(key=token_key).user
    except Token.DoesNotExist:
        return AnonymousUser()


class TokenAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        scope = dict(scope)
        headers = dict(scope.get("headers", []))
        authorization = headers.get(b"authorization", b"").decode(
            "utf-8", errors="ignore"
        )

        user = AnonymousUser()
        if authorization.startswith("Token "):
            key = authorization[6:].strip()
            if key and len(key) <= 40:
                user = await get_user_from_token(key)

        scope["user"] = user
        return await super().__call__(scope, receive, send)
