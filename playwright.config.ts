import { defineConfig, devices } from '@playwright/test'

const port = 8000

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  forbidOnly: true,
  retries: 1,
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: `http://127.0.0.1:${port}`,
    actionTimeout: 10_000,
    navigationTimeout: 30_000,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: `python tools/serve_web.py --port ${port} --directory tmp/build/web_e2e`,
    url: `http://127.0.0.1:${port}/index.html`,
    reuseExistingServer: true,
    timeout: 30_000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], viewport: { width: 1365, height: 768 } },
    },
    {
      name: 'edge',
      use: { ...devices['Desktop Edge'], channel: 'msedge', viewport: { width: 1365, height: 768 } },
    },
  ],
})
