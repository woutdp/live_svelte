import { describe, it, expect } from "vitest";
// @ts-expect-error - vite_plugin.js is plain JS without type declarations
import { getBaseDir, getComponentName, buildModuleCode } from "./vite_plugin.js";
import path from "node:path";

describe("getBaseDir", () => {
  it("strips wildcard and trailing slash from glob pattern", () => {
    expect(getBaseDir("./svelte/**/*.svelte")).toBe("./svelte");
  });

  it("returns pattern unchanged when no wildcard present", () => {
    expect(getBaseDir("./svelte")).toBe("./svelte");
  });

  it("handles parent-directory relative patterns", () => {
    expect(getBaseDir("../svelte/**/*.svelte")).toBe("../svelte");
  });

  it("handles single-level glob pattern", () => {
    expect(getBaseDir("./svelte/*.svelte")).toBe("./svelte");
  });

  it("handles pattern with trailing slash before wildcard", () => {
    expect(getBaseDir("./components/**/*.svelte")).toBe("./components");
  });
});

describe("getComponentName", () => {
  const base = path.resolve("/project/assets/svelte");

  it("returns filename without extension for top-level components", () => {
    const file = path.resolve("/project/assets/svelte/Counter.svelte");
    expect(getComponentName(file, base)).toBe("Counter");
  });

  it("preserves subdirectory prefix for nested components", () => {
    const file = path.resolve("/project/assets/svelte/forms/ContactForm.svelte");
    expect(getComponentName(file, base)).toBe("forms/ContactForm");
  });

  it("handles deeply nested components", () => {
    const file = path.resolve("/project/assets/svelte/ui/forms/Input.svelte");
    expect(getComponentName(file, base)).toBe("ui/forms/Input");
  });

  it("normalizes backslashes to forward slashes", () => {
    const file = path.resolve("/project/assets/svelte/forms/Form.svelte");
    const result = getComponentName(file, base);
    expect(result).not.toContain("\\");
    expect(result).toBe("forms/Form");
  });

  it("strips .svelte extension correctly", () => {
    const file = path.resolve("/project/assets/svelte/MyComponent.svelte");
    const result = getComponentName(file, base);
    expect(result).toBe("MyComponent");
    expect(result).not.toContain(".svelte");
  });
});

describe("buildModuleCode", () => {
  it("returns an empty default export for an empty file list", () => {
    expect(buildModuleCode([])).toBe("export default {}\n");
  });

  it("generates a single import and export entry for one component", () => {
    const base = path.resolve("/project/assets/svelte");
    const file = path.resolve("/project/assets/svelte/Counter.svelte");
    const code = buildModuleCode([{ file, baseDir: base }]);
    expect(code).toMatch(/^import __c0 from /m);
    expect(code).toContain("Counter.svelte");
    expect(code).toContain('"Counter": __c0');
    expect(code).toContain("export default {");
  });

  it("generates sequential __c0, __c1 imports for multiple components", () => {
    const base = path.resolve("/project/assets/svelte");
    const files = [
      { file: path.resolve("/project/assets/svelte/Counter.svelte"), baseDir: base },
      { file: path.resolve("/project/assets/svelte/forms/Form.svelte"), baseDir: base },
    ];
    const code = buildModuleCode(files);
    expect(code).toMatch(/^import __c0 from /m);
    expect(code).toMatch(/^import __c1 from /m);
    expect(code).toContain('"Counter": __c0');
    expect(code).toContain('"forms/Form": __c1');
  });

  it("uses double-quoted string literals (JSON.stringify) for safe path embedding", () => {
    const base = path.resolve("/project/assets/svelte");
    const file = path.resolve("/project/assets/svelte/Counter.svelte");
    const code = buildModuleCode([{ file, baseDir: base }]);
    // JSON.stringify wraps in double quotes — safe for paths containing single quotes or backslashes
    expect(code).toMatch(/import __c0 from ".*Counter\.svelte"/);
    expect(code).toMatch(/"Counter": __c0/);
  });
});
