import pytest


@pytest.mark.asyncio
async def test_create_memory(api_client, auth_headers, mock_chroma):
    resp = await api_client.post(
        "/api/v1/memory",
        json={"category": "strategy", "title": "Test", "content": "Test content"},
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["title"] == "Test"


@pytest.mark.asyncio
async def test_search_memory(api_client, auth_headers):
    resp = await api_client.get("/api/v1/memory?q=test", headers=auth_headers)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_list_memory_empty(api_client, auth_headers):
    resp = await api_client.get("/api/v1/memory", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []
