import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from passlib import exc
from redis import Redis
from redis.asyncio import Redis as AsyncRedis
from redis.exceptions import RedisError

from app.core.config import settings
from app.ws.manager import manager

logger = logging.getLogger(__name__)

_redis_sync: Redis | None = None
_redis_async: AsyncRedis | None = None


def get_redis_sync() -> Redis:
    global _redis_sync
    if _redis_sync is None:
        _redis_sync = Redis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
            socket_connect_timeout=1,
            socket_timeout=1,
        )
    return _redis_sync


def get_redis_async() -> AsyncRedis:
    global _redis_async
    if _redis_async is None:
        _redis_async = AsyncRedis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
            socket_connect_timeout=1,
        )
    return _redis_async


def publish_event(
    group_id: UUID | str, event_type: str, payload: dict[str, Any]
) -> None:
    event = {
        "type": event_type,
        "group_id": str(group_id),
        "timestamp": datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z"),
        "payload": payload,
    }
    try:
        get_redis_sync().publish(
            f"group:{group_id}",
            json.dumps(event, default=str),
        )
    except RedisError:
        logger.warning(
            "Redis unavailable; dropped event %s for group %s",
            event_type,
            group_id,
            exc_info=True,
        )


async def subscribe_to_groups(
    redis_client: AsyncRedis | None = None,
) -> None:
    client = redis_client or get_redis_async()
    backoff_seconds = 1

    while True:
        pubsub = client.pubsub()
        try:
            await pubsub.psubscribe("group:*")
            async for message in pubsub.listen():
                if message.get("type") != "pmessage":
                    continue

                if backoff_seconds > 1:
                    logger.info("Redis subscription reconnected")
                
                backoff_seconds = 1
                
                channel = message.get("channel", "")
                group_value = channel.removeprefix("group:")
                try:
                    group_id = UUID(group_value)
                    event = json.loads(message["data"])
                    if isinstance(event, dict):
                        await manager.broadcast_to_group(group_id, event)
                except (ValueError, TypeError, KeyError, json.JSONDecodeError):
                    logger.warning("Ignoring malformed Redis event on %r", channel)
        except asyncio.CancelledError:
            raise
        except RedisError:
            logger.warning(
                "Redis subscription failed; retrying in %s seconds",
                backoff_seconds,
            )
        finally:
            try:
                await pubsub.aclose()
            except RedisError:
                logger.debug("Error closing Redis Pub/Sub connection", exc_info=True)

        await asyncio.sleep(backoff_seconds)
        backoff_seconds = min(backoff_seconds * 2, 30)


async def close_redis_async(client: AsyncRedis | None = None) -> None:
    global _redis_async
    redis_client = client or _redis_async
    if redis_client is not None:
        await redis_client.aclose()
    if redis_client is _redis_async:
        _redis_async = None


def close_redis_sync() -> None:
    global _redis_sync
    if _redis_sync is not None:
        _redis_sync.close()
        _redis_sync = None
