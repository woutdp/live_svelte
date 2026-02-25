/**
 * useLiveForm — Svelte composable for Phoenix LiveView form binding.
 *
 * Binds to an Ecto changeset-backed form prop, providing reactive field
 * instances with value, errors, and attrs for inputs. Uses Svelte stores
 * (`writable`/`derived` from `svelte/store`) for reactivity so it compiles
 * in plain `.ts` without the Svelte compiler plugin in Vitest.
 *
 * Usage:
 * ```svelte
 * <script lang="ts">
 *   import { useLiveForm } from "live_svelte"
 *   let { form: serverForm } = $props()
 *   const liveForm = useLiveForm(serverForm, { changeEvent: "validate", submitEvent: "submit" })
 *   $effect(() => { liveForm.sync(serverForm) })
 *   const nameField = liveForm.field("name")
 * </script>
 * <input {...$nameField.attrs} />
 * ```
 */

import { writable, derived, get, type Readable, type Writable } from "svelte/store"
import { useLiveSvelte } from "./composables"

// ---------------------------------------------------------------------------
// Utility functions
// ---------------------------------------------------------------------------

function deepClone<T>(val: T): T {
  return JSON.parse(JSON.stringify(val))
}

function parsePath(path: string): string[] {
  return path.replace(/\[(\d+)\]/g, ".$1").split(".").filter(Boolean)
}

function getByPath(obj: any, keys: string[]): any {
  return keys.reduce((acc: any, key: string) => (acc != null ? acc[key] : undefined), obj)
}

/** In-place mutation on an already-cloned object. */
function setByPath(obj: any, keys: string[], value: any): void {
  if (keys.length === 0) return
  const last = keys[keys.length - 1]
  const parent = keys.slice(0, -1).reduce((acc: any, k: string) => acc?.[k], obj)
  if (parent !== undefined) parent[last] = value
}

function sanitizeId(path: string): string {
  return path.replace(/[\[\].]/g, "_").replace(/_+/g, "_").replace(/^_|_$/g, "")
}

function hasAnyErrors(errors: any): boolean {
  if (errors == null) return false
  if (Array.isArray(errors)) {
    if (errors.length === 0) return false
    if (typeof errors[0] === "string") return true
    return errors.some((e: any) => hasAnyErrors(e))
  }
  if (typeof errors === "object") {
    return Object.values(errors).some((v: any) => hasAnyErrors(v))
  }
  return false
}

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/**
 * Recursive type for Ecto changeset error maps.
 * Each key maps to either an array of error strings or a nested error map.
 */
export type FormErrors<T extends object> = {
  [K in keyof T]?: string[] | Record<string, unknown>
}

/**
 * Shape of the Phoenix.HTML.Form encoded by LiveSvelte.Encoder.
 * Produced by `to_form(changeset)` in the LiveView and passed as a prop.
 */
export interface Form<T extends object> {
  /** Form name used as the key in `pushEvent` payloads: `{ [name]: values }` */
  name: string
  /** Current field values */
  values: T
  /** Validation errors per field */
  errors: FormErrors<T>
  /** Whether the changeset is valid */
  valid: boolean
}

/** Options for `field()` to specify input type and checkbox value. */
export interface FieldOptions {
  /** HTML input type, e.g. `"checkbox"`, `"radio"`, `"number"`. */
  type?: string
  /** For checkboxes: the value this input represents when checked. */
  value?: unknown
}

/** Options for `useLiveForm`. */
export interface FormOptions {
  /** Server event for validation. `null` disables automatic validation events. */
  changeEvent?: string | null
  /** Server event for form submission. Default: `"submit"`. */
  submitEvent?: string
  /** Debounce delay in ms for change events. Default: `300`. */
  debounceInMiliseconds?: number
  /** Transform form data before sending to server. */
  prepareData?: (data: Record<string, unknown>) => Record<string, unknown>
}

/** Attributes to spread onto an `<input>` element. */
export interface FieldAttrs {
  name: string
  id: string
  oninput: (e: Event) => void
  onblur: () => void
  "aria-invalid": boolean
  "aria-describedby"?: string
  value?: unknown
  checked?: boolean
  type?: string
}

