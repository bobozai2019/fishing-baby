import { expect, type Page } from '@playwright/test'

export type GameState = Record<string, any>

declare global {
  interface Window {
    __fishingBabyE2EState?: GameState
    __fishingBabyE2ECommand?: (payload: string) => void
  }
}

export async function openGame(
  page: Page,
  options: { setup?: 'multi' | 'none' } = {},
): Promise<void> {
	await page.goto('/?e2e=1')
	await expect(page.locator('canvas')).toBeVisible()
	await page.waitForFunction(() => window.__fishingBabyE2EState?.ready === true)
	if ((options.setup ?? 'multi') === 'multi') {
		await clickControl(page, 'mode_multi')
		await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')
	}
}

export async function gameState(page: Page): Promise<GameState> {
  return page.evaluate(() => structuredClone(window.__fishingBabyE2EState))
}

export async function command(page: Page, name: string, args: Record<string, unknown> = {}): Promise<void> {
  const id = `${name}-${Date.now()}-${Math.random()}`
  await page.evaluate(
    payload => window.__fishingBabyE2ECommand?.(JSON.stringify(payload)),
    { id, name, args },
  )
  await expect.poll(async () => (await gameState(page)).last_command.id).toBe(id)
  const result = await gameState(page)
  expect(result.last_command.ok, result.last_command.error).toBe(true)
}

export async function clickControl(
  page: Page,
  control: 'start' | 'ready_return' | 'restart' | 'result_return' | 'mode_single' | 'mode_multi' | 'setup_back' | 'character_boy' | 'character_girl',
): Promise<void> {
  const state = await gameState(page)
  const rect = state.controls[control]
  await clickCanvasPoint(page, rect.x + rect.width / 2, rect.y + rect.height / 2, state.viewport)
}

export async function clickWaterForPlayer(page: Page, player: 1 | 2): Promise<void> {
  const state = await gameState(page)
  const x = state.viewport.x * (player === 1 ? 0.25 : 0.75)
  const y = state.viewport.y * 0.65
  await clickCanvasPoint(page, x, y, state.viewport)
}

export async function clickCanvasPoint(
  page: Page,
  logicalX: number,
  logicalY: number,
  viewport?: { x: number; y: number },
): Promise<void> {
  const canvas = page.locator('canvas')
  const box = await canvas.boundingBox()
  expect(box, 'Godot canvas bounding box').not.toBeNull()
  const logical = viewport ?? (await gameState(page)).viewport
  await page.mouse.click(
    box!.x + (logicalX / logical.x) * box!.width,
    box!.y + (logicalY / logical.y) * box!.height,
  )
}

export async function startRound(page: Page): Promise<void> {
  await clickControl(page, 'start')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('PLAYING')
}
