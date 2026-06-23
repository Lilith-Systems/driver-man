import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, patch

from app.config import settings


@pytest.fixture(autouse=True)
def mock_claude_cli():
    import os
    os.environ["CLAUDE_CLI_MOCK"] = "true"
    yield
    os.environ.pop("CLAUDE_CLI_MOCK", None)


@pytest_asyncio.fixture
async def async_db_session():
    from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
    from app.core.database import Base

    engine = create_async_engine("sqlite+aiosqlite://", echo=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as session:
        yield session

    await engine.dispose()


@pytest.fixture
def mock_redis():
    with patch("app.core.events.get_redis", new=AsyncMock()) as mock:
        mock.return_value.publish = AsyncMock()
        yield mock


@pytest.fixture
def mock_chroma():
    with patch("app.core.chroma_client.get_collection") as mock:
        mock.return_value.add = AsyncMock()
        mock.return_value.query = AsyncMock(return_value={
            "documents": [[]], "ids": [[]], "metadatas": [[]], "distances": [[]]
        })
        yield mock


@pytest_asyncio.fixture
async def api_client(async_db_session):
    from app.core.database import get_db
    from app.main import app
    from httpx import AsyncClient, ASGITransport

    async def override_db():
        yield async_db_session

    app.dependency_overrides[get_db] = override_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client

    app.dependency_overrides.clear()


@pytest.fixture
def auth_headers():
    return {"X-API-Key": settings.api_key}
