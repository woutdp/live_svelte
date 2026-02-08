<script>
  let { color } = $props();
  const colorClass = $derived(
    color === "red" ? "text-red-500" : color === "blue" ? "text-blue-500" : "text-base-content/80"
  );
  const borderClass = $derived(
    color === "red" ? "border-red-500" : color === "blue" ? "border-blue-500" : "border-base-content/30"
  );
</script>

<div class="card bg-base-100 shadow-md border overflow-hidden w-full max-w-xs md:min-w-md {borderClass}">
  <div class="card-body gap-4 p-5">
    <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
      LiveSvelte
    </span>
    <h3 class="font-semibold text-lg text-base-content">Svelte component</h3>
    <p class="text-sm text-base-content/80">
      This svelte component will receive the color from the LiveView and display it.
    </p>
    <div 
    class={colorClass}
    >
      <span class="font-medium italic">{color}</span>
    </div>
  </div>
</div>
