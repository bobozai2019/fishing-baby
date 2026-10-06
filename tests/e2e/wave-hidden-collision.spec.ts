import { test, expect } from './fixtures'
import { clickWaterForPlayer, command, gameState, openGame, startRound } from './game'

const TARGET_ID = 'pufferfish-01'

test('E2E-WAVE-02 隐藏波次目标不可捕获，激活后可捕获', async ({ page, browserErrors }) => {
  test.setTimeout(45_000)

  await openGame(page)
  await startRound(page)
  await command(page, 'clear_events')
  await command(page, 'prepare_inactive_entity', { id: TARGET_ID, player: 1 })

  const hidden = await gameState(page)
  const expectedScore = hidden.entities[TARGET_ID].score
  expect(hidden.entities[TARGET_ID]).toMatchObject({
    wave: 2,
    state: 'AVAILABLE',
    visible: false,
    monitorable: false,
    collision_disabled: true,
    movement_paused: true,
  })
  expect(hidden.round.scores).toEqual({ '1': 0, '2': 0 })

  await clickWaterForPlayer(page, 1)
  await expect
    .poll(async () => (await gameState(page)).events.shots.length, { timeout: 15_000 })
    .toBe(1)

  const missed = await gameState(page)
  expect(missed.events.shots).toEqual([{ player: 1, caught: false }])
  expect(missed.events.catches).toHaveLength(0)
  expect(missed.events.deliveries).toHaveLength(0)
  expect(missed.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(missed.entities[TARGET_ID]).toMatchObject({
    state: 'AVAILABLE',
    visible: false,
    monitorable: false,
    collision_disabled: true,
  })

  await command(page, 'clear_events')
  await command(page, 'prepare_entity', { id: TARGET_ID, player: 1, isolate: true })

  const active = await gameState(page)
  expect(active.entities[TARGET_ID]).toMatchObject({
    state: 'AVAILABLE',
    visible: true,
    monitorable: true,
    collision_disabled: false,
  })
  expect(active.entities[TARGET_ID].position).toEqual(hidden.entities[TARGET_ID].position)

  await clickWaterForPlayer(page, 1)
  await expect.poll(async () => {
    const state = await gameState(page)
    return {
      hookState: state.hooks['1'].state,
      catches: state.events.catches,
      deliveries: state.events.deliveries,
      shots: state.events.shots,
      scores: state.round.scores,
      targetState: state.entities[TARGET_ID].state,
    }
  }, { timeout: 15_000 }).toEqual({
    hookState: 'SWINGING',
    catches: [{ player: 1, id: TARGET_ID }],
    deliveries: [{ player: 1, id: TARGET_ID, score: expectedScore }],
    shots: [{ player: 1, caught: true }],
    scores: { '1': expectedScore, '2': 0 },
    targetState: 'COLLECTED',
  })

  expect(browserErrors).toEqual([])
})
