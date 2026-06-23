import pytest
from app.agents.crew_factory import get_agent, run_agent_for_task


def test_get_agent_returns_correct_type():
    agent = get_agent("orchestrator")
    assert agent.agent_type == "orchestrator"


def test_run_agent_for_task_unknown():
    with pytest.raises(ValueError, match="Unknown agent type"):
        run_agent_for_task("nonexistent", {}, {})
