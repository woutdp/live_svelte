/** Input shape from bundler: default = array of { default: Component }, filenames = paths */
export interface ComponentModuleInput {
  default: Array<{ default: unknown }>;
  filenames: string[];
}

/** Map of component name -> Svelte component constructor */
export type NormalizedComponents = Record<string, unknown>;

export function normalizeComponents(
  components: ComponentModuleInput
): NormalizedComponents | ComponentModuleInput {
  if (
    !Array.isArray(components.default) ||
    !Array.isArray(components.filenames)
  ) {
    return components;
  }

  const normalized: NormalizedComponents = {};
  const len = Math.min(components.default.length, components.filenames.length);
  for (let index = 0; index < len; index++) {
    const module = components.default[index];
    const Component = module.default;
    const name = components.filenames[index]
      .replace("../svelte/", "")
      .replace(".svelte", "");
    normalized[name] = Component;
  }
  return normalized;
}

export function decodeB64ToUTF8(b64: string): string {
  const chars = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
  return new TextDecoder().decode(chars);
}
