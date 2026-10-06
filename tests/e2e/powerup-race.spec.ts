import { test, expect } from './fixtures'
import { clickWaterForPlayer, command, gameState, openGame, startRound } from './game'

const POWERUP_ID = 'speed-reel-01'
const POWERUP_DEFINITION_ID = 'speed-reel'

test('E2E-COMP-01 双钩同时争抢同一道具，仅一方消费', async ({ page, browserErrors }) => {
  await openGame(page)
  await startRound(page)
  await command(page, 'clear_events')
  await command(page, 'prepare_powerup_race', { id: POWERUP_ID })

  // These are consecutive real canvas clicks in the documented left/right zones.
  await clickWaterForPlayer(page, 1)
  await expect.poll(async () => (await gameState(page)).hooks['1'].state).toBe('EXTENDING')
  await clickWaterForPlayer(page, 2)
  await expect.poll(async () => (await gameState(page)).hooks['2'].state).toBe('EXTENDING')

  await expect.poll(async () => {
    const state = await gameState(page)
    return {
      powerupState: state.entities[POWERUP_ID].state,
      eventCount: state.events.powerups.length,
    }
  }, { timeout: 5_000 }).toEqual({ powerupState: 'CONSUMED', eventCount: 1 })

  const resolved = await gameState(page)
  const event = resolved.events.powerups[0]
  expect(event).toMatchObject({ id: POWERUP_DEFINITION_ID })
  expect([1, 2]).toContain(event.player)

  const winner = String(event.player)
  const loser = event.player === 1 ? '2' : '1'
  expect(resolved.hooks[winner].speed_multiplier).toBeCloseTo(1.75, 5)
  expect(resolved.hooks[loser].speed_multiplier).toBe(1)
  expect(resolved.hud[`p${winner}_effects`]).toContain('加速')
  expect(resolved.hud[`p${loser}_effects`]).toBe('')
  expect(resolved.events.powerups).toHaveLength(1)
  expect(resolved.events.deliveries).toHaveLength(0)
  expect(resolved.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(browserErrors).toEqual([])
})
