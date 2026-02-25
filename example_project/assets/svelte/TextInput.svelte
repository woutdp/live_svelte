<script lang="ts">
    interface Props {
        value: string
        name: string
        id: string
        [key: string]: unknown
    }

    let {value = $bindable(), name, id, ...rest}: Props = $props()
</script>

<div>
    <input type="text" {name} {id} bind:value {...rest} class="input input-bordered w-full mt-2" />
</div>
