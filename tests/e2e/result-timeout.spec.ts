import { expect, test } from './fixtures'
import { clickControl, command, gameState, openGame, startRound } from './game'

function expectHooksDisabled(state: Record<string, any>): void {
  expect(state.hooks['1']).toMatchObject({ input_enabled: false, state: 'DISABLED' })
  expect(state.hooks['2']).toMatchObject({ input_enabled: false, state: 'DISABLED' })
}

test('E2E-RESULT-02 超时按高分判胜与同分平局', async ({ page, browserErrors }) => {
  await openGame(page)
  await startRound(page)

  await command(page, 'award_score', {
    id: `e2e-timeout-p2-${Date.now()}`,
    amount: 500,
    player: 2,
  })
  await command(page, 'force_expire')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('WON')

  const p2Won = await gameState(page)
  expect(p2Won.round.scores).toEqual({ '1': 0, '2': 500 })
  expect(p2Won.round.seconds_left).toBe(0)
  expect(p2Won.hud.time).toBe('00')
  expect(p2Won.hud.result_visible).toBe(true)
  expect(p2Won.hud.result_title).toBe('P2 获胜！')
  expect(p2Won.hud.result_text).toBe('P1: 0 / 1800\nP2: 500 / 1800')
  expectHooksDisabled(p2Won)

  await clickControl(page, 'restart')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('READY')

  const readyAfterWin = await gameState(page)
  expect(readyAfterWin.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(readyAfterWin.round.seconds_left).toBe(90)
  expect(readyAfterWin.hud.time).toBe('90')
  expect(readyAfterWin.hud.ready_visible).toBe(true)
  expect(readyAfterWin.hud.result_visible).toBe(false)
  expectHooksDisabled(readyAfterWin)

  await startRound(page)
  const secondRound = await gameState(page)
  expect(secondRound.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(secondRound.round.seconds_left).toBe(90)

  await command(page, 'force_expire')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('DRAW')

  const draw = await gameState(page)
  expect(draw.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(draw.round.seconds_left).toBe(0)
  expect(draw.hud.time).toBe('00')
  expect(draw.hud.result_visible).toBe(true)
  expect(draw.hud.result_title).toBe('平局')
  expect(draw.hud.result_text).toBe('P1: 0 / 1800\nP2: 0 / 1800')
  expectHooksDisabled(draw)

  await clickControl(page, 'restart')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('READY')

  const readyAfterDraw = await gameState(page)
  expect(readyAfterDraw.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(readyAfterDraw.round.seconds_left).toBe(90)
  expect(readyAfterDraw.hud.time).toBe('90')
  expect(readyAfterDraw.hud.ready_visible).toBe(true)
  expect(readyAfterDraw.hud.result_visible).toBe(false)
  expectHooksDisabled(readyAfterDraw)
  expect(browserErrors).toEqual([])
})
