import json
import pytest
from app.agents.base_agent import BasePolsiaAgent


class ConcreteAgent(BasePolsiaAgent):
    agent_type = "test"
    def run(self, task, context):
        return {"status": "ok"}


def test_mock_call_claude():
    agent = ConcreteAgent()
    result = agent.call_claude("test prompt")
    assert "summary" in result
    assert "Mock generation" in result


def test_call_claude_json():
    import os
    os.environ["CLAUDE_CLI_MOCK_RESPONSE"] = '{"result": "{\\"key\\": \\"value\\"}"}'
    agent = ConcreteAgent()
    result = agent.call_claude_json("test prompt")
    assert result == {"key": "value"}
    del os.environ["CLAUDE_CLI_MOCK_RESPONSE"]


def test_timed_run_adds_duration():
    agent = ConcreteAgent()
    result = agent.timed_run({"key": "val"}, {"ctx": "data"})
    assert result["status"] == "ok"
    assert "duration_secs" in result
    assert result["duration_secs"] >= 0
