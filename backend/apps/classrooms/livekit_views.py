from datetime import timedelta
import logging
import os

from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.authentication import SessionAuthentication, TokenAuthentication
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from livekit import api

from apps.classrooms.models import Classroom

logger = logging.getLogger(__name__)


@api_view(["POST"])
@authentication_classes([TokenAuthentication, SessionAuthentication])
@permission_classes([IsAuthenticated])
def livekit_token(request, classroom_id):
    server_url = os.environ.get("LIVEKIT_URL", "").strip()
    api_key = os.environ.get("LIVEKIT_API_KEY", "").strip()
    api_secret = os.environ.get("LIVEKIT_API_SECRET", "").strip()

    if not server_url or not api_key or not api_secret:
        logger.error(
            "LiveKit configuration missing: URL=%s KEY=%s SECRET=%s",
            bool(server_url), bool(api_key), bool(api_secret)
        )
        return Response(
            {"detail": "Live classroom service is not configured."},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    classroom = get_object_or_404(Classroom, pk=classroom_id, is_active=True)
    is_trainer = classroom.trainer_id == request.user.pk
    room_name = f"sopan-class-{classroom.pk}"
    identity = f"user-{request.user.pk}"

    try:
        grants = api.VideoGrants(
            room_join=True,
            room=room_name,
            can_publish=True,
            can_subscribe=True,
            can_publish_data=is_trainer,
        )
        token = (
            api.AccessToken(api_key, api_secret)
            .with_identity(identity)
            .with_name("Trainer" if is_trainer else "Student")
            .with_grants(grants)
            .with_ttl(timedelta(hours=2))
            .to_jwt()
        )
    except Exception:
        logger.exception("LiveKit token generation failed for classroom %s", classroom.pk)
        return Response(
            {"detail": "Could not create classroom access token."},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    return Response({
        "serverUrl": server_url,
        "token": token,
        "roomName": room_name,
        "identity": identity,
        "isTrainer": is_trainer,
    })

