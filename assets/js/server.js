import * as Components from '../svelte/components/**/*'

let { default: modules, filenames } = Components

filenames = filenames
    .map(name => name.replace('../svelte/components/', ''))
    .map(name => name.replace('.svelte', ''))

module.exports = Object.assign({}, ...modules.map((m, index) => ({[filenames[index]]: m.default})))
