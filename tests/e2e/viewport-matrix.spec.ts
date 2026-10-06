import { test, expect } from './fixtures'
import { clickControl, clickWaterForPlayer, gameState, openGame, startRound } from './game'

type Size = { width: number; height: number }
type Rect = { x: number; y: number; width: number; height: number }

const SIZES: Size[] = [
  { width: 1920, height: 1080 },
  { width: 1280, height: 720 },
  { width: 1365, height: 768 },
  { width: 390, height: 844 },
  { width: 768, height: 1024 },
]

function expectRectInside(rect: Rect, size: Size, name: string): void {
  expect.soft(rect.width, `${name} width`).toBeGreaterThanOrEqual(0)
  expect.soft(rect.height, `${name} height`).toBeGreaterThanOrEqual(0)
  expect.soft(rect.x, `${name} left`).toBeGreaterThanOrEqual(-0.5)
  expect.soft(rect.y, `${name} top`).toBeGreaterThanOrEqual(-0.5)
  expect.soft(rect.x + rect.width, `${name} right`).toBeLessThanOrEqual(size.width + 0.5)
  expect.soft(rect.y + rect.height, `${name} bottom`).toBeLessThanOrEqual(size.height + 0.5)
}

function contains(outer: Rect, inner: Rect): boolean {
  return (
    inner.x >= outer.x - 0.5
    && inner.y >= outer.y - 0.5
    && inner.x + inner.width <= outer.x + outer.width + 0.5
    && inner.y + inner.height <= outer.y + outer.height + 0.5
  )
}

function overlaps(left: Rect, right: Rect): boolean {
  return (
    left.x < right.x + right.width
    && left.x + left.width > right.x
    && left.y < right.y + right.height
    && left.y + left.height > right.y
  )
}

function toPhysicalRect(rect: Rect, canvas: Rect, logicalSize: Size): Rect {
  return {
    x: canvas.x + (rect.x / logicalSize.width) * canvas.width,
    y: canvas.y + (rect.y / logicalSize.height) * canvas.height,
    width: (rect.width / logicalSize.width) * canvas.width,
    height: (rect.height / logicalSize.height) * canvas.height,
  }
}

function logicalSize(state: Record<string, any>): Size {
  return { width: state.viewport.x, height: state.viewport.y }
}

test('E2E-VIEW-01 / E2E-VIEW-02 Web 横竖屏视口布局矩阵', async ({ page, browserErrors }, testInfo) => {
  test.setTimeout(120_000)
  page.setDefaultTimeout(30_000)

  for (const size of SIZES) {
    await page.setViewportSize(size)
    await openGame(page, { setup: 'none' })
    expect(page.viewportSize()).toEqual(size)

    const setupState = await gameState(page)
    expect.soft(setupState.session.state).toBe('MODE_SELECT')
    expect.soft(setupState.session.setup_visible).toBe(true)
    const setupLogicalSize = logicalSize(setupState)
    const setupCanvasBox = await page.locator('canvas').boundingBox()
    expect(setupCanvasBox, `${size.width}x${size.height} setup canvas bounding box`).not.toBeNull()
    for (const name of ['mode_single', 'mode_multi'] as const) {
      expectRectInside(setupState.controls[name], setupLogicalSize, `${name} logical`)
      expectRectInside(toPhysicalRect(setupState.controls[name], setupCanvasBox!, setupLogicalSize), size, `${name} physical`)
    }
    expect.soft(overlaps(setupState.controls.mode_single, setupState.controls.mode_multi), 'Mode buttons must not overlap').toBe(false)
    await page.locator('canvas').screenshot({
      path: testInfo.outputPath(`setup-mode-${size.width}x${size.height}.png`),
    })
    await clickControl(page, 'mode_multi')
    await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')

    const state = await gameState(page)
    const currentLogicalSize = logicalSize(state)
    expect.soft(currentLogicalSize.width, 'logical viewport width').toBeGreaterThan(0)
    expect.soft(currentLogicalSize.height, 'logical viewport height').toBeGreaterThan(0)
    expect.soft(state.round.state).toBe('READY')
    expect.soft(state.hud.ready_visible).toBe(true)
    expect.soft(state.hud.score).toBe('P1: 0 / 1800\nP2: 0 / 1800')
    expect.soft(state.hud.time).toBe('90')

    const canvas = page.locator('canvas')
    const canvasBox = await canvas.boundingBox()
    expect(canvasBox, `${size.width}x${size.height} canvas bounding box`).not.toBeNull()
    expect.soft(canvasBox!.width).toBeGreaterThan(0)
    expect.soft(canvasBox!.height).toBeGreaterThan(0)
    expect.soft(canvasBox!.x).toBeGreaterThanOrEqual(0)
    expect.soft(canvasBox!.y).toBeGreaterThanOrEqual(0)
    expect.soft(canvasBox!.x + canvasBox!.width).toBeLessThanOrEqual(size.width)
    expect.soft(canvasBox!.y + canvasBox!.height).toBeLessThanOrEqual(size.height)

    const layoutNames = [
      'score',
      'time',
      'powerup_row',
      'p1_effects',
      'global_effects',
      'p2_effects',
      'prompt',
    ] as const
    for (const name of layoutNames) {
      expectRectInside(state.layout[name], currentLogicalSize, `${name} logical`)
      expectRectInside(toPhysicalRect(state.layout[name], canvasBox!, currentLogicalSize), size, `${name} physical`)
    }

    const start = state.controls.start as Rect
    expectRectInside(start, currentLogicalSize, 'start logical')
    expectRectInside(toPhysicalRect(start, canvasBox!, currentLogicalSize), size, 'start physical')
    expect.soft(start.width).toBeGreaterThan(0)
    expect.soft(start.height).toBeGreaterThan(0)
    expect.soft(contains(state.layout.prompt, start), 'StartButton must remain inside the prompt').toBe(true)
    for (const name of layoutNames.filter(name => name !== 'prompt')) {
      expect.soft(overlaps(state.layout[name], start), `${name} must not cover StartButton`).toBe(false)
    }

    for (const name of ['p1_effects', 'global_effects', 'p2_effects'] as const) {
      expect.soft(contains(state.layout.powerup_row, state.layout[name]), `${name} must stay in powerup row`).toBe(true)
    }
    expect.soft(overlaps(state.layout.p1_effects, state.layout.global_effects)).toBe(false)
    expect.soft(overlaps(state.layout.global_effects, state.layout.p2_effects)).toBe(false)
    const topLevelHud = ['score', 'time', 'powerup_row', 'prompt'] as const
    for (let left = 0; left < topLevelHud.length; left += 1) {
      for (let right = left + 1; right < topLevelHud.length; right += 1) {
        expect.soft(
          overlaps(state.layout[topLevelHud[left]], state.layout[topLevelHud[right]]),
          `${topLevelHud[left]} must not overlap ${topLevelHud[right]}`,
        ).toBe(false)
      }
    }

    await canvas.screenshot({
      path: testInfo.outputPath(`viewport-${size.width}x${size.height}.png`),
    })

    if (size.width < size.height) {
      await startRound(page)
      await clickWaterForPlayer(page, 1)
      await expect.poll(async () => (await gameState(page)).hooks['1'].state).toBe('EXTENDING')
    }
  }

  expect(browserErrors).toEqual([])
})
