import pytest


@pytest.mark.asyncio
async def test_dashboard_summary(api_client, auth_headers):
    resp = await api_client.get("/api/v1/dashboard/summary", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "tasks_today_total" in data


@pytest.mark.asyncio
async def test_dashboard_activity(api_client, auth_headers):
    resp = await api_client.get("/api/v1/dashboard/activity", headers=auth_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


@pytest.mark.asyncio
async def test_health(api_client, auth_headers):
    resp = await api_client.get("/api/v1/health", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
