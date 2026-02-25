import { defineConfig } from 'vitest/config'

// Phoenix deps (phoenix, phoenix_html, phoenix_live_view) are file: refs in package.json.
// No resolve alias needed unless a test imports them; then add resolve.alias in Vite config.
export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['**/*.test.js', '**/*.spec.js', '**/*.test.ts', '**/*.spec.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['js/**/*.js', 'js/**/*.ts'],
      exclude: ['**/*.test.js', '**/*.spec.js', '**/*.test.ts', '**/*.spec.ts', 'node_modules/**'],
    },
  },
})
