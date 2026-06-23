import pytest
from app.services.memory_service import store_memory, search_memory, list_memories


@pytest.mark.asyncio
async def test_store_memory(async_db_session, mock_chroma):
    entry = await store_memory(
        async_db_session, category="strategy", title="Test", content="Test content",
    )
    assert entry.id is not None
    assert entry.category == "strategy"


@pytest.mark.asyncio
async def test_search_memory(async_db_session, mock_chroma):
    results = await search_memory(async_db_session, "test query")
    assert isinstance(results, list)


@pytest.mark.asyncio
async def test_list_memories(async_db_session, mock_chroma):
    await store_memory(async_db_session, category="learning", title="Learn", content="Stuff")
    memories = await list_memories(async_db_session)
    assert len(memories) >= 1
