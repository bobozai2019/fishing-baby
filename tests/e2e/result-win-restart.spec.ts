import { type Page } from '@playwright/test'
import { test, expect } from './fixtures'
import { clickControl, clickWaterForPlayer, command, gameState, openGame, startRound } from './game'

async function expectWonStateStable(
  page: Page,
  secondsLeft: number,
  shotCount: number,
  key: string,
): Promise<void> {
  await page.waitForFunction(({ expectedSeconds, expectedShots, stableKey }) => {
    const state = window.__fishingBabyE2EState
    const stable = state?.round?.state === 'WON'
      && state.round.seconds_left === expectedSeconds
      && state.events.shots.length === expectedShots
      && state.hooks['1'].input_enabled === false
      && state.hooks['2'].input_enabled === false
    const timings = window as unknown as Record<string, number>
    if (!stable) {
      delete timings[stableKey]
      return false
    }
    timings[stableKey] ??= performance.now()
    return performance.now() - timings[stableKey] >= 750
  }, { expectedSeconds: secondsLeft, expectedShots: shotCount, stableKey: key }, {
    polling: 'raf',
    timeout: 3_000,
  })
}

test('E2E-RESULT-01 达到 1800 立即胜利、禁用输入并真实点击重开完整复原', async ({ page, browserErrors }) => {
  await openGame(page)
  await startRound(page)
  await command(page, 'clear_events')
  await command(page, 'award_score', { id: 'e2e-win-p1', amount: 1800, player: 1 })

  await expect.poll(async () => (await gameState(page)).round.state).toBe('WON')
  const won = await gameState(page)
  expect(won.round.scores).toEqual({ '1': 1800, '2': 0 })
  expect(won.hud.result_visible).toBe(true)
  expect(won.hud.result_title).toBe('P1 获胜！')
  expect(won.hud.result_text).toBe('P1: 1800 / 1800\nP2: 0 / 1800')
  expect(won.hooks['1']).toMatchObject({ input_enabled: false, state: 'DISABLED' })
  expect(won.hooks['2']).toMatchObject({ input_enabled: false, state: 'DISABLED' })
  expect(won.events.shots).toHaveLength(0)

  const stoppedAt = won.round.seconds_left
  await expectWonStateStable(page, stoppedAt, 0, '__resultWinTimerStable')

  // A real water click after victory must not launch either hook.
  await clickWaterForPlayer(page, 1)
  await expectWonStateStable(page, stoppedAt, 0, '__resultWinInputStable')
  const afterBlockedClick = await gameState(page)
  expect(afterBlockedClick.events.shots).toHaveLength(0)
  expect(afterBlockedClick.hooks['1'].state).toBe('DISABLED')
  expect(afterBlockedClick.hooks['2'].state).toBe('DISABLED')

  // RestartButton coordinates come from the exported Godot Control rectangle.
  await clickControl(page, 'restart')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('READY')

  const restarted = await gameState(page)
  expect(restarted.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(restarted.round.seconds_left).toBe(90)
  expect(restarted.hud.ready_visible).toBe(true)
  expect(restarted.hud.prompt).toContain('准备好了吗？')
  expect(restarted.hud.result_visible).toBe(false)
  expect(restarted.waves.active_count).toBe(1)
  expect(restarted.effects.active_count).toBe(0)
  expect(restarted.hooks['1']).toMatchObject({
    input_enabled: false,
    state: 'DISABLED',
    speed_multiplier: 1,
    size_multiplier: 1,
  })
  expect(restarted.hooks['2']).toMatchObject({
    input_enabled: false,
    state: 'DISABLED',
    speed_multiplier: 1,
    size_multiplier: 1,
  })

  const entities = Object.values(restarted.entities) as Array<Record<string, any>>
  expect(entities.length).toBeGreaterThan(0)
  for (const entity of entities) {
    expect(entity.state).toBe('AVAILABLE')
    if (entity.wave === 1) {
      expect(entity.visible).toBe(true)
      expect(entity.monitorable).toBe(true)
    } else {
      expect(entity.visible).toBe(false)
      expect(entity.monitorable).toBe(false)
    }
    if (entity.kind === 'powerup') expect(entity.state).toBe('AVAILABLE')
  }

  // StartButton remains a real canvas click after the complete reset.
  await startRound(page)
  const playingAgain = await gameState(page)
  expect(playingAgain.round.state).toBe('PLAYING')
  expect(playingAgain.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(playingAgain.round.seconds_left).toBe(90)
  expect(playingAgain.hooks['1'].input_enabled).toBe(true)
  expect(playingAgain.hooks['2'].input_enabled).toBe(true)
  expect(browserErrors).toEqual([])
})
