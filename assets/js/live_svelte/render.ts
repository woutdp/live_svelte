import type { ComponentModuleInput, NormalizedComponents } from "./utils";
import { normalizeComponents } from "./utils";
import { render } from "svelte/server";
import { createRawSnippet } from "svelte";

export type SSRRenderResponse = {
  head: string;
  html: string;
  css: {
    code: string;
    map: string;
  };
};

export function getRender(
  components: ComponentModuleInput
): (
  name: string,
  props: Record<string, unknown>,
  slots: Record<string, string>
) => SSRRenderResponse {
  const normalized = normalizeComponents(components) as NormalizedComponents;

  return function r(
    name: string,
    props: Record<string, unknown>,
    slots: Record<string, string>
  ): SSRRenderResponse {
    const snippets = Object.fromEntries(
      Object.entries(slots).map(([slotName, v]) => {
        const snippet = createRawSnippet(() => ({
          render: () => v,
        }));
        if (slotName === "default") return ["children", snippet];
        return [slotName, snippet];
      })
    );

    const Component = normalized[name];
    if (!Component) {
      throw new Error(`Unknown component: ${name}`);
    }
    const output = render(Component as import("svelte").Component, {
      props: { ...props, ...snippets },
    });

    // LiveSvelte's Elixir SSR pipeline expects `%{"head" => ..., "html" => ..., "css" => %{"code" => ..., "map" => ...}}`.
    // Svelte 5's `render()` returns `{ head, html/body, hashes }` with CSS already in `head`.
    // We provide an empty css payload to keep the Elixir consumer stable.
    const sync = output as { head: string; html: string };
    return {
      head: sync.head,
      html: sync.html,
      css: { code: "", map: "" },
    };
  };
}
