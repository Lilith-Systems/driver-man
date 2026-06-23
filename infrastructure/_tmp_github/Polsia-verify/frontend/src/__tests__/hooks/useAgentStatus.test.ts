import { renderHook, act } from "@testing-library/react";
import { useAgentStatus } from "@/hooks/useAgentStatus";

jest.mock("@/lib/api", () => ({
  api: {
    get: jest.fn(),
  },
}));

const mockApiGet = jest.requireMock("@/lib/api").api.get;

describe("useAgentStatus", () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it("starts in loading state", () => {
    mockApiGet.mockResolvedValue([]);
    const { result } = renderHook(() => useAgentStatus(10000));
    expect(result.current.loading).toBe(true);
  });

  it("fetches on mount", async () => {
    mockApiGet.mockResolvedValue([{ agent_type: "test", last_run_at: null, last_run_status: null, tasks_today: 0, tasks_total: 0 }]);

    const { result } = renderHook(() => useAgentStatus(10000));

    await act(async () => {
      await Promise.resolve();
    });

    expect(result.current.loading).toBe(false);
    expect(result.current.agents).toHaveLength(1);
  });

  it("polls at interval", async () => {
    mockApiGet.mockResolvedValue([]);
    renderHook(() => useAgentStatus(10000));

    expect(mockApiGet).toHaveBeenCalledTimes(1);

    await act(async () => {
      jest.advanceTimersByTime(10000);
    });

    expect(mockApiGet).toHaveBeenCalledTimes(2);
  });
});
