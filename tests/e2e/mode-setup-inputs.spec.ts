import { expect, type Page } from '@playwright/test'
import { test } from './fixtures'
import { gameState, openGame } from './game'

test.use({ hasTouch: true })

async function tapLogicalPoint(page: Page, logicalX: number, logicalY: number): Promise<void> {
  const state = await gameState(page)
  const canvas = page.locator('canvas')
  const box = await canvas.boundingBox()
  expect(box, 'Godot canvas bounding box').not.toBeNull()
  await page.touchscreen.tap(
    box!.x + (logicalX / state.viewport.x) * box!.width,
    box!.y + (logicalY / state.viewport.y) * box!.height,
  )
}

async function tapControl(
  page: Page,
  control: 'ready_return' | 'mode_multi' | 'start',
): Promise<void> {
  const state = await gameState(page)
  const rect = state.controls[control]
  await tapLogicalPoint(page, rect.x + rect.width / 2, rect.y + rect.height / 2)
}

test('E2E-MODE-05 键盘选择女孩并通过触控切换多人及发射 P2', async ({ page }) => {
  await openGame(page, { setup: 'none' })

  // Single has initial Godot focus, so real keyboard acceptance must open character selection.
  await page.keyboard.press('Enter')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('CHARACTER_SELECT')

  // The first character is focused; move right to Girl and accept with the keyboard.
  await page.keyboard.press('ArrowRight')
  await page.keyboard.press('Enter')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')

  const singleGirl = await gameState(page)
  expect(singleGirl.session).toMatchObject({
    mode: 'SINGLE',
    active_players: [1],
    selected_characters: { '1': 'girl' },
  })
  expect(singleGirl.participants.p1_head).toBe('res://resources/characters/girl_head.png')

  // Continue entirely through real touchscreen taps: return, choose multiplayer, start, cast P2.
  await tapControl(page, 'ready_return')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('MODE_SELECT')

  await tapControl(page, 'mode_multi')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')
  const readyMulti = await gameState(page)
  expect(readyMulti.session).toMatchObject({
    mode: 'LOCAL_MULTI',
    active_players: [1, 2],
  })

  await tapControl(page, 'start')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('PLAYING')

  const playing = await gameState(page)
  expect(playing.hooks['1']).toMatchObject({ input_enabled: true, state: 'SWINGING' })
  expect(playing.hooks['2']).toMatchObject({ input_enabled: true, state: 'SWINGING' })

  await tapLogicalPoint(page, playing.viewport.x * 0.75, playing.viewport.y * 0.65)
  await expect.poll(async () => (await gameState(page)).hooks['2'].state).toBe('EXTENDING')

  const launched = await gameState(page)
  expect(launched.hooks['1'].state).toBe('SWINGING')
  expect(launched.hooks['2']).toMatchObject({ input_enabled: true, state: 'EXTENDING' })
})
