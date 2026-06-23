import pytest


@pytest.mark.asyncio
async def test_get_config_not_found(api_client, auth_headers):
    resp = await api_client.get("/api/v1/config", headers=auth_headers)
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_get_config(api_client, async_db_session, auth_headers):
    from app.models.company import CompanyConfig
    async_db_session.add(CompanyConfig(name="TestCorp"))
    await async_db_session.flush()

    resp = await api_client.get("/api/v1/config", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["name"] == "TestCorp"


@pytest.mark.asyncio
async def test_update_config(api_client, async_db_session, auth_headers):
    from app.models.company import CompanyConfig
    async_db_session.add(CompanyConfig(name="OldName"))
    await async_db_session.flush()

    resp = await api_client.put("/api/v1/config", json={"name": "NewName"}, headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["name"] == "NewName"


@pytest.mark.asyncio
async def test_config_auth_required(api_client):
    resp = await api_client.get("/api/v1/config")
    assert resp.status_code == 401
