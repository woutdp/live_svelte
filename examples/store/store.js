import {writable} from "svelte/store"

function createStore() {
    return writable(true)
}

function getStore() {
    if (typeof window === "undefined") return createStore()
    window.store = window.store || createStore()
    return window.store
}

export default store = getStore()
