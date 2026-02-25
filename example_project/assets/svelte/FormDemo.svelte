<script lang="ts">
    import {useLiveForm} from "live_svelte"
    import type {Form} from "live_svelte"

    interface Props {
        form: Form<{name: string; email: string}>
    }

    let {form: serverForm}: Props = $props()

    const liveForm = useLiveForm(serverForm, {
        changeEvent: "validate",
        submitEvent: "submit",
        debounceInMiliseconds: 300,
    })

    // Sync server-side updates (new errors / values) into the composable.
    $effect(() => {
        liveForm.sync(serverForm)
    })

    // Field stores — memoized, same instance returned on every call.
    const nameField = liveForm.field("name")
    const emailField = liveForm.field("email")

    // Form-level stores for template auto-subscription.
    const isValid = liveForm.isValid
</script>

<div class="w-full min-w-xs mx-auto">
    <form
        onsubmit={e => {
            e.preventDefault()
            liveForm.submit()
        }}
        class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden"
    >
        <div class="card-body gap-4 p-5">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit"> Contact form </span>

            <!-- Name field -->
            <label class="flex flex-col gap-1.5">
                <span class="text-xs font-medium text-base-content/50">Name *</span>
                <input
                    data-testid="form-name-input"
                    class="input input-bordered input-sm w-full bg-base-200/50 border-base-300"
                    {...$nameField.attrs}
                />
                {#if $nameField.errorMessage}
                    <p data-testid="form-name-error" class="text-error text-xs">
                        {$nameField.errorMessage}
                    </p>
                {/if}
            </label>

            <!-- Email field -->
            <label class="flex flex-col gap-1.5">
                <span class="text-xs font-medium text-base-content/50">Email *</span>
                <input
                    data-testid="form-email-input"
                    class="input input-bordered input-sm w-full bg-base-200/50 border-base-300"
                    {...$emailField.attrs}
                />
                {#if $emailField.errorMessage}
                    <p data-testid="form-email-error" class="text-error text-xs">
                        {$emailField.errorMessage}
                    </p>
                {/if}
            </label>

            <div class="flex items-center justify-between">
                <button data-testid="form-submit-btn" type="submit" class="btn btn-sm bg-brand text-white border-0 hover:opacity-90 w-fit">
                    Submit
                </button>
                <span data-testid="form-valid-indicator" class="badge badge-ghost border badge-sm font-medium">
                    {$isValid ? "valid" : "invalid"}
                </span>
            </div>
        </div>
    </form>
</div>
