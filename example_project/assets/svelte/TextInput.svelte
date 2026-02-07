<script lang="ts">
    interface Props {
        value: string
        name: string
        id: string
    }

    let {value = $bindable(), name, id}: Props = $props()
</script>

<div>
    <input
        type="text"
        {name}
        {id}
        bind:value
        class="input input-bordered w-full mt-2"
    />
</div>
