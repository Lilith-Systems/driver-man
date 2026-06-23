import pytest
import pytest_asyncio
from unittest.mock import patch


@pytest.mark.integration
@pytest_asyncio.fixture(scope="session")
async def integration_db():
    from testcontainers.postgres import PostgresContainer
    from sqlalchemy.ext.asyncio import create_async_engine
    from app.core.database import Base

    with PostgresContainer("postgres:16-alpine") as postgres:
        db_url = postgres.get_connection_url().replace("psycopg2", "asyncpg")
        engine = create_async_engine(db_url)
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        yield db_url
        await engine.dispose()


@pytest.mark.integration
@pytest_asyncio.fixture
async def db(integration_db):
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

    engine = create_async_engine(integration_db)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as session:
        yield session
    await engine.dispose()


@pytest.mark.integration
@pytest_asyncio.fixture
async def int_client(integration_db):
    from app.main import app
    from app.core.database import get_db
    from httpx import AsyncClient, ASGITransport
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

    engine = create_async_engine(integration_db)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async def override_db():
        async with Session() as session:
            yield session

    app.dependency_overrides[get_db] = override_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client

    app.dependency_overrides.clear()
    await engine.dispose()
