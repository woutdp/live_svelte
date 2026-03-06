# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.18.0 - 2026-03-06

> **Note:** Many of the features in this release were backported from
> [live_vue](https://github.com/Valian/live_vue) by
> [Jakub Skalecki](https://github.com/Valian). A huge thank you to Jakub
> for the excellent architecture and implementation that served as the
> foundation for props diffing, composables, streams support, Vite
> integration, Igniter installer, and more.

### Breaking Changes

-   **esbuild removed** — LiveSvelte no longer supports esbuild. Migrate to
    Vite + `phoenix_vite`. See the [Upgrade Guide](guides/upgrade_guide.html)
    for step-by-step instructions.

-   **live_json / live_json_props removed** — The `live_json` hex dependency
    and `live_json_props` attribute have been removed. Replace with `props={...}`;
    built-in JSON Patch diffing provides the same optimization by default.

-   **phoenix_vite now required** — Add `{:phoenix_vite, "~> 0.4"}` to your
    `mix.exs` dependencies.

### Added

-   **Vite integration** — Full Vite build pipeline replaces esbuild.
    `phoenix_vite` handles client and SSR builds with a single `vite.config.mjs`.

-   **Vite HMR** — Hot Module Replacement for Svelte components and CSS in
    development. Zero extra config when using `phoenix_vite` — just run
    `mix phx.server`.

-   **ViteJS SSR mode** — New `LiveSvelte.SSR.ViteJS` backend sends SSR render
    requests to the Vite dev server over HTTP. New `.svelte` files are picked up
    immediately without running `mix assets.build`.

-   **SSR telemetry** — SSR render events emit telemetry under
    `[:live_svelte, :ssr, :render, :start]` / `[:live_svelte, :ssr, :render, :stop]`
    for performance monitoring.

-   **Igniter installer** — `mix live_svelte.install` (powered by
    [Igniter](https://hex.pm/packages/igniter)) sets up LiveSvelte automatically
    in an existing Phoenix project, including Vite config, endpoint changes, and
    JavaScript entrypoint.

-   **Props diffing (JSON Patch)** — Server-side props are diffed using RFC 6902
    JSON Patch, sending only changed values to the client. Enabled by default;
    disable with `config :live_svelte, enable_props_diff: false`.

-   **Svelte encoder** — New `LiveSvelte.Encoder` protocol for custom JSON
    serialization of Svelte props. Replaces the need for `@derive Jason.Encoder`
    on Elixir structs.

-   **Streams support** — Phoenix `stream/3` now works with Svelte components.
    Stream operations are sent as JSON Patch ops via the `data-streams-diff`
    attribute.

-   **Live form support** — New `useLiveForm` composable for Ecto
    changeset-backed forms in Svelte with server-side validation feedback.

-   **File upload support** — New `useLiveUpload` composable for Phoenix
    LiveView file uploads with progress tracking.

-   **Event reply** — New `useEventReply` composable for handling `push_reply`
    responses from the server.

-   **Live navigation** — New `useLiveNavigation` composable exposing `patch()`
    and `navigate()` for client-side routing from Svelte.

-   **TypeScript rewrite** — Library source (`assets/js/live_svelte/*.ts`) is
    now written in TypeScript with full type definitions exported via
    `package.json`.

-   **Hot-apply new components** — New `.svelte` files added during development
    are automatically discovered by the ViteJS SSR mode and Vite plugin without
    restarting the Phoenix server.

-   **CI/CD** — GitHub Actions workflows for Elixir (tests + Coveralls coverage
    reporting) and frontend (Vitest unit tests).

-   **Documentation** — `ex_doc` integration; all public modules now have
    HexDocs entries.

-   **New examples** — Drag & Drop, Rich Text Editor (Editor.js), Runed state
    management, Svelte Stores.

### Removed

-   **esbuild** — Removed `esbuild` mix dependency, `assets/build.js`, and all
    related `config :esbuild` configuration.

-   **live_json / live_json_props** — Removed in favor of built-in props
    diffing (enabled by default).

## 0.17.4 - 2026-02-18

### Added

-   `key` attribute for stable DOM IDs in loops (`name-key`).
-   Auto-detect identity from props (`id`, `key`, `index`, `idx`) to generate deterministic IDs.

### Fixed

-   Preserve Svelte component instances/local state by avoiding timing-based ID resets and using deterministic ID generation.
-   Correct props filtering when `assigns.__changed__` is `nil` (e.g. `~V` sigil / initial render).

### Changed (dev)

-   Expanded `example_project` test coverage across **PhoenixTest** (server-side contract) and **Wallaby E2E** (full browser pipeline) to validate LiveView → LiveSvelte hook → Svelte component rendering and interactions across more demos (e.g. counters, slots, live_json, chat, lights, client-side loading, struct/OTP examples).

## 0.17.3 - 2026-02-08

### Added

-   Auto-generated IDs for duplicate Svelte components to ensure correct reconciliation
-   Upgrade example project to use Daisy UI and latest Phoenix

### Fixed

-   Svelte component remounting on server events when it should update in place
-   Static Svelte components in LiveView parent are now handled properly
-   Fix duplicate ID collisions in `for` loops by replacing timing-based counter with deterministic identity extraction from props (`id`, `key`, `index`, `idx`). Added `key` attribute for explicit loop identity.


## 0.17.2 - 2026-02-02

### Fixed

-   Fixed "undefined slot" compiler warnings when using named slots with `LiveSvelte.svelte` ([#196](https://github.com/woutdp/live_svelte/pull/196))
-   Fixed `Jason.Encoder` protocol error when using slots with `LiveSvelte.Components` macro

### Changed

-   `LiveSvelte.Slots.filter_slots_from_assigns/1` now handles slots with multiple entries
-   Named slots are now properly forwarded through the Components macro

## 0.17.1 - 2026-02-01

### Added

-   DateTime, NaiveDateTime, Date, and Time are now automatically converted to ISO 8601 strings
-   Ecto schema `__meta__` field is automatically stripped during JSON encoding
-   New `LiveSvelte.JSON.prepare/1` function for preparing data before external JSON encoders

### Fixed

-   SSR now properly serializes DateTime and Ecto schemas when passing to NodeJS

## 0.17.0 - 2026-01-22

### Breaking Changes

-   **Minimum OTP version is now 27** - LiveSvelte now uses Erlang's native `:json` module by default
-   **Minimum Elixir version is now 1.17** - Required for OTP 27 support
-   **Jason is now optional** - Add `{:jason, "~> 1.2"}` to your deps if you want to use Jason instead of native JSON

### Changed

-   Default JSON library changed from Jason to native Erlang `:json` module (`LiveSvelte.JSON`)
-   Structs are automatically converted to maps by the native JSON encoder (no `@derive` needed)

### Added

-   New `LiveSvelte.JSON` module that wraps Erlang's native `:json` module with a Jason-compatible interface

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
