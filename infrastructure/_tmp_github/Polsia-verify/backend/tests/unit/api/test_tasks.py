import pytest


@pytest.mark.asyncio
async def test_list_tasks_empty(api_client, auth_headers):
    resp = await api_client.get("/api/v1/tasks", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_create_task(api_client, auth_headers):
    resp = await api_client.post(
        "/api/v1/tasks",
        json={"title": "Test task", "agent_type": "orchestrator"},
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["title"] == "Test task"


@pytest.mark.asyncio
async def test_get_task_by_id(api_client, async_db_session, auth_headers):
    from app.services.task_service import create_task
    task = await create_task(async_db_session, title="Specific", agent_type="finance")

    resp = await api_client.get(f"/api/v1/tasks/{task.id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["title"] == "Specific"


@pytest.mark.asyncio
async def test_get_task_not_found(api_client, auth_headers):
    resp = await api_client.get("/api/v1/tasks/999", headers=auth_headers)
    assert resp.status_code == 404
