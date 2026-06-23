import { render, screen } from "@testing-library/react";
import { AgentStatusGrid } from "@/components/dashboard/AgentStatusGrid";

jest.mock("@/hooks/useAgentStatus", () => ({
  useAgentStatus: jest.fn(),
}));

const mockUseAgentStatus = jest.requireMock("@/hooks/useAgentStatus").useAgentStatus;

describe("AgentStatusGrid", () => {
  it("shows loading skeletons", () => {
    mockUseAgentStatus.mockReturnValue({ agents: [], loading: true, error: null });
    const { container } = render(<AgentStatusGrid />);
    expect(container.querySelectorAll(".animate-pulse").length).toBeGreaterThan(0);
  });

  it("renders agent cards", () => {
    mockUseAgentStatus.mockReturnValue({
      agents: [
        { agent_type: "orchestrator", last_run_at: null, last_run_status: null, tasks_today: 5, tasks_total: 100 },
        { agent_type: "finance", last_run_at: null, last_run_status: "completed", tasks_today: 3, tasks_total: 50 },
      ],
      loading: false,
      error: null,
    });
    render(<AgentStatusGrid />);
    expect(screen.getByText("Orchestrator")).toBeInTheDocument();
    expect(screen.getByText("Finance")).toBeInTheDocument();
  });
});
