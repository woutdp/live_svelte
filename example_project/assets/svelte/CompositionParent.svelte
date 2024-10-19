<script lang="ts">
    import TextInput from "./TextInput.svelte";
    
    export let live;

    let textInput = "Content";

    function handleForm() {
        live.pushEvent("validate-item", { name: textInput });
    }
</script>

<form on:submit|preventDefault={handleForm}>
    <TextInput value={textInput} name="element" id="123456" />
    <button type="submit">Submit</button>
</form>

