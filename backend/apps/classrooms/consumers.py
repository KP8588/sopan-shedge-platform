import json
import re

from channels.generic.websocket import AsyncJsonWebsocketConsumer


class ClassroomSignalingConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        user = self.scope.get("user")
        if not user or not user.is_authenticated:
            await self.close(code=4401)
            return

        self.class_id = self.scope["url_route"]["kwargs"]["class_id"]
        self.group_name = f"classroom_{self.class_id}"

        # Prevent invalid Channels group names.
        if not re.fullmatch(r"[A-Za-z0-9_-]{1,80}", self.group_name):
            await self.close(code=4400)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "signal.message",
                "payload": {
                    "type": "participant_joined",
                    "participant_id": str(user.pk),
                },
                "exclude_channel": self.channel_name,
            },
        )

    async def disconnect(self, close_code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(
                self.group_name, self.channel_name
            )
            user = self.scope.get("user")
            if user and user.is_authenticated:
                await self.channel_layer.group_send(
                    self.group_name,
                    {
                        "type": "signal.message",
                        "payload": {
                            "type": "participant_left",
                            "participant_id": str(user.pk),
                        },
                        "exclude_channel": self.channel_name,
                    },
                )

    async def receive_json(self, content, **kwargs):
        if not isinstance(content, dict):
            await self.close(code=4400)
            return

        message_type = content.get("type")
        allowed_types = {"offer", "answer", "ice_candidate"}

        if message_type not in allowed_types:
            await self.send_json({
                "type": "error",
                "message": "Unsupported signaling message type.",
            })
            return

        # Keep signaling messages bounded and structurally valid.
        if len(json.dumps(content)) > 64_000:
            await self.send_json({
                "type": "error",
                "message": "Signaling message is too large.",
            })
            return

        user = self.scope["user"]
        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "signal.message",
                "payload": {
                    **content,
                    "sender_id": str(user.pk),
                },
                "exclude_channel": self.channel_name,
            },
        )

    async def signal_message(self, event):
        if event.get("exclude_channel") == self.channel_name:
            return
        await self.send_json(event["payload"])
