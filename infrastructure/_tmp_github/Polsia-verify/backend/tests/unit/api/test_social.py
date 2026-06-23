import pytest


@pytest.mark.asyncio
async def test_social_posts_empty(api_client, auth_headers):
    resp = await api_client.get("/api/v1/social/posts", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_social_posts_with_data(api_client, async_db_session, auth_headers):
    from app.models.social import SocialPost
    async_db_session.add(SocialPost(content="Hello world"))
    await async_db_session.flush()

    resp = await api_client.get("/api/v1/social/posts", headers=auth_headers)
    assert resp.status_code == 200
    posts = resp.json()
    assert len(posts) == 1
    assert posts[0]["content"] == "Hello world"
