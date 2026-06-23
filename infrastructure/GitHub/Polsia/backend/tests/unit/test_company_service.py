import pytest
from app.services.company_service import get_full_context, build_context_prompt


@pytest.mark.asyncio
async def test_get_full_context_empty(async_db_session):
    ctx = await get_full_context(async_db_session)
    assert ctx == {}


@pytest.mark.asyncio
async def test_get_full_context_with_company(async_db_session):
    from app.models.company import CompanyConfig

    config = CompanyConfig(name="TestCorp", mission="Dominate")
    async_db_session.add(config)
    await async_db_session.flush()

    ctx = await get_full_context(async_db_session)
    assert ctx["company"]["name"] == "TestCorp"
    assert ctx["company"]["mission"] == "Dominate"


def test_build_context_prompt_empty():
    result = build_context_prompt({})
    assert result == "No company context available."


def test_build_context_prompt_with_data():
    context = {
        "company": {"name": "Polsia", "mission": "Automate", "description": "AI platform"},
        "kpis": {"mrr": "$10k"},
    }
    result = build_context_prompt(context)
    assert "Polsia" in result
    assert "$10k" in result
