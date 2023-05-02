# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
