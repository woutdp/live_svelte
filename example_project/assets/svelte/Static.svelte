<script>
  /**
   * @type {{ color: string, index: number }}
   */
  let { color, index } = $props();
  const colorClass = $derived(
    color === "red" ? "text-red-500" : color === "blue" ? "text-blue-500" : "text-base-content/80"
  );
  const borderClass = $derived(
    color === "red" ? "border-red-500" : color === "blue" ? "border-blue-500" : "border-base-content/30"
  );
</script>

<div class="card card-xs bg-base-100 shadow-md border overflow-hidden {borderClass}">
  <div class="card-body gap-4 p-5">
    <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
      LiveSvelte (file based)
    </span>
    <h3 class="font-semibold text-lg text-base-content">Svelte component {index}</h3>
    <p class="text-sm text-base-content/80">
      This svelte component will receive the color from the LiveView and display it.
    </p>
    <div 
    class={colorClass}
    >
      <span class="font-medium italic uppercase" data-testid="static-color-svelte-value">{color}</span>
    </div>
  </div>
</div>
