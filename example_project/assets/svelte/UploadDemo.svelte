<script lang="ts">
    import {useLiveUpload} from "live_svelte"
    import type {UploadConfig} from "live_svelte"

    interface Props {
        uploads: {test_files: UploadConfig}
        uploaded_files: {name: string; size: number}[]
    }

    let {uploads, uploaded_files}: Props = $props()

    const upload = useLiveUpload(uploads.test_files, {
        changeEvent: "validate",
        submitEvent: "save",
    })

    // Sync server-side upload config updates into the composable.
    $effect(() => {
        upload.sync(uploads.test_files)
    })

    // Reactive store aliases for template use.
    const entries = upload.entries
    const progress = upload.progress
    const valid = upload.valid
</script>

<div
    data-testid="upload-container"
    class="w-full max-w-md mx-auto card bg-base-100 shadow-md border border-base-300/50"
>
    <div class="card-body gap-4 p-5">
        <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
            File Upload
        </span>

        <!-- File picker and drag-drop zone -->
        <div
            data-testid="drop-zone"
            role="region"
            aria-label="File drop zone"
            class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center hover:border-brand/50 transition-colors"
            ondragover={(e) => e.preventDefault()}
            ondrop={(e) => {
                e.preventDefault()
                if (e.dataTransfer) upload.addFiles(e.dataTransfer)
            }}
        >
            <p class="text-sm text-base-content/50 mb-3">Drag and drop files here, or</p>
            <button
                data-testid="pick-files-btn"
                type="button"
                class="btn btn-sm bg-brand text-white border-0 hover:opacity-90"
                onclick={() => upload.showFilePicker()}
            >
                Select Files
            </button>
            <p class="text-xs text-base-content/40 mt-2">
                Accepts .txt, .pdf, .jpg, .png — max 5 MB each, up to 3 files
            </p>
        </div>

        <!-- Entry list -->
        {#if $entries.length > 0}
            <ul class="flex flex-col gap-2">
                {#each $entries as entry (entry.ref)}
                    <li data-testid="upload-entry" class="flex items-center gap-3 text-sm">
                        <div class="flex-1 min-w-0">
                            <span data-testid="entry-name" class="font-medium truncate block">
                                {entry.client_name}
                            </span>
                            <span class="text-xs text-base-content/50">
                                {(entry.client_size / 1024).toFixed(1)} KB
                            </span>
                        </div>
                        <div class="flex items-center gap-2 shrink-0">
                            <span data-testid="entry-progress" class="text-xs w-8 text-right">
                                {entry.progress}%
                            </span>
                            {#if !entry.valid}
                                <span data-testid="entry-error" class="text-xs text-error">
                                    {entry.errors[0] ?? "invalid"}
                                </span>
                            {/if}
                            <button
                                data-testid="cancel-entry-btn"
                                type="button"
                                class="btn btn-xs btn-ghost text-error"
                                onclick={() => upload.cancel(entry.ref)}
                            >
                                ✕
                            </button>
                        </div>
                    </li>
                {/each}
            </ul>

            <!-- Overall progress bar -->
            {#if $progress > 0 && $progress < 100}
                <div class="w-full bg-base-200 rounded-full h-1.5">
                    <div
                        data-testid="progress-bar"
                        class="bg-brand h-1.5 rounded-full transition-all"
                        style="width: {$progress}%"
                    ></div>
                </div>
            {/if}

            <!-- Action buttons -->
            <div class="flex gap-2">
                {#if !uploads.test_files.auto_upload}
                    <button
                        data-testid="upload-submit-btn"
                        type="button"
                        class="btn btn-sm bg-brand text-white border-0 hover:opacity-90"
                        disabled={!$valid}
                        onclick={() => upload.submit()}
                    >
                        Upload
                    </button>
                {/if}
                <button
                    data-testid="cancel-all-btn"
                    type="button"
                    class="btn btn-sm btn-ghost"
                    onclick={() => upload.cancel()}
                >
                    Cancel All
                </button>
            </div>
        {/if}

        <!-- Uploaded files list -->
        {#if uploaded_files.length > 0}
            <div>
                <h3 class="text-xs font-medium text-base-content/50 uppercase tracking-wide mb-2">
                    Uploaded
                </h3>
                <ul class="flex flex-col gap-1">
                    {#each uploaded_files as file}
                        <li data-testid="uploaded-file" class="flex items-center gap-2 text-sm">
                            <span class="text-success">✓</span>
                            <span data-testid="uploaded-name">{file.name}</span>
                            <span class="text-xs text-base-content/40 ml-auto">
                                {(file.size / 1024).toFixed(1)} KB
                            </span>
                        </li>
                    {/each}
                </ul>
            </div>
        {/if}
    </div>
</div>
