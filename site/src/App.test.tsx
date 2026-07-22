import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { afterEach, describe, expect, it } from "vitest";
import App from "./App";

afterEach(cleanup);

const routes = [
  "/de", "/de/installation", "/de/features", "/de/architecture", "/de/security", "/de/troubleshooting", "/de/downloads",
  "/en", "/en/installation", "/en/features", "/en/architecture", "/en/security", "/en/troubleshooting", "/en/downloads"
];

describe("documentation site", () => {
  it("renders the German overview and download", () => {
    render(<MemoryRouter initialEntries={["/de"]}><App/></MemoryRouter>);
    expect(screen.getByRole("heading", { name: "Öffentliche TikTok-LIVE-Streams zugänglicher nutzen" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Version 0.7.1 herunterladen/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-extension-0.7.1.zip");
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

  it("exposes all release downloads and the checksum action", () => {
    render(<MemoryRouter initialEntries={["/en/downloads"]}><App/></MemoryRouter>);
    expect(screen.getByRole("link", { name: /Extension ZIP/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-extension-0.7.1.zip");
    expect(screen.getByRole("link", { name: /Codex plugin ZIP/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-plugin-0.7.0.zip");
    expect(screen.getByRole("link", { name: /Windows service ZIP/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-service-0.7.0.zip");
    expect(screen.getByRole("link", { name: /iOS source project/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-ios-0.7.0-source.zip");
    expect(screen.getByRole("link", { name: /Android\/HyperOS source/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-android-0.7.0-source.zip");
    expect(screen.getByRole("link", { name: /Android test APK/ })).toHaveAttribute("href", "/downloads/tiktok-live-companion-android-0.7.0-debug.apk");
    expect(screen.getByRole("button", { name: "Copy checksums" })).toBeInTheDocument();
  });

  it("documents the browser and native recognition split", () => {
    render(<MemoryRouter initialEntries={["/en"]}><App/></MemoryRouter>);
    expect(screen.getAllByText(/AudD/).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/ShazamKit/).length).toBeGreaterThan(0);
    expect(screen.getByText("Android & HyperOS")).toBeInTheDocument();
  });

  it("provides an accessible text alternative for the architecture", () => {
    render(<MemoryRouter initialEntries={["/en/architecture"]}><App/></MemoryRouter>);
    expect(screen.getByRole("heading", { name: "TikTok LIVE tab" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "WebSocket hook" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Side panel" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Open 3D view" })).toHaveAttribute("href", "/en/architecture-3d");
  });

  it("opens the project-specific Three.js architecture route", async () => {
    render(<MemoryRouter initialEntries={["/de/architecture-3d"]}><App/></MemoryRouter>);
    expect(await screen.findByRole("heading", { name: "Interaktive Plattformarchitektur" })).toBeInTheDocument();
    expect(screen.getByText(/demselben reproduzierbaren Projektmodell/)).toBeInTheDocument();
    expect(document.querySelector('[src*="mcp-flow"], [href*="mcp-flow"]')).not.toBeInTheDocument();
  });

  it("provides a focusable skip-link target", () => {
    const { container } = render(<MemoryRouter initialEntries={["/de"]}><App/></MemoryRouter>);
    expect(screen.getByRole("link", { name: "Zum Inhalt springen" })).toHaveAttribute("href", "#main-content");
    expect(container.querySelector("#main-content")).toHaveAttribute("tabindex", "-1");
  });
});
