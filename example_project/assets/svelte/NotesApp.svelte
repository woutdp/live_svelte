<script>
    import { flip } from "svelte/animate"
    import {fly, fade} from "svelte/transition"

    /**
     * @typedef {Object} Note
     * @property {string} id
     * @property {string} title
     * @property {string|null} content
     * @property {string} color
     * @property {string} inserted_at
     */

    /** @type {{notes: Note[], encoder: string, info: string, live: any}} */
    let {notes: propNotes = [], encoder = "OTP", info = "", live} = $props()

    // Use local reactive state for notes - this helps Svelte track changes for transitions
    let notes = $state([])

    // Sync props to local state using in-place mutations to preserve $state proxy identity.
    // This is critical for animations - replacing the array would cause all items to re-animate.
    $effect(() => {
        const currentIds = new Set(propNotes.map((p) => p.id));

        // 1. Remove deleted items (iterate backwards to avoid index shift issues)
        for (let i = notes.length - 1; i >= 0; i--) {
            if (!currentIds.has(notes[i].id)) {
                notes.splice(i, 1);
            }
        }

        // 2. Update existing items and add new ones in correct order
        for (let i = 0; i < propNotes.length; i++) {
            const p = propNotes[i];
            const existingIndex = notes.findIndex((n) => n.id === p.id);

            if (existingIndex !== -1) {
                // Update existing item in place (no animation triggered)
                notes[existingIndex].title = p.title;
                notes[existingIndex].content = p.content;
                notes[existingIndex].color = p.color;
                notes[existingIndex].inserted_at = p.inserted_at;

                // Move to correct position if needed (triggers flip animation)
                if (existingIndex !== i) {
                    const [item] = notes.splice(existingIndex, 1);
                    notes.splice(i, 0, item);
                }
            } else {
                // Insert new item at correct position (triggers enter animation)
                notes.splice(i, 0, { ...p });
            }
        }
    })

    let title = $state("")
    let content = $state("")
    let color = $state("#fef3c7")

    const colors = [
        {value: "#fef3c7", name: "Amber"},
        {value: "#dcfce7", name: "Green"},
        {value: "#dbeafe", name: "Blue"},
        {value: "#fce7f3", name: "Pink"},
        {value: "#f3e8ff", name: "Purple"},
        {value: "#fff", name: "White"},
    ]

    function handleSubmit() {
        if (!title.trim()) return

        live.pushEvent("create_note", {
            title: title.trim(),
            content: content.trim(),
            color,
        })

        title = ""
        content = ""
        color = "#fef3c7"
    }

    /**
     * @param {string} id
     */
    function handleDelete(id) {
        live.pushEvent("delete_note", {id})
    }

    /**
     * @param {string} uuid
     */
    function truncateUUID(uuid) {
        return uuid ? uuid.substring(0, 8) + "..." : ""
    }

    /**
     * @param {string} dateStr
     */
    function formatDate(dateStr) {
        if (!dateStr) return ""
        const date = new Date(dateStr)
        return date.toLocaleDateString("en-US", {
            month: "short",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
        })
    }
</script>

<svelte:head>
    <title>Notes ({encoder})</title>
</svelte:head>

<div class="max-w-4xl mx-auto p-4">
    <!-- Info Banner -->
    <div class="mb-6 p-4 rounded-lg bg-blue-50 border border-blue-200">
        <div class="flex items-center gap-2 mb-2">
            <span class="px-2 py-1 text-xs font-semibold rounded bg-blue-600 text-white">
                {encoder} JSON Encoder
            </span>
        </div>
        <p class="text-sm text-blue-800">{info}</p>
    </div>

    <!-- Create Note Form -->
    <form
        onsubmit={e => {
            e.preventDefault()
            handleSubmit()
        }}
        class="mb-8 p-4 bg-white rounded-lg shadow-sm border"
    >
        <h2 class="text-lg font-semibold mb-4">Create Note</h2>

        <div class="space-y-4">
            <div>
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Title *</label>
                <input
                    id="title"
                    type="text"
                    bind:value={title}
                    placeholder="Enter note title"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    required
                />
            </div>

            <div>
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea
                    id="content"
                    bind:value={content}
                    placeholder="Enter note content (optional)"
                    rows="3"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                ></textarea>
            </div>

            <div>
                <label for="color" class="block text-sm font-medium text-gray-700 mb-2">Color</label>
                <div class="flex gap-2 flex-wrap">
                    {#each colors as c}
                        <button
                            aria-label={c.name}
                            id="color"
                            type="button"
                            onclick={() => (color = c.value)}
                            class="w-8 h-8 rounded-full border-2 transition-transform hover:scale-110"
                            class:ring-2={color === c.value}
                            class:ring-offset-2={color === c.value}
                            class:ring-blue-500={color === c.value}
                            style="background-color: {c.value}; border-color: {c.value === '#fff' ? '#e5e7eb' : c.value}"
                            title={c.name}
                        ></button>
                    {/each}
                </div>
            </div>

            <button type="submit" class="px-4 py-2 bg-zinc-900 text-white rounded-md hover:bg-zinc-700 transition-colors">
                Add Note
            </button>
        </div>
    </form>

    <!-- Notes Grid 
    in:fly|global={{ x: -200, duration: 300 }}
    out:fade|global={{ duration: 200 }}
     
    -->
    <ul class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {#each notes as note, index (note.id)}
            <li
            animate:flip={{ delay: 500 }}
                role="listitem"
                id={`note-${note.id}`}
                aria-label={`Note ${index + 1}`}
                class="p-4 rounded-lg shadow-sm border transition-shadow hover:shadow-md"
                style="background-color: {note.color}"
            >
                <div class="flex justify-between items-start mb-2">
                    <h3 class="font-semibold text-gray-900 break-words flex-1 mr-2">{note.title}</h3>
                    <button
                        aria-label="Delete note"
                        onclick={() => handleDelete(note.id)}
                        class="text-gray-500 hover:text-red-600 transition-colors p-1"
                        title="Delete note"
                    >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>

                {#if note.content}
                    <p class="text-sm text-gray-700 mb-3 break-words">{note.content}</p>
                {/if}

                <div class="flex justify-between items-center text-xs text-gray-500 pt-2 border-t border-gray-200/50">
                    <span class="font-mono" title={note.id}>ID: {truncateUUID(note.id)}</span>
                    <span>{formatDate(note.inserted_at)}</span>
                </div>
            </li>
        {:else}
            <li class="col-span-full text-center py-12 text-gray-500">
                <p class="text-lg">No notes yet</p>
                <p class="text-sm">Create your first note above!</p>
            </li>
        {/each}
    </ul>

    <!-- Notes Count -->
    {#if notes.length > 0}
        <div class="mt-6 text-center text-sm text-gray-500">
            {notes.length} note{notes.length === 1 ? "" : "s"}
        </div>
    {/if}
</div>
