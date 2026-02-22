import { describe, expect, it, vi } from "vitest";

vi.mock("svelte/server", () => {
  return {
    render: vi.fn(() => ({
      head: "<style>.x{}</style>",
      html: "<div>ok</div>",
      body: "<div>ok</div>",
      hashes: { script: [] },
    })),
  };
});

import { getRender } from "./render";

describe("getRender", () => {
  it("wraps Svelte render output into LiveSvelte SSR response shape", () => {
    const Components = {
      default: [{ default: {} }],
      filenames: ["../svelte/Demo.svelte"],
    };

    const r = getRender(Components);
    const out = r("Demo", {}, {});

    expect(out).toEqual({
      head: "<style>.x{}</style>",
      html: "<div>ok</div>",
      css: { code: "", map: "" },
    });
  });
});

