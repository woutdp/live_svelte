<script>
    import {flip} from "svelte/animate"
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
        const currentIds = new Set(propNotes.map(p => p.id))

        // 1. Remove deleted items (iterate backwards to avoid index shift issues)
        for (let i = notes.length - 1; i >= 0; i--) {
            if (!currentIds.has(notes[i].id)) {
                notes.splice(i, 1)
            }
        }

        // 2. Update existing items and add new ones in correct order
        for (let i = 0; i < propNotes.length; i++) {
            const p = propNotes[i]
            const existingIndex = notes.findIndex(n => n.id === p.id)

            if (existingIndex !== -1) {
                // Update existing item in place (no animation triggered)
                notes[existingIndex].title = p.title
                notes[existingIndex].content = p.content
                notes[existingIndex].color = p.color
                notes[existingIndex].inserted_at = p.inserted_at

                // Move to correct position if needed (triggers flip animation)
                if (existingIndex !== i) {
                    const [item] = notes.splice(existingIndex, 1)
                    notes.splice(i, 0, item)
                }
            } else {
                // Insert new item at correct position (triggers enter animation)
                notes.splice(i, 0, {...p})
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

<div class="w-full max-w-4xl mx-auto">
    <!-- Info -->
    <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden mb-6">
        <div class="card-body gap-2 p-4">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
                {encoder} JSON encoder
            </span>
            <p class="text-sm text-base-content/70">{info}</p>
        </div>
    </div>

    <!-- Create Note Form -->
    <form
        onsubmit={e => {
            e.preventDefault()
            handleSubmit()
        }}
        class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden mb-8"
    >
        <div class="card-body gap-4 p-5">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit"> Create note </span>

            <label for="title" class="flex flex-col gap-1.5">
                <span class="text-xs font-medium text-base-content/50">Title *</span>
                <input
                    id="title"
                    type="text"
                    bind:value={title}
                    placeholder="Enter note title"
                    class="input input-bordered input-sm w-full bg-base-200/50 border-base-300"
                    required
                />
            </label>

            <label for="content" class="flex flex-col gap-1.5">
                <span class="text-xs font-medium text-base-content/50">Content</span>
                <textarea
                    id="content"
                    bind:value={content}
                    placeholder="Enter note content (optional)"
                    rows="3"
                    class="textarea textarea-bordered textarea-sm w-full bg-base-200/50 border-base-300"
                ></textarea>
            </label>

            <div class="flex flex-col gap-2">
                <span class="text-xs font-medium text-base-content/50">Color</span>
                <div class="flex gap-2 flex-wrap">
                    {#each colors as c}
                        <button
                            aria-label={c.name}
                            type="button"
                            onclick={() => (color = c.value)}
                            class="w-8 h-8 rounded-full border-2 transition-transform hover:scale-110"
                            class:ring-2={color === c.value}
                            class:ring-offset-2={color === c.value}
                            class:ring-brand={color === c.value}
                            style="background-color: {c.value}; border-color: {c.value === '#fff' ? 'var(--color-base-300)' : c.value}"
                            title={c.name}
                        ></button>
                    {/each}
                </div>
            </div>

            <button type="submit" class="btn btn-sm bg-brand text-white border-0 hover:opacity-90 w-fit"> Add note </button>
        </div>
    </form>

    <!-- Notes Grid -->
    <ul class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {#each notes as note, index (note.id)}
            <li
                animate:flip={{delay: 100, duration: 500}}
                role="listitem"
                id={`note-${note.id}`}
                aria-label={`Note ${index + 1}`}
                class="rounded-lg border border-base-300/50 p-4 transition-shadow hover:shadow-md"
                style="background-color: {note.color}"
            >
                <div class="flex justify-between items-start gap-2 mb-2">
                    <h3 class="font-semibold text-base-content break-words flex-1 min-w-0">{note.title}</h3>
                    <button
                        aria-label="Delete note"
                        onclick={() => handleDelete(note.id)}
                        class="btn btn-ghost btn-xs hover:bg-error/20 hover:text-error shrink-0"
                        title="Delete note"
                    >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>

                {#if note.content}
                    <p class="text-sm text-base-content/70 mb-3 break-words">{note.content}</p>
                {/if}

                <div class="flex justify-between items-center text-xs text-base-content/50 pt-2 border-t border-base-300/50">
                    <span class="font-mono truncate" title={note.id}>ID: {truncateUUID(note.id)}</span>
                    <span class="shrink-0">{formatDate(note.inserted_at)}</span>
                </div>
            </li>
        {:else}
            <li class="col-span-full">
                <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden">
                    <div class="card-body py-12 text-center">
                        <p class="text-base-content/70 font-medium">No notes yet</p>
                        <p class="text-sm text-base-content/50">Create your first note above.</p>
                    </div>
                </div>
            </li>
        {/each}
    </ul>

    {#if notes.length > 0}
        <div class="mt-6 text-center">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/50">
                {notes.length} note{notes.length === 1 ? "" : "s"}
            </span>
        </div>
    {/if}
</div>
