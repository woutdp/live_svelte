import * as Components from '../svelte/components/**/*'

let { default: modules, filenames } = Components

filenames = filenames
    .map(name => name.replace('../svelte/components/', ''))
    .map(name => name.replace('.svelte', ''))

components = Object.assign({}, ...modules.map((m, index) => ({[filenames[index]]: m.default})))

function parsedProps(el) {
    const props = el.getAttribute('data-props')
    return props ? JSON.parse(props) : {}
}

const SvelteComponent = {
    mounted() {
        const componentName = this.el.getAttribute('data-name')
        if (!componentName) {
            throw new Error('Component name must be provided')
        }

        const Component = components[componentName]
        if (!Component) {
            throw new Error(`Unable to find ${componentName} component. Did you forget to import it into hooks.js?`)
        }

        const pushEvent = (event, data, callback) => {
            this.pushEvent(event, data, callback)
        }

        const goto = href => {
            liveSocket.pushHistoryPatch(href, 'push', this.el)
        }

        this._instance = new Component({
            target: this.el,
            props: {...parsedProps(this.el), pushEvent, goto},
            hydrate: true
        })
    },

    updated() {
        const pushEvent = (event, data, callback) => {
            this.pushEvent(event, data, callback)
        }

        const goto = href => {
            liveSocket.pushHistoryPatch(href, 'push', this.el)
        }

        this._instance.$$set({...parsedProps(this.el), pushEvent, goto})
    },

    destroyed() {
        this._instance?.$destroy()
    }
}

export default {
    SvelteComponent
}
