/***
 * Render a component with the name, props and slots provided.
 */
export function render(name, props, slots) {
    const component = require(__filename)[name]
    const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v]))

    return component.render(props, {$$slots})
}
