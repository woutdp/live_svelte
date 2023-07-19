# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2023-07-18

### Added

-   Added support for `live_json`

## [0.8.0] - 2023-06-03

### Added

-   Added [LiveSvelte Components Macro](https://github.com/woutdp/live_svelte#the-components-macro) - [PR](https://github.com/woutdp/live_svelte/pull/50)

## [0.7.1] - 2023-06-03

### Fixed

-   Support LiveView 0.19

## [0.7.0] - 2023-05-29

### Added

-   Added `pushEventTo`

## [0.6.0] - 2023-05-26

### Added

-   Install instructions on importing LiveSvelte inside `html_helpers` so `<.svelte />` is possible.

### Changed

-   Deprecated `LiveSvelte.render` in favor of `LiveSvelte.svelte`
-   Now we're using `<.svelte />` instead of `<LiveSvelte.render />` in the examples

## [0.5.1] - 2023-05-06

### Fixed

-   Fixed an issue where sometimes NPM packages don't import.

## [0.5.0] - 2023-05-02

### Added

-   Added `~V` sigil for using Svelte as an alternative DSL for LiveView
-   Added ability to use `$lib` inside Svelte components like: `import Component from "$lib/component.Svelte"`

### Fixed

-   Removed duplicate minify in `build.js`

### Changed

-   `build.js` file adds `tsconfig.json` configuration

## [0.4.2] - 2023-04-12

### Added

-   Start of the changelog
-   End-To-End Reactivity with LiveView
-   Server-Side Rendered (SSR) Svelte
-   Svelte Preprocessing Support with svelte-preprocess
-   Tailwind Support
-   Dead View Support
-   Slot Interoperability (Experimental)
