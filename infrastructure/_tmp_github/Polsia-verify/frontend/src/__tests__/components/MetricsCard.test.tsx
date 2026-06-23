import { render, screen } from "@testing-library/react";
import { MetricsCard } from "@/components/dashboard/MetricsCard";

describe("MetricsCard", () => {
  it("renders title and value", () => {
    render(<MetricsCard title="Test" value={42} />);
    expect(screen.getByText("Test")).toBeInTheDocument();
    expect(screen.getByText("42")).toBeInTheDocument();
  });

  it("renders subtitle", () => {
    render(<MetricsCard title="Test" value="100" subtitle="Up 10%" />);
    expect(screen.getByText("Up 10%")).toBeInTheDocument();
  });

  it("renders loading skeleton", () => {
    const { container } = render(<MetricsCard title="Test" value={0} loading />);
    expect(container.querySelector(".animate-pulse")).toBeInTheDocument();
  });
});
