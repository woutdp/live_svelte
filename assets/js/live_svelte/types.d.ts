/**
 * Public API type definitions for LiveSvelte.
 * No `any` in public API; consumers get type safety and exported types.
 */

/** LiveView socket/channel push and event types (payloads from server are unknown) */
export type Live = {
  pushEvent(
    event: string,
    payload?: object,
    onReply?: (reply: unknown, ref: number) => void
  ): number;
  pushEventTo(
    phxTarget: unknown,
    event: string,
    payload?: object,
    onReply?: (reply: unknown, ref: number) => void
  ): number;

  handleEvent(event: string, callback: (payload: unknown) => void): () => void;
  removeHandleEvent(callbackRef: () => void): void;

  upload(name: string, files: FileList | File[]): void;
  uploadTo(phxTarget: unknown, name: string, files: FileList | File[]): void;
};

/** Component module input: default = modules, filenames = paths */
export interface ComponentModuleInput {
  default: Array<{ default: unknown }>;
  filenames: string[];
}

/** Result of getHooks: SvelteHook for LiveView hooks */
export interface SvelteHooksResult {
  SvelteHook: {
    mounted(this: { el: HTMLElement; _instance?: { state: Record<string, unknown> } }): void;
    updated(this: { el: HTMLElement; _instance?: { state: Record<string, unknown> } }): void;
    destroyed(this: { el: HTMLElement; _instance?: { state: Record<string, unknown> } }): void;
  };
}

/** Render function returned by getRender */
export type LiveSvelteRenderFn = (
  name: string,
  props: Record<string, unknown>,
  slots: Record<string, string>
) => {
  head: string;
  html: string;
  css: {
    code: string;
    map: string;
  };
};

export declare const getHooks: (components: ComponentModuleInput) => SvelteHooksResult;
export declare const getRender: (
  components: ComponentModuleInput
) => LiveSvelteRenderFn;
