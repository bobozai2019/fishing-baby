import { test, expect } from './fixtures'
import { clickWaterForPlayer, command, gameState, openGame, startRound } from './game'

const POWERUP_ID = 'speed-reel-01'
const POWERUP_DEFINITION_ID = 'speed-reel'

test('E2E-PWR-01 P1 个人加速即时生效并到期恢复', async ({ page, browserErrors }) => {
  await openGame(page)
  await startRound(page)
  await command(page, 'clear_events')
  await command(page, 'prepare_entity', { id: POWERUP_ID, player: 1, isolate: true })

  // Observe the collection frame because the pickup must not interrupt extension.
  const collectedObservation = page.waitForFunction(id => {
    const state = window.__fishingBabyE2EState
    const powerup = state?.entities?.[id]
    if (state?.events?.powerups?.length !== 1 || powerup?.state !== 'CONSUMED') return false
    return structuredClone({
      powerups: state.events.powerups,
      deliveries: state.events.deliveries,
      shots: state.events.shots,
      powerupState: powerup.state,
      powerupVisible: powerup.visible,
      p1HookState: state.hooks['1'].state,
      p1Speed: state.hooks['1'].speed_multiplier,
      p2Speed: state.hooks['2'].speed_multiplier,
      p1Effects: state.hud.p1_effects,
      p2Effects: state.hud.p2_effects,
      scores: state.round.scores,
      activeEffects: state.effects.active_count,
    })
  }, POWERUP_ID, { polling: 'raf', timeout: 5_000 })

  await clickWaterForPlayer(page, 1)

  const collected = await (await collectedObservation).jsonValue()
  expect(collected.powerups).toHaveLength(1)
  expect(collected.powerups[0]).toMatchObject({ player: 1, id: POWERUP_DEFINITION_ID })
  expect(collected.powerupState).toBe('CONSUMED')
  expect(collected.powerupVisible).toBe(false)
  expect(collected.p1HookState).toBe('EXTENDING')
  expect(collected.deliveries).toHaveLength(0)
  expect(collected.shots).toHaveLength(0)
  expect(collected.scores).toEqual({ '1': 0, '2': 0 })
  expect(collected.p1Speed).toBeCloseTo(1.75, 5)
  expect(collected.p2Speed).toBe(1)
  expect(collected.p1Effects).toContain('加速 5')
  expect(collected.p2Effects).toBe('')
  expect(collected.activeEffects).toBe(1)

  await command(page, 'advance_effects', { seconds: 5.1 })
  await expect.poll(async () => {
    const state = await gameState(page)
    return {
      p1Speed: state.hooks['1'].speed_multiplier,
      p2Speed: state.hooks['2'].speed_multiplier,
      p1Effects: state.hud.p1_effects,
      p2Effects: state.hud.p2_effects,
      activeEffects: state.effects.active_count,
    }
  }).toEqual({
    p1Speed: 1,
    p2Speed: 1,
    p1Effects: '',
    p2Effects: '',
    activeEffects: 0,
  })

  const expired = await gameState(page)
  expect(expired.events.powerups).toHaveLength(1)
  expect(expired.events.deliveries).toHaveLength(0)
  expect(expired.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(browserErrors).toEqual([])
})
