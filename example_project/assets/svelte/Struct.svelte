<script>
    let {struct} = $props()
</script>

<div class="flex flex-col gap-2">
    {JSON.stringify(struct)}
    <button phx-click="randomize" class="bg-black text-white rounded p-2">Randomize Age</button>
</div>
