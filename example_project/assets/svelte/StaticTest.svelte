<script>
    let { color, index } = $props();
    console.log(color);
</script>

<div
    class:bg-white={color === "white"}
    class:border-[var(--color-brand)]={color === "white"}
    class:border-red-500={color === "red"}
    class:bg-red-500={color === "red"}
    class:text-white={color === "red"}
    class="flex flex-col justify-center items-center p-4 w-100 border-1 rounded-md shadow-lg"
>
    <div class="font-bold p-1 text-lg">{index}</div>
    <div class="font-bold p-1 text-lg">Svelte component</div>
</div>
