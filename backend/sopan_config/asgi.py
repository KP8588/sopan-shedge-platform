import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "sopan_config.settings")

from django.core.asgi import get_asgi_application

django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter
from apps.classrooms.routing import websocket_urlpatterns
from sopan_config.ws_auth import TokenAuthMiddleware

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": TokenAuthMiddleware(
        URLRouter(websocket_urlpatterns)
    ),
})
