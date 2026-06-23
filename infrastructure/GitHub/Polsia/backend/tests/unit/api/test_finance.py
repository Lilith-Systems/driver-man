import pytest


@pytest.mark.asyncio
async def test_finance_summary_empty(api_client, auth_headers):
    resp = await api_client.get("/api/v1/finance/summary", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["mrr_cents"] == 0


@pytest.mark.asyncio
async def test_finance_summary_with_data(api_client, async_db_session, auth_headers):
    from datetime import date
    from app.models.finance import RevenueSnapshot
    async_db_session.add(RevenueSnapshot(snapshot_date=date.today(), mrr_cents=50000))
    await async_db_session.flush()

    resp = await api_client.get("/api/v1/finance/summary", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["mrr_cents"] == 50000


@pytest.mark.asyncio
async def test_revenue_list(api_client, async_db_session, auth_headers):
    from datetime import date
    from app.models.finance import RevenueSnapshot
    async_db_session.add_all([
        RevenueSnapshot(snapshot_date=date.today(), mrr_cents=10000),
        RevenueSnapshot(snapshot_date=date(2026, 1, 1), mrr_cents=20000),
    ])
    await async_db_session.flush()

    resp = await api_client.get("/api/v1/finance/revenue", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) >= 2


@pytest.mark.asyncio
async def test_expenses_empty(api_client, auth_headers):
    resp = await api_client.get("/api/v1/finance/expenses", headers=auth_headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
