import pytest


@pytest.mark.asyncio
async def test_trigger_valid_agent(api_client, auth_headers):
    resp = await api_client.post("/api/v1/agents/orchestrator/trigger", headers=auth_headers)
    assert resp.status_code == 202
    data = resp.json()
    assert data["status"] == "queued"


@pytest.mark.asyncio
async def test_trigger_invalid_agent(api_client, auth_headers):
    resp = await api_client.post("/api/v1/agents/nonexistent/trigger", headers=auth_headers)
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_agent_status(api_client, auth_headers):
    resp = await api_client.get("/api/v1/agents/status", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 9
