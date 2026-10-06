import { expect, test } from './fixtures'
import { command, gameState, openGame, startRound, type GameState } from './game'

type EntityState = {
  wave: number
  visible: boolean
}

function waveEntities(state: GameState, wave: number): EntityState[] {
  return Object.values(state.entities).filter((entity: EntityState) => entity.wave === wave) as EntityState[]
}

function visibleByWave(state: GameState): Record<string, boolean[]> {
  return {
    '1': waveEntities(state, 1).map(entity => entity.visible),
    '2': waveEntities(state, 2).map(entity => entity.visible),
    '3': waveEntities(state, 3).map(entity => entity.visible),
  }
}

test('E2E-WAVE-01 三波刷新与旧波保留', async ({ page, browserErrors }) => {
  await openGame(page)

  const ready = await gameState(page)
  expect(ready.round.state).toBe('READY')
  expect(ready.waves.active_count).toBe(1)
  expect(waveEntities(ready, 1).length).toBeGreaterThan(0)
  expect(waveEntities(ready, 2).length).toBeGreaterThan(0)
  expect(waveEntities(ready, 3).length).toBeGreaterThan(0)
  expect(visibleByWave(ready)).toEqual({
    '1': expect.arrayContaining([true]),
    '2': expect.not.arrayContaining([true]),
    '3': expect.not.arrayContaining([true]),
  })
  expect(ready.hud.time).toBe('90')

  await startRound(page)
  await command(page, 'clear_events')

  await command(page, 'set_seconds_left', { seconds: 60 })
  await expect.poll(async () => (await gameState(page)).hud.time).toBe('60')
  await expect.poll(async () => (await gameState(page)).waves.active_count).toBe(2)
  await expect.poll(async () => (await gameState(page)).events.waves).toEqual([2])
  await expect.poll(async () => (await gameState(page)).hud.feedback).toBe('第 2 波出现！')

  const wave2 = await gameState(page)
  expect(visibleByWave(wave2)).toEqual({
    '1': expect.not.arrayContaining([false]),
    '2': expect.not.arrayContaining([false]),
    '3': expect.not.arrayContaining([true]),
  })

  await command(page, 'set_seconds_left', { seconds: 30 })
  await expect.poll(async () => (await gameState(page)).hud.time).toBe('30')
  await expect.poll(async () => (await gameState(page)).waves.active_count).toBe(3)
  await expect.poll(async () => (await gameState(page)).events.waves).toEqual([2, 3])
  await expect.poll(async () => (await gameState(page)).hud.feedback).toBe('第 3 波出现！')

  const wave3 = await gameState(page)
  expect(visibleByWave(wave3)).toEqual({
    '1': expect.not.arrayContaining([false]),
    '2': expect.not.arrayContaining([false]),
    '3': expect.not.arrayContaining([false]),
  })
  expect(wave3.events.waves.filter((wave: number) => wave === 2)).toHaveLength(1)
  expect(wave3.events.waves.filter((wave: number) => wave === 3)).toHaveLength(1)
  expect(browserErrors).toEqual([])
})
