// Test SSR server for NodeJS SSR tests
export function render(name, props, slots) {
  const propsStr = JSON.stringify(props)
  const slotsStr = JSON.stringify(slots)

  return `<div data-component="${name}" data-props="${propsStr.replace(/"/g, "&quot;")}" data-slots="${slotsStr.replace(/"/g, "&quot;")}">SSR Rendered: ${name}</div>`
}
