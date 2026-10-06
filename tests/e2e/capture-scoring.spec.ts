import { test, expect } from './fixtures'
import { command, gameState, openGame, startRound, clickWaterForPlayer } from './game'

const TARGET_ID = 'blue-small-01'

test.describe('真实捕获与计分', () => {
  test('E2E-CORE-02 目标当帧挂钩并在送达时只计分一次', async ({ page, browserErrors }) => {
    void browserErrors

    await openGame(page)
    await startRound(page)

    const baseline = await gameState(page)
    const initialP1Score = baseline.round.scores['1']
    const initialP2Score = baseline.round.scores['2']
    const expectedScore = baseline.entities[TARGET_ID].score

    expect(initialP1Score).toBe(0)
    expect(expectedScore).toBeGreaterThan(0)

    await command(page, 'clear_events')
    await command(page, 'prepare_entity', { id: TARGET_ID, player: 1, isolate: true })

    // Arm a frame-level observer before the click because this lightweight fish
    // can complete its retraction between two Node-side Playwright polls.
    const hookedObservation = page.waitForFunction(id => {
      const state = window.__fishingBabyE2EState
      const target = state?.entities?.[id]
      if (target?.state !== 'HOOKED' || state?.events?.catches?.length !== 1) return false
      return structuredClone({
        targetState: target.state,
        carrierDistance: target.carrier_distance,
        visible: target.visible,
        zIndex: target.z_index,
        hookState: state.hooks['1'].state,
        catches: state.events.catches,
        deliveryCount: state.events.deliveries.length,
      })
    }, TARGET_ID, { polling: 'raf', timeout: 5_000 })

    await clickWaterForPlayer(page, 1)

    const hooked = await (await hookedObservation).jsonValue()
    expect(hooked.targetState).toBe('HOOKED')
    expect(hooked.carrierDistance).toBeCloseTo(0, 2)
    expect(hooked.visible).toBe(true)
    expect(hooked.zIndex).toBeGreaterThan(11)
    expect(hooked.zIndex).toBeLessThan(20)
    expect(hooked.hookState).toBe('RETRACTING_CATCH')
    expect(hooked.catches).toEqual([{ player: 1, id: TARGET_ID }])
    expect(hooked.deliveryCount).toBe(0)

    await expect.poll(async () => {
      const state = await gameState(page)
      return {
        targetState: state.entities[TARGET_ID].state,
        visible: state.entities[TARGET_ID].visible,
        hookState: state.hooks['1'].state,
        deliveryCount: state.events.deliveries.length,
        p1Score: state.round.scores['1'],
      }
    }, { timeout: 5_000 }).toEqual({
      targetState: 'COLLECTED',
      visible: false,
      hookState: 'SWINGING',
      deliveryCount: 1,
      p1Score: initialP1Score + expectedScore,
    })

    const delivered = await gameState(page)
    expect(delivered.round.scores['2']).toBe(initialP2Score)
    expect(delivered.events.deliveries).toEqual([
      { player: 1, id: TARGET_ID, score: expectedScore },
    ])
    expect(delivered.events.shots).toEqual([{ player: 1, caught: true }])
    expect(delivered.hud.score).toContain(`P1: ${initialP1Score + expectedScore} /`)

    // Let the visible round timer advance, then prove delivery and score stayed singular.
    const secondsAtDelivery = delivered.round.seconds_left
    await expect.poll(async () => (await gameState(page)).round.seconds_left, {
      timeout: 2_500,
    }).toBeLessThan(secondsAtDelivery)

    const stable = await gameState(page)
    expect(stable.events.catches).toHaveLength(1)
    expect(stable.events.deliveries).toHaveLength(1)
    expect(stable.round.scores['1']).toBe(initialP1Score + expectedScore)
    expect(stable.entities[TARGET_ID].state).toBe('COLLECTED')
    expect(stable.entities[TARGET_ID].visible).toBe(false)
    expect(stable.hooks['1'].state).toBe('SWINGING')
  })
})
