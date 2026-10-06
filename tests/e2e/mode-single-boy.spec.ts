import { test, expect } from './fixtures'
import { clickControl, clickWaterForPlayer, gameState, openGame } from './game'

test('E2E-MODE-01 单人男孩仅启用 P1 且忽略 P2 输入', async ({ page }) => {
  await openGame(page, { setup: 'none' })

  const initial = await gameState(page)
  expect(initial.session).toMatchObject({
    state: 'MODE_SELECT',
    mode: 'NONE',
    active_players: [],
    selected_characters: {},
    setup_visible: true,
  })

  await clickControl(page, 'mode_single')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('CHARACTER_SELECT')

  await clickControl(page, 'character_boy')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')

  const ready = await gameState(page)
  expect(ready.session).toMatchObject({
    mode: 'SINGLE',
    active_players: [1],
    selected_characters: { '1': 'boy' },
    setup_visible: false,
  })
  expect(ready.participants).toMatchObject({
    boat_1_visible: true,
    boat_2_visible: false,
    hook_1_visible: true,
    hook_2_visible: false,
    p1_head: 'res://resources/characters/boy_head.png',
  })

  await clickControl(page, 'start')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('PLAYING')

  const playing = await gameState(page)
  expect(playing.hooks['1']).toMatchObject({ input_enabled: true, state: 'SWINGING' })
  expect(playing.hooks['2']).toMatchObject({ input_enabled: false, state: 'DISABLED' })
  expect(playing.events.shots).toHaveLength(0)

  // P is the real P2 keyboard binding. In single-player mode it must remain inert.
  await expect(page.locator('canvas')).toBeFocused()
  await page.keyboard.press('KeyP')
  await page.waitForFunction(() => {
    const state = window.__fishingBabyE2EState
    const stable = state?.hooks?.['2']?.state === 'DISABLED'
      && state.hooks['2'].input_enabled === false
      && state.events.shots.length === 0
    const timings = window as unknown as Record<string, number>
    if (!stable) {
      delete timings.__singleBoyP2Stable
      return false
    }
    timings.__singleBoyP2Stable ??= performance.now()
    return performance.now() - timings.__singleBoyP2Stable >= 500
  }, undefined, { polling: 'raf', timeout: 2_000 })

  // A real water click still launches the only active player.
  await clickWaterForPlayer(page, 1)
  await expect.poll(async () => (await gameState(page)).hooks['1'].state).toBe('EXTENDING')

  const launched = await gameState(page)
  expect(launched.hooks['1'].input_enabled).toBe(true)
  expect(launched.hooks['2']).toMatchObject({ input_enabled: false, state: 'DISABLED' })
  expect(launched.participants).toMatchObject({
    boat_1_visible: true,
    boat_2_visible: false,
    hook_1_visible: true,
    hook_2_visible: false,
  })
})