/** Reactive state snapshot for a single form field (the store's value). */
export interface FieldState<V> {
  value: V
  errors: string[]
  errorMessage: string | undefined
  isValid: boolean
  isDirty: boolean
  isTouched: boolean
  attrs: FieldAttrs
}

/**
 * A reactive field store. Subscribe via `$nameField` in Svelte templates.
 * Call `nameField.set(value)` to update the field value programmatically.
 */
export interface FormField<V> extends Readable<FieldState<V>> {
  set(value: V): void
  update(updater: (currentValue: V) => V): void
  /** Access a nested sub-field by dot-path relative to this field. */
  field(subPath: string, options?: FieldOptions): FormField<any>
  /** Access a nested array sub-field by dot-path relative to this field. */
  fieldArray(subPath: string): FormFieldArray<any>
}

/**
 * A reactive array-field store. Provides `fields` (array of item field stores)
 * and `add`/`remove`/`move` operations.
 */
export interface FormFieldArray<V> extends Readable<FieldState<V[]>> {
  set(value: V[]): void
  /** Reactive store of per-item `FormField` instances. Subscribe via `$itemFields`. */
  fields: Readable<FormField<V>[]>
  add(item?: Partial<V>): void
  remove(index: number): void
  move(from: number, to: number): void
}

/** Return value of `useLiveForm`. */
export interface UseLiveFormReturn<T extends object> {
  isValid: Readable<boolean>
  isDirty: Readable<boolean>
  isTouched: Readable<boolean>
  isValidating: Readable<boolean>
  submitCount: Readable<number>
  /** Frozen snapshot of initial values. */
  initialValues: Readonly<T>
  field<V = unknown>(path: string, options?: FieldOptions): FormField<V>
  fieldArray<V = unknown>(path: string): FormFieldArray<V>
  /** Send submit event to the LiveView. Handles `{ reset: true }` reply. */
  submit(): Promise<any>
  /** Reset form to initial values and clear touched/dirty state. */
  reset(): void
  /**
   * Merge server-side form updates into the composable.
   * Always updates errors; updates values only when not validating.
   * Call this from a Svelte `$effect(() => { liveForm.sync(serverForm) })`.
   */
  sync(newForm: Form<T>): void
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

export function useLiveForm<T extends object>(
  form: Form<T>,
  options: FormOptions = {}
): UseLiveFormReturn<T> {
  const {
    changeEvent = null,
    submitEvent = "submit",
    debounceInMiliseconds = 300,
    prepareData = (d: Record<string, unknown>) => d,
  } = options

  // Graceful degradation: composable works without LiveSvelte context (SSR, tests without mock).
  let liveCtx: ReturnType<typeof useLiveSvelte> | null = null
  try {
    liveCtx = useLiveSvelte()
  } catch {
    // SSR or test without LiveSvelte context — pushEvent unavailable.
  }

  // Snapshot initial values for dirty detection and reset.
  const initialSnapshot = deepClone(form.values)
  const initialValues = Object.freeze(initialSnapshot) as Readonly<T>

  // Core reactive stores.
  const currentValues: Writable<T> = writable(deepClone(form.values))
  const currentErrors: Writable<FormErrors<T>> = writable(deepClone(form.errors))
  const touchedPaths: Writable<Set<string>> = writable(new Set())
  const submitCountStore: Writable<number> = writable(0)
  const isValidatingStore: Writable<boolean> = writable(false)

  let debounceTimer: ReturnType<typeof setTimeout> | null = null

  // Form-level derived stores.
  const isValid: Readable<boolean> = derived(
    currentErrors,
    ($errors) => !hasAnyErrors($errors)
  )

  const isDirty: Readable<boolean> = derived(
    currentValues,
    ($values) => JSON.stringify($values) !== JSON.stringify(initialSnapshot)
  )

  const isTouched: Readable<boolean> = derived(
    [submitCountStore, touchedPaths],
    ([$count, $touched]) => $count > 0 || $touched.size > 0
  )

  function sendChange(): void {
    if (!changeEvent || !liveCtx) return
    if (debounceTimer) clearTimeout(debounceTimer)
    isValidatingStore.set(true)
    debounceTimer = setTimeout(() => {
      const values = get(currentValues)
      const data = prepareData(values as Record<string, unknown>)
      liveCtx!.pushEvent(changeEvent, { [form.name]: data })
      isValidatingStore.set(false)
      debounceTimer = null
    }, debounceInMiliseconds)
  }

  // Memoize field instances per (path, opts) to prevent recreation on re-renders.
  const fieldCache = new Map<string, FormField<any>>()
  const fieldArrayCache = new Map<string, FormFieldArray<any>>()

  function createField<V>(path: string, opts: FieldOptions = {}): FormField<V> {
    const cacheKey = `${path}::${JSON.stringify(opts)}`
    if (fieldCache.has(cacheKey)) return fieldCache.get(cacheKey) as FormField<V>

    const keys = parsePath(path)
    const optValue = opts.value
    const fieldId =
      sanitizeId(path) + (optValue !== undefined ? `_${sanitizeId(String(optValue))}` : "")

    // Stable event handlers closed over constants (not re-created per derive).
    const onblurHandler = () => {
      touchedPaths.update((s) => {
        s.add(path)
        return s
      })
    }

    let oninputHandler: (e: Event) => void

    if (opts.type === "checkbox") {
      oninputHandler = (e: Event) => {
        const target = e.target as HTMLInputElement
        currentValues.update((vals) => {
          const clone = deepClone(vals)
          const current = getByPath(clone, keys)
          if (Array.isArray(current)) {
            // Multi-checkbox: toggle value in array.
            const arr = [...current]
            const idx = arr.indexOf(optValue)
            if (target.checked && idx === -1) arr.push(optValue)
            else if (!target.checked && idx !== -1) arr.splice(idx, 1)
            setByPath(clone, keys, arr)
          } else {
            // Single checkbox: set value or null.
            const checkedValue = optValue !== undefined ? optValue : true
            setByPath(clone, keys, target.checked ? checkedValue : null)
          }
          return clone
        })
        sendChange()
      }
    } else {
      oninputHandler = (e: Event) => {
        const target = e.target as HTMLInputElement
        currentValues.update((vals) => {
          const clone = deepClone(vals)
          setByPath(clone, keys, target.value)
          return clone
        })
        sendChange()
      }
    }

    const stateStore: Readable<FieldState<V>> = derived(
      [currentValues, currentErrors, touchedPaths, submitCountStore],
      ([$values, $errors, $touched, $count]) => {
        const value = getByPath($values, keys) as V
        const rawErrors = getByPath($errors, keys)
        // Errors are a string[] if the array's first element is a string (or empty).
        const errors: string[] =
          Array.isArray(rawErrors) &&
          (rawErrors.length === 0 || typeof rawErrors[0] === "string")
            ? (rawErrors as string[])
            : []
        const errorMessage = errors.length > 0 ? errors[0] : undefined
        const isFieldValid = errors.length === 0
        const isTouchedField = $count > 0 || $touched.has(path)
        const initialVal = getByPath(initialSnapshot, keys)
        const isFieldDirty = JSON.stringify(value) !== JSON.stringify(initialVal)

        let attrs: FieldAttrs
        if (opts.type === "checkbox") {
          const isMulti = Array.isArray(value)
          attrs = {
            name: path,
            id: fieldId,
            type: "checkbox",
            ...(optValue !== undefined ? { value: optValue } : {}),
            checked: isMulti
              ? ((value as unknown as any[]) ?? []).includes(optValue)
              : value === (optValue !== undefined ? optValue : true),
            oninput: oninputHandler,
            onblur: onblurHandler,
            "aria-invalid": !isFieldValid,
            ...(errors.length > 0 ? { "aria-describedby": `${fieldId}-error` } : {}),
          }
        } else {
          attrs = {
            name: path,
            id: fieldId,
            ...(opts.type ? { type: opts.type } : {}),
            value: value as unknown,
            oninput: oninputHandler,
            onblur: onblurHandler,
            "aria-invalid": !isFieldValid,
            ...(errors.length > 0 ? { "aria-describedby": `${fieldId}-error` } : {}),
          }
        }

        return {
          value,
          errors,
          errorMessage,
          isValid: isFieldValid,
          isDirty: isFieldDirty,
          isTouched: isTouchedField,
          attrs,
        }
      }
    )

    const fieldStore: FormField<V> = {
      subscribe: stateStore.subscribe,

      set(value: V) {
        currentValues.update((vals) => {
          const clone = deepClone(vals)
          setByPath(clone, keys, value)
          return clone
        })
        sendChange()
      },

      update(updater: (v: V) => V) {
        currentValues.update((vals) => {
          const current = getByPath(vals, keys) as V
          const clone = deepClone(vals)
          setByPath(clone, keys, updater(current))
          return clone
        })
        sendChange()
      },

      field(subPath: string, subOpts?: FieldOptions): FormField<any> {
        return createField(`${path}.${subPath}`, subOpts)
      },

      fieldArray(subPath: string): FormFieldArray<any> {
        return createFieldArray(`${path}.${subPath}`)
      },
    }

    fieldCache.set(cacheKey, fieldStore)
    return fieldStore
  }

  function createFieldArray<V>(path: string): FormFieldArray<V> {
    if (fieldArrayCache.has(path)) return fieldArrayCache.get(path) as FormFieldArray<V>

    const keys = parsePath(path)
    const baseField = createField<V[]>(path) as FormField<V[]>

    const fieldsStore: Readable<FormField<V>[]> = derived(currentValues, ($values) => {
      const arr: V[] = getByPath($values, keys) ?? []
      return arr.map((_: V, i: number) => createField<V>(`${path}[${i}]`))
    })

    const arrayStore: FormFieldArray<V> = {
      subscribe: baseField.subscribe,

      set(value: V[]) {
        baseField.set(value)
      },

      fields: fieldsStore,

      add(item?: Partial<V>) {
        currentValues.update((vals) => {
          const clone = deepClone(vals)
          const arr: V[] = getByPath(clone, keys) ?? []
          setByPath(clone, keys, [...arr, (item ?? {}) as V])
          return clone
        })
        sendChange()
      },

      remove(index: number) {
        currentValues.update((vals) => {
          const clone = deepClone(vals)
          const arr: V[] = [...(getByPath(clone, keys) ?? [])]
          arr.splice(index, 1)
          setByPath(clone, keys, arr)
          return clone
        })
        sendChange()
      },

      move(from: number, to: number) {
        currentValues.update((vals) => {
          const clone = deepClone(vals)
          const arr: V[] = [...(getByPath(clone, keys) ?? [])]
          if (from >= 0 && from < arr.length && to >= 0 && to < arr.length) {
            const [item] = arr.splice(from, 1)
            arr.splice(to, 0, item)
            setByPath(clone, keys, arr)
          }
          return clone
        })
        sendChange()
      },
    }

    fieldArrayCache.set(path, arrayStore)
    return arrayStore
  }

  async function submit(): Promise<any> {
    // Cancel any pending debounce to prevent stale validate events after submit.
    if (debounceTimer) {
      clearTimeout(debounceTimer)
      debounceTimer = null
      isValidatingStore.set(false)
    }

    if (!liveCtx) {
      console.warn("LiveView hook not available, form submission skipped")
      return Promise.resolve(undefined)
    }

    submitCountStore.update((n) => n + 1)

    const values = get(currentValues)
    const data = prepareData(values as Record<string, unknown>)

    return new Promise((resolve) => {
      liveCtx!.pushEvent(submitEvent, { [form.name]: data }, (result: any) => {
        if (result && result.reset) {
          reset()
        }
        resolve(result)
      })
    })
  }

  function reset(): void {
    if (debounceTimer) {
      clearTimeout(debounceTimer)
      debounceTimer = null
    }
    currentValues.set(deepClone(initialSnapshot))
    currentErrors.set({} as FormErrors<T>)
    touchedPaths.set(new Set())
    submitCountStore.set(0)
    isValidatingStore.set(false)
  }

  function sync(newForm: Form<T>): void {
    currentErrors.set(deepClone(newForm.errors))
    if (!get(isValidatingStore)) {
      currentValues.set(deepClone(newForm.values))
    }
  }

  return {
    isValid,
    isDirty,
    isTouched,
    isValidating: { subscribe: isValidatingStore.subscribe },
    submitCount: { subscribe: submitCountStore.subscribe },
    initialValues,
    field: createField,
    fieldArray: createFieldArray,
    submit,
    reset,
    sync,
  }
}
