<script>
  export let number
</script>

<div class="flex flex-col justify-center items-center gap-4 p-4">
  <div class="flex flex-row items-center justify-center gap-10">
    <span class="text-xl">{number}</span>
    <button class="plus" phx-click="increment">+1</button>
  </div>
</div>
