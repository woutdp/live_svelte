# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## UNRELEASED

## 0.16.0 - 2025-04-18

### Added
-   Added support for [fallback content](https://github.com/woutdp/live_svelte?tab=readme-ov-file#showing-fallback-content-with-loading) while the component is rendering

### Fixed
-   Documentation tweaks that refer to adding the socket when not using SSR

## 0.15.0 - 2025-02-05

### Changed

-   Support Svelte 5

## 0.14.1 - 2024-11-19

### Changed

-   Upgraded to esbuild 0.24.0. This requires you to reconfigure the `build.js` file. An example can be found in `example_project/assets/build.js`.

## [0.14.0] - 2024-09-25

### Added

-   Added the option to disable SSR through a config variable [Issue 144](https://github.com/woutdp/live_svelte/issues/144)

### Changed

-   Updated :nodejs to `3.1`

## [0.13.3] - 2024-08-15

### Fixed

-   Fixed an issue where the `SvelteHook` wasn't updated when pulling in `0.13.2`

## [0.13.2] - 2024-05-21

### Fixed

-   Fixed an issue where the Svelte component would flicker on navigation: [Issue 125](https://github.com/woutdp/live_svelte/issues/125)

## [0.13.1] - 2024-04-12

### Changed

-   Stopped silently failing json encoding errors: [Issue 113](https://github.com/woutdp/live_svelte/issues/113)

## [0.13.0] - 2024-01-17

### Added

-   Added flake setup with direnv

### Fixed

-   Memory leak [issue](https://github.com/woutdp/live_svelte/issues/108)
-   Explicitly set npm install folder [fixes package.json on Windows](https://github.com/woutdp/live_svelte/issues/75)
-   Properly support binary for SSR

### Changed

-   Started work on a plugable SSR renderer [PR](https://github.com/woutdp/live_svelte/pull/82)
-   Async and improved setup tasks

## [0.12.0] - 2023-08-19

### Changed

-   Must now provide the `socket` when rendering in a LiveView [PR](https://github.com/woutdp/live_svelte/pull/74)

### Fixed

-   Fixed some TypeScript definitions

## [0.11.0] - 2023-08-08

This update involves some breaking changes laid out in [PR](https://github.com/woutdp/live_svelte/pull/65).
Most of these changes should be resolved by running `mix live_svelte.setup`.

Manual migration guide:

-   Use `export let live; live.pushEvent();` instead of `export let pushEvent; pushEvent();`, example is available in the readme
-   Update the `build.js` file by setting `optsServer.outdir` to `outdir: "../priv/svelte"`
-   Update the `build.js` file by setting `compilerOptions` to include `{dev: !deploy, ...}`
-   Add `/priv/svelte/` to your `.gitignore` file
-   Replace the `server.js` file

### Added

-   Add "browser" to client esbuild conditions for svelte 4
-   Add typescript definitions
-   Added dev option in compilerOptions

### Changed

-   Move ssr build from `priv/static/assets` into `priv/svelte`
-   Use `export let live` instead of `export let pushEvent` and `export let pushEventTo` allowing for a more broad use of LiveView JS interop.

## [0.10.2] - 2023-07-31

### Fixed

-   Cleanup and simplify `render` function - [PR](https://github.com/woutdp/live_svelte/pull/61)
-   Mark `esbuild` as dev only dependency - [PR](https://github.com/woutdp/live_svelte/pull/62)

## [0.10.1] - 2023-07-30

### Fixed

[PR](https://github.com/woutdp/live_svelte/pull/60)

-   Json and liveJsonData variables in getLiveJsonProps were missing declaration specifier. The code was not working in strict mode.
-   Fixed issue where compilerOptions.css was incorrectly configured.
-   Hydrate should be true only if there was ssr involved, was getting errors about it, added data-ssr attribute to indicate server rendering.
-   Simplified `get_svelte_components`
-   Cosmetic changes

## [0.10.0] - 2023-07-28

### Added

-   Support for Svelte 4

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
