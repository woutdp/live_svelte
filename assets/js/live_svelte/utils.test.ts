import { describe, it, expect } from "vitest";
import { decodeB64ToUTF8, normalizeComponents } from "./utils";

describe("decodeB64ToUTF8", () => {
  it("decodes base64 string to UTF-8", () => {
    expect(decodeB64ToUTF8("aGVsbG8=")).toBe("hello");
  });

  it("decodes empty base64 to empty string", () => {
    expect(decodeB64ToUTF8("")).toBe("");
  });

  it("decodes Unicode correctly", () => {
    expect(decodeB64ToUTF8("Y2Fmw6k=")).toBe("café");
  });

  it("throws on invalid base64 input", () => {
    expect(() => decodeB64ToUTF8("!!!")).toThrow();
  });
});

describe("normalizeComponents", () => {
  it("returns input unchanged when default is not an array", () => {
    const input = { default: null, filenames: [] } as unknown as Parameters<
      typeof normalizeComponents
    >[0];
    expect(normalizeComponents(input)).toBe(input);
  });

  it("returns input unchanged when filenames is not an array", () => {
    const input = { default: [], filenames: null } as unknown as Parameters<
      typeof normalizeComponents
    >[0];
    expect(normalizeComponents(input)).toBe(input);
  });

  it("normalizes component map from default and filenames arrays", () => {
    const ComponentA = {};
    const ComponentB = {};
    const components = {
      default: [{ default: ComponentA }, { default: ComponentB }],
      filenames: ["../svelte/Counter.svelte", "../svelte/Button.svelte"],
    };
    const result = normalizeComponents(components);
    expect(result).toEqual({
      Counter: ComponentA,
      Button: ComponentB,
    });
  });

  it("handles filenames shorter than default (only normalizes up to filenames length)", () => {
    const ComponentA = {};
    const components = {
      default: [{ default: ComponentA }, { default: {} }],
      filenames: ["../svelte/OnlyOne.svelte"],
    };
    const result = normalizeComponents(components);
    expect(result).toEqual({ OnlyOne: ComponentA });
  });
});
