<script lang="ts">
    import {preventDefault} from "svelte/legacy"

    import TextInput from "./TextInput.svelte"

    let {live} = $props()

    let textInput = "Content"

    function handleForm() {
        live.pushEvent("validate-item", {name: textInput})
    }
</script>

<form onsubmit={preventDefault(handleForm)}>
    <TextInput value={textInput} name="element" id="123456" />
    <button type="submit">Submit</button>
</form>
