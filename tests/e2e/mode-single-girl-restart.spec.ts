import { test, expect } from './fixtures'
import { clickControl, command, gameState, openGame } from './game'

test('E2E-MODE-02 单人女孩重开保留选择并可返回切换多人', async ({ page }) => {
  await openGame(page, { setup: 'none' })
  await clickControl(page, 'mode_single')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('CHARACTER_SELECT')
  await clickControl(page, 'character_girl')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')

  await clickControl(page, 'start')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('PLAYING')
  await command(page, 'award_score', { id: 'e2e-single-girl-first-win', amount: 1800, player: 1 })
  await expect.poll(async () => (await gameState(page)).session.state).toBe('RESULT')

  const firstResult = await gameState(page)
  expect(firstResult.round.state).toBe('WON')
  expect(firstResult.round.scores).toEqual({ '1': 1800, '2': 0 })
  expect(firstResult.participants.p1_head).toBe('res://resources/characters/girl_head.png')

  // Restart through the visible result control, preserving the configured session.
  await clickControl(page, 'restart')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')

  const restarted = await gameState(page)
  expect(restarted.round.state).toBe('READY')
  expect(restarted.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(restarted.session).toMatchObject({
    mode: 'SINGLE',
    active_players: [1],
    selected_characters: { '1': 'girl' },
  })
  expect(restarted.participants).toMatchObject({
    boat_1_visible: true,
    boat_2_visible: false,
    hook_1_visible: true,
    hook_2_visible: false,
    p1_head: 'res://resources/characters/girl_head.png',
  })

  await clickControl(page, 'start')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('PLAYING')
  await command(page, 'award_score', { id: 'e2e-single-girl-second-win', amount: 1800, player: 1 })
  await expect.poll(async () => (await gameState(page)).session.state).toBe('RESULT')

  // Return through the result overlay and verify the unconfigured presentation is restored.
  await clickControl(page, 'result_return')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('MODE_SELECT')

  const returned = await gameState(page)
  expect(returned.session).toMatchObject({
    mode: 'NONE',
    active_players: [],
    selected_characters: {},
    setup_visible: true,
  })
  expect(returned.participants).toMatchObject({
    boat_1_visible: true,
    boat_2_visible: true,
    hook_1_visible: true,
    hook_2_visible: true,
  })

  await clickControl(page, 'mode_multi')
  await expect.poll(async () => (await gameState(page)).session.state).toBe('READY')

  const multiplayer = await gameState(page)
  expect(multiplayer.session).toMatchObject({
    mode: 'LOCAL_MULTI',
    active_players: [1, 2],
    selected_characters: { '1': 'boy', '2': 'girl' },
    setup_visible: false,
  })
  expect(multiplayer.participants).toMatchObject({
    boat_1_visible: true,
    boat_2_visible: true,
    hook_1_visible: true,
    hook_2_visible: true,
  })
})
