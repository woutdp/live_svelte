<script>
    import { useLiveNavigation, Link } from "live_svelte"

    /** @type {{ page: string, query: Record<string, string> }} */
    let { page, query } = $props()

    const { patch, navigate } = useLiveNavigation()
</script>

<div class="card bg-base-100 shadow-md border border-base-300/50 p-6 max-w-md">
    <div class="mb-4 space-y-1">
        <p class="text-sm">
            Current page: <span data-testid="nav-page" class="font-mono font-semibold">{page}</span>
        </p>
        <p class="text-sm">
            Query params: <span data-testid="nav-query" class="font-mono font-semibold">{JSON.stringify(query)}</span>
        </p>
    </div>

    <div class="flex flex-wrap gap-2">
        <button
            data-testid="patch-btn"
            class="btn btn-sm bg-brand text-white border-0 hover:opacity-90"
            onclick={() => patch({ section: "details", from: page })}
        >
            Patch query params
        </button>

        <button
            data-testid="navigate-btn"
            class="btn btn-sm btn-secondary"
            onclick={() => navigate(page === "home" ? "/live-navigation/other" : "/live-navigation")}
        >
            Navigate to {page === "home" ? "other" : "home"}
        </button>

        <Link
            data-testid="link-patch"
            patch="/live-navigation?tab=overview"
            class="btn btn-sm btn-outline"
        >
            Link patch
        </Link>

        <Link
            data-testid="link-navigate"
            navigate="/live-navigation/linked"
            class="btn btn-sm btn-ghost"
        >
            Link navigate
        </Link>
    </div>
</div>
