import { fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it } from "vitest";
import App from "./App";

const routes = [
  "/de", "/de/installation", "/de/features", "/de/architecture", "/de/security", "/de/troubleshooting", "/de/downloads",
  "/en", "/en/installation", "/en/features", "/en/architecture", "/en/security", "/en/troubleshooting", "/en/downloads"
];

describe("documentation site", () => {
  it("renders the German overview and download", () => {
    render(<MemoryRouter initialEntries={["/de"]}><App/></MemoryRouter>);
    expect(screen.getByRole("heading", { name: "Öffentliche TikTok-LIVE-Streams zugänglicher nutzen" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Version 0.5.0 herunterladen/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-extension-0.5.0.zip");
  });

  it("opens keyboard search and lists English architecture", () => {
    render(<MemoryRouter initialEntries={["/en"]}><App/></MemoryRouter>);
    fireEvent.keyDown(window, { key: "k", ctrlKey: true });
    expect(screen.getByRole("dialog", { name: "Search documentation" })).toBeInTheDocument();
    fireEvent.change(screen.getByPlaceholderText("Enter a title or topic"), { target: { value: "WebSocket" } });
    expect(screen.getByRole("button", { name: /Architecture/ })).toBeInTheDocument();
  });

  it("switches feature tabs", () => {
    render(<MemoryRouter initialEntries={["/de/features"]}><App/></MemoryRouter>);
    fireEvent.click(screen.getByRole("tab", { name: /Untertitel/ }));
    expect(screen.getByRole("heading", { name: "Untertitel" })).toBeInTheDocument();
  });

  it.each(routes)("renders route %s", (route) => {
    const { container } = render(<MemoryRouter initialEntries={[route]}><App/></MemoryRouter>);
    expect(container.querySelector("main h1, .hero h1")).toBeInTheDocument();
    expect(screen.getByText(/Not affiliated|Nicht mit TikTok verbunden/)).toBeInTheDocument();
  });

  it("keeps the current page when switching languages", () => {
    render(<MemoryRouter initialEntries={["/de/security"]}><App/></MemoryRouter>);
    expect(screen.getByRole("link", { name: "Sprache: EN" })).toHaveAttribute("href", "/en/security");
  });

  it("exposes both release downloads and the checksum action", () => {
    render(<MemoryRouter initialEntries={["/en/downloads"]}><App/></MemoryRouter>);
    expect(screen.getByRole("link", { name: /Extension ZIP/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-extension-0.5.0.zip");
    expect(screen.getByRole("link", { name: /Codex plugin ZIP/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-plugin-0.5.0.zip");
    expect(screen.getByRole("button", { name: "Copy checksums" })).toBeInTheDocument();
  });

  it("provides an accessible text alternative for the architecture", () => {
    render(<MemoryRouter initialEntries={["/en/architecture"]}><App/></MemoryRouter>);
    expect(screen.getByRole("heading", { name: "TikTok LIVE tab" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "WebSocket hook" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Side panel" })).toBeInTheDocument();
  });

  it("provides a focusable skip-link target", () => {
    const { container } = render(<MemoryRouter initialEntries={["/de"]}><App/></MemoryRouter>);
    expect(screen.getByRole("link", { name: "Zum Inhalt springen" })).toHaveAttribute("href", "#main-content");
    expect(container.querySelector("#main-content")).toHaveAttribute("tabindex", "-1");
  });
});
