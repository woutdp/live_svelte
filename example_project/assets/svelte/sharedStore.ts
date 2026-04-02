import {writable, derived} from "svelte/store"

// Shared writable store — a module singleton.
// Every component that imports this gets the exact same store instance,
// so any write is immediately visible in all subscribers across the page.
export const sharedCount = writable(0)
export const sharedCountIsOdd = derived(sharedCount, count => count % 2 === 1)
