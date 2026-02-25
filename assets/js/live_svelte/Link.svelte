<script lang="ts">
  import type { Snippet } from "svelte"

  /**
   * A link component that integrates with Phoenix LiveView navigation.
   *
   * - `patch` — patches the current LiveView (calls handle_params)
   * - `navigate` — navigates to a new LiveView process
   * - `href` — plain browser navigation (full page load)
   * - `replace` — use replaceState instead of pushState (for patch/navigate)
   *
   * Phoenix intercepts clicks on <a> tags with `data-phx-link` attributes and
   * performs patch/navigate without a full page reload.
   *
   * @example
   * ```svelte
   * <Link patch="/live-navigation?tab=overview">Overview</Link>
   * <Link navigate="/other-live-view">Go elsewhere</Link>
   * <Link href="/external">External link</Link>
   * ```
   */
  interface Props {
    /** Plain browser navigation — full page load. */
    href?: string
    /** Patch the current LiveView (handle_params is called). */
    patch?: string
    /** Navigate to a new LiveView process. */
    navigate?: string
    /** Use replaceState instead of pushState for patch/navigate. */
    replace?: boolean
    children?: Snippet
    [key: string]: unknown
  }

  let { href, patch, navigate, replace = false, children, ...rest }: Props = $props()

  const phxHref = $derived(navigate ?? patch ?? href ?? "#")
  const phxLink = $derived(navigate ? "redirect" : patch ? "patch" : undefined)
  const phxState = $derived((navigate || patch) ? (replace ? "replace" : "push") : undefined)
</script>

<a href={phxHref} data-phx-link={phxLink} data-phx-link-state={phxState} {...rest}>
  {@render children?.()}
</a>
