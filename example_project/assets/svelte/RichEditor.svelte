<script lang="ts">
    import type {Attachment} from "svelte/attachments"

    let {initialContent = {blocks: []}, live} = $props()

    // Plain const snapshot — not reactive, so the attachment only runs once on mount
    // and the editor isn't re-created when the server echoes back saved content.
    const initialData = JSON.parse(JSON.stringify(initialContent))

    let isSyncing = $state(false)
    let syncedBlocks = $state<number | null>(null)
    let editorSync: (() => Promise<void>) | null = null

    const editorAttachment: Attachment<HTMLElement> = element => {
        let editor: any = null

        ;(async () => {
            const {default: EditorJS} = await import("@editorjs/editorjs")
            const {default: Header} = await import("@editorjs/header")
            const {default: List} = await import("@editorjs/list")

            editor = new EditorJS({
                holder: element,
                tools: {
                    header: {class: Header, config: {levels: [2, 3], defaultLevel: 2}},
                    list: {class: List, inlineToolbar: true},
                },
                data: initialData,
                placeholder: "Start writing...",
            })

            editorSync = async () => {
                isSyncing = true
                try {
                    await editor.isReady
                    const data = await editor.save()
                    live.pushEvent("sync_content", data)
                    syncedBlocks = data.blocks.length
                } finally {
                    isSyncing = false
                }
            }
        })()

        return () => {
            editorSync = null
            editor?.destroy()
        }
    }
</script>

<div>
    <div
        {@attach editorAttachment}
        data-testid="editor-container"
        class="min-h-[200px] border border-base-300 rounded-lg bg-base-50 px-4 py-3 text-sm [&_.codex-editor\_\_redactor]:pb-0"
    ></div>
    <div class="flex justify-between items-center mt-4">
        {#if syncedBlocks !== null}
            <span data-testid="editor-saved-blocks" class="text-sm text-success">
                {syncedBlocks} block{syncedBlocks === 1 ? "" : "s"} saved locally
            </span>
        {:else}
            <span></span>
        {/if}
        <button data-testid="editor-save-btn" onclick={() => editorSync?.()} disabled={isSyncing} class="btn bg-brand text-white btn-sm">
            {isSyncing ? "Syncing..." : "Sync with server"}
        </button>
    </div>
</div>
