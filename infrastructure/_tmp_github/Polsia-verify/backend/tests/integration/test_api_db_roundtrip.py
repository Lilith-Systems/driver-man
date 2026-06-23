import pytest


@pytest.mark.integration
@pytest.mark.asyncio
async def test_create_and_retrieve_task(int_client):
    headers = {"X-API-Key": "polsia-unlocked-key"}

    resp = await int_client.post(
        "/api/v1/tasks",
        json={"title": "Integration test", "agent_type": "orchestrator"},
        headers=headers,
    )
    assert resp.status_code == 201
    task_id = resp.json()["id"]

    resp = await int_client.get(f"/api/v1/tasks/{task_id}", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["title"] == "Integration test"


@pytest.mark.integration
@pytest.mark.asyncio
async def test_health_check(int_client):
    resp = await int_client.get("/api/v1/health")
    assert resp.status_code == 200
