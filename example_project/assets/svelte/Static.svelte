<script>
  let { color } = $props();
  const colorClass =
    color === "red" ? "text-red-500" : color === "blue" ? "text-blue-500" : "text-base-content/80";
</script>

<div class="card bg-base-100 shadow-lg border border-base-300/50 overflow-hidden w-full">
  <div class="card-body gap-4 p-5">
    <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
      LiveSvelte
    </span>
    <h3 class="font-semibold text-lg text-base-content">Svelte component</h3>
    <p class="text-sm text-base-content/80">
      This svelte component will disappear whenever the "Add Element" button is pressed.
    </p>
    <div class="font-medium {colorClass}">
      {color}
    </div>
  </div>
</div>
