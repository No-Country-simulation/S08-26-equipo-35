import asyncio
import json
from unittest.mock import Mock
from uuid import uuid4

import pytest
from redis.exceptions import RedisError

import app.ws.redis_pubsub as redis_pubsub


def test_publish_event_wraps_event_and_uses_group_channel(monkeypatch):
    group_id = uuid4()
    redis_client = Mock()
    monkeypatch.setattr(redis_pubsub, "get_redis_sync", lambda: redis_client)

    redis_pubsub.publish_event(
        group_id,
        "expense.created",
        {"expense_id": "expense-1"},
    )

    channel, raw_event = redis_client.publish.call_args.args
    event = json.loads(raw_event)
    assert channel == f"group:{group_id}"
    assert event["type"] == "expense.created"
    assert event["group_id"] == str(group_id)
    assert event["payload"] == {"expense_id": "expense-1"}
    assert event["timestamp"].endswith("Z")


def test_subscriber_retries_with_exponential_backoff_and_forwards_event(monkeypatch):
    group_id = uuid4()
    delays = []
    attempts = 0
    broadcasted = []
    original_sleep = asyncio.sleep

    class FakePubSub:
        async def psubscribe(self, pattern):
            nonlocal attempts
            attempts += 1
            if attempts <= 4:
                raise RedisError("Redis unavailable")

        async def listen(self):
            yield {
                "type": "pmessage",
                "channel": f"group:{group_id}",
                "data": json.dumps({"type": "expense.created"}),
            }
            await asyncio.Future()

        async def aclose(self):
            return None

    class FakeRedis:
        def pubsub(self):
            return FakePubSub()

    async def fake_sleep(delay):
        delays.append(delay)
        await original_sleep(0)

    async def fake_broadcast(received_group_id, event):
        broadcasted.append((received_group_id, event))

    monkeypatch.setattr(redis_pubsub.asyncio, "sleep", fake_sleep)
    monkeypatch.setattr(redis_pubsub.manager, "broadcast_to_group", fake_broadcast)

    async def scenario():
        task = asyncio.create_task(redis_pubsub.subscribe_to_groups(FakeRedis()))
        try:
            for _ in range(100):
                if broadcasted:
                    break
                await original_sleep(0.01)
            assert broadcasted
        finally:
            task.cancel()
            with pytest.raises(asyncio.CancelledError):
                await task

    asyncio.run(scenario())

    assert attempts == 5
    assert delays == [1, 2, 4, 8]
    assert broadcasted == [(group_id, {"type": "expense.created"})]
