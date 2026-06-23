import { render, screen } from "@testing-library/react";
import { ActivityFeed } from "@/components/dashboard/ActivityFeed";

jest.mock("@/hooks/useActivityFeed", () => ({
  useActivityFeed: jest.fn(),
}));

const mockUseActivityFeed = jest.requireMock("@/hooks/useActivityFeed").useActivityFeed;

describe("ActivityFeed", () => {
  it("shows empty state", () => {
    mockUseActivityFeed.mockReturnValue({ events: [], connected: false });
    render(<ActivityFeed />);
    expect(screen.getByText("No recent activity.")).toBeInTheDocument();
  });

  it("shows live status when connected", () => {
    mockUseActivityFeed.mockReturnValue({ events: [], connected: true });
    render(<ActivityFeed />);
    expect(screen.getByText("Live")).toBeInTheDocument();
  });

  it("renders events", () => {
    mockUseActivityFeed.mockReturnValue({
      events: [{ id: 1, agent_type: "test", action: "test", summary: "Test event", level: "info", created_at: new Date().toISOString() }],
      connected: true,
    });
    render(<ActivityFeed />);
    expect(screen.getByText("Test event")).toBeInTheDocument();
  });
});
