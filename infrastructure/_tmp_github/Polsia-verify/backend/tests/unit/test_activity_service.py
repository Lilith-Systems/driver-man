import pytest
from app.services.activity_service import log_activity, get_recent_activity


@pytest.mark.asyncio
async def test_log_activity(async_db_session, mock_redis):
    entry = await log_activity(
        async_db_session, agent_type="orchestrator",
        action="test", summary="Test entry",
    )
    assert entry.id is not None
    assert entry.agent_type == "orchestrator"
    mock_redis.return_value.publish.assert_called_once()


@pytest.mark.asyncio
async def test_get_recent_activity(async_db_session, mock_redis):
    await log_activity(async_db_session, agent_type="social_media", action="post", summary="Posted")
    await log_activity(async_db_session, agent_type="finance", action="sync", summary="Synced")

    activities = await get_recent_activity(async_db_session)
    assert len(activities) >= 2
