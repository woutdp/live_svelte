<script>
    /** @type {{big_data_set: any}} */
    let {big_data_set} = $props()
</script>

<h1 class="text-lg">LiveJson demo</h1>
<p class="mb-2">Check the websocket to see how much data is being transferred.</p>

<ul>
    <li>
        Key Length: {Object.keys(big_data_set).length}
    </li>
    <li>
        Rough byte size: {JSON.stringify(big_data_set).length}
    </li>
</ul>

<button phx-click="remove_element" class="bg-black text-white px-4 py-2 rounded">Remove Element</button>
