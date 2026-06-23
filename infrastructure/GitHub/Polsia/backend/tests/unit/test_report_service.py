from datetime import date
import pytest
from app.services.report_service import get_or_create_daily_report, save_morning_plan, save_evening_summary, get_daily_report


@pytest.mark.asyncio
async def test_get_or_create_daily_report(async_db_session):
    report = await get_or_create_daily_report(async_db_session, date.today())
    assert report.id is not None
    assert report.report_date == date.today()


@pytest.mark.asyncio
async def test_get_or_create_daily_report_idempotent(async_db_session):
    r1 = await get_or_create_daily_report(async_db_session, date.today())
    r2 = await get_or_create_daily_report(async_db_session, date.today())
    assert r1.id == r2.id


@pytest.mark.asyncio
async def test_save_morning_plan(async_db_session):
    report = await save_morning_plan(async_db_session, date.today(), "Plan text", 5)
    assert report.morning_plan == "Plan text"
    assert report.tasks_planned == 5


@pytest.mark.asyncio
async def test_save_evening_summary(async_db_session):
    report = await save_evening_summary(
        async_db_session, date.today(), "Summary", ["insight1"], 3, 1,
    )
    assert report.evening_summary == "Summary"
    assert report.insights == ["insight1"]


@pytest.mark.asyncio
async def test_get_daily_report(async_db_session):
    report = await get_daily_report(async_db_session, date.today())
    assert report is None

    await save_morning_plan(async_db_session, date.today(), "Plan", 3)
    report = await get_daily_report(async_db_session, date.today())
    assert report is not None
