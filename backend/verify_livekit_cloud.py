import asyncio
from dotenv import load_dotenv
from livekit import api

load_dotenv(override=True)

url = __import__("os").getenv("LIVEKIT_URL", "").strip()
key = __import__("os").getenv("LIVEKIT_API_KEY", "").strip()
secret = __import__("os").getenv("LIVEKIT_API_SECRET", "").strip()

if not all([url, key, secret]):
    print("FAIL: LiveKit environment variables are missing.")
    raise SystemExit(1)

http_url = url.replace("wss://", "https://", 1)

async def main():
    client = api.LiveKitAPI(http_url, key, secret)
    try:
        await client.room.list_rooms(api.ListRoomsRequest())
        print("PASS: LiveKit Cloud accepted the API credentials.")
        print("Host:", http_url.split("/")[2])
    except Exception as exc:
        print("FAIL:", type(exc).__name__)
        print(str(exc)[:400])
    finally:
        await client.aclose()

asyncio.run(main())
