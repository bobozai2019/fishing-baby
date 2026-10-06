import { test as base, expect } from '@playwright/test'

export const test = base.extend<{ browserErrors: string[] }>({
  browserErrors: [async ({ page }, use) => {
    const browserErrors: string[] = []
    page.on('pageerror', error => browserErrors.push(`pageerror: ${error.message}`))
    page.on('console', message => {
      if (message.type() === 'error') browserErrors.push(`console: ${message.text()}`)
    })
    await use(browserErrors)
    expect(browserErrors, 'browser console and page errors').toEqual([])
  }, { auto: true }],
})

export { expect }
