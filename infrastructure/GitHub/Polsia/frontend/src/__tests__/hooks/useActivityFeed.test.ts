import { renderHook, act } from "@testing-library/react";
import { useActivityFeed } from "@/hooks/useActivityFeed";

describe("useActivityFeed", () => {
  let mockWs: any;

  beforeEach(() => {
    mockWs = {
      onopen: null,
      onmessage: null,
      onclose: null,
      onerror: null,
      close: jest.fn(),
    };
    global.WebSocket = jest.fn(() => mockWs) as any;
  });

  it("connects on mount", () => {
    renderHook(() => useActivityFeed());
    expect(global.WebSocket).toHaveBeenCalled();
  });

  it("handles incoming events", () => {
    const { result } = renderHook(() => useActivityFeed());

    act(() => {
      mockWs.onopen();
    });

    act(() => {
      mockWs.onmessage({ data: JSON.stringify({ id: 1, agent_type: "test", action: "test", summary: "Test", level: "info", created_at: new Date().toISOString() }) });
    });

    expect(result.current.events).toHaveLength(1);
    expect(result.current.events[0].summary).toBe("Test");
  });

  it("handles disconnect", () => {
    const { result } = renderHook(() => useActivityFeed());

    act(() => {
      mockWs.onclose();
    });

    expect(result.current.connected).toBe(false);
  });
});
