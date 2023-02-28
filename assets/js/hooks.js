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

function extraProps(ref) {
    return {
        pushEvent: (event, data, callback) => ref.pushEvent(event, data, callback),
        innerBlock: ref.el.getAttribute('data-inner-block')
    }
}

const SvelteComponent = {
    mounted() {
        const componentName = this.el.getAttribute('data-name')
        if (!componentName) {
            throw new Error('Component name must be provided')
        }

        const Component = components[componentName]
        if (!Component) {
            throw new Error(`Unable to find ${componentName} component.`)
        }

        this._instance = new Component({
            target: this.el,
            props: {...parsedProps(this.el), ...extraProps(this)},
            hydrate: true
        })
    },

    updated() {
        this._instance.$$set({...parsedProps(this.el), ...extraProps(this)})
    },

    destroyed() {
        this._instance?.$destroy()
    }
}

export default {
    SvelteComponent
}
