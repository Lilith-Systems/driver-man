import pytest
from app.services.task_service import create_task, get_task, update_task_status, list_tasks


@pytest.mark.asyncio
async def test_create_task(async_db_session):
    task = await create_task(async_db_session, title="Test task", agent_type="orchestrator")
    assert task.id is not None
    assert task.title == "Test task"
    assert task.status == "pending"


@pytest.mark.asyncio
async def test_get_task(async_db_session):
    task = await create_task(async_db_session, title="Find me", agent_type="social_media")
    found = await get_task(async_db_session, task.id)
    assert found is not None
    assert found.title == "Find me"


@pytest.mark.asyncio
async def test_get_task_not_found(async_db_session):
    found = await get_task(async_db_session, 999)
    assert found is None


@pytest.mark.asyncio
async def test_update_task_status(async_db_session):
    task = await create_task(async_db_session, title="Update me", agent_type="finance")
    updated = await update_task_status(async_db_session, task.id, "completed", result_summary="Done")
    assert updated.status == "completed"
    assert updated.result_summary == "Done"


@pytest.mark.asyncio
async def test_list_tasks_filter_by_status(async_db_session):
    await create_task(async_db_session, title="Task A", agent_type="orchestrator")
    await create_task(async_db_session, title="Task B", agent_type="social_media")
    tasks = await list_tasks(async_db_session)
    assert len(tasks) >= 2
