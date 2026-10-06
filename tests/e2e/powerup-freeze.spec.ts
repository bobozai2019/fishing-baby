import { expect, test } from './fixtures'
import { clickWaterForPlayer, command, gameState, openGame, startRound } from './game'

const POWERUP_ID = 'freeze-crystal-01'
const POWERUP_DEFINITION_ID = 'freeze-crystal'
const STATIC_MOVEMENT = 0
const AQUATIC_CATEGORIES = new Set([0, 1])

type Point = { x: number; y: number }
type EntityState = Record<string, any> & { position: Point }

function catchables(entities: Record<string, EntityState>): EntityState[] {
  return Object.values(entities).filter(entity => entity.kind === 'catchable')
}

function availableAquatic(entities: Record<string, EntityState>): EntityState[] {
  return catchables(entities).filter(entity =>
    entity.state === 'AVAILABLE' && AQUATIC_CATEGORIES.has(entity.category),
  )
}

function distance(left: Point, right: Point): number {
  return Math.hypot(left.x - right.x, left.y - right.y)
}

test('E2E-PWR-03 全局冰冻停止水生物、保持可捕获并到期续动', async ({ page, browserErrors }) => {
  await openGame(page)
  await startRound(page)

  const playing = await gameState(page)
  const movingAquatic = Object.entries(playing.entities)
    .filter(([, entity]: [string, EntityState]) =>
      entity.kind === 'catchable'
      && entity.state === 'AVAILABLE'
      && entity.visible
      && AQUATIC_CATEGORIES.has(entity.category)
      && entity.movement_kind !== STATIC_MOVEMENT,
    )
    .sort(([, left]: [string, EntityState], [, right]: [string, EntityState]) => {
      const hookX = playing.hooks['1'].tip_position.x
      return Math.abs(right.position.x - hookX) - Math.abs(left.position.x - hookX)
    })
  expect(movingAquatic.length).toBeGreaterThan(0)
  const selectedId = movingAquatic[0][0]

  await command(page, 'clear_events')
  await command(page, 'prepare_entity', { id: POWERUP_ID, player: 1, isolate: false })

  const frozenObservation = page.waitForFunction(({ powerupId, selectedEntityId }) => {
    const state = window.__fishingBabyE2EState
    const powerup = state?.entities?.[powerupId]
    if (state?.events?.powerups?.length !== 1 || powerup?.state !== 'CONSUMED') return false
    return structuredClone({
      powerup,
      powerups: state.events.powerups,
      deliveries: state.events.deliveries,
      shots: state.events.shots,
      scores: state.round.scores,
      p1HookState: state.hooks['1'].state,
      globalEffects: state.hud.global_effects,
      activeEffects: state.effects.active_count,
      entities: state.entities,
      selectedPosition: state.entities[selectedEntityId].position,
    })
  }, { powerupId: POWERUP_ID, selectedEntityId: selectedId }, { polling: 'raf', timeout: 5_000 })

  await clickWaterForPlayer(page, 1)

  const frozen = await (await frozenObservation).jsonValue()
  expect(frozen.powerup.state).toBe('CONSUMED')
  expect(frozen.powerup.visible).toBe(false)
  expect(frozen.powerup.monitorable).toBe(false)
  expect(frozen.powerups).toEqual([
    { player: 1, id: POWERUP_DEFINITION_ID, effect_kind: 2 },
  ])
  expect(frozen.p1HookState).toBe('EXTENDING')
  expect(frozen.deliveries).toHaveLength(0)
  expect(frozen.shots).toHaveLength(0)
  expect(frozen.scores).toEqual({ '1': 0, '2': 0 })
  expect(frozen.globalEffects).toContain('冰冻 5')
  expect(frozen.activeEffects).toBe(1)

  const aquatic = availableAquatic(frozen.entities)
  expect(aquatic.length).toBeGreaterThan(0)
  for (const entity of aquatic) {
    expect(entity.movement_paused).toBe(true)
    expect(entity.visible).toBe(true)
    expect(entity.monitorable).toBe(true)
  }
  const nonAquatic = catchables(frozen.entities).filter(entity => !AQUATIC_CATEGORIES.has(entity.category))
  expect(nonAquatic.length).toBeGreaterThan(0)
  for (const entity of nonAquatic) expect(entity.movement_paused).toBe(false)

  await expect.poll(async () => (await gameState(page)).hud.global_effects).toContain('冰冻 4')
  const stillFrozen = await gameState(page)
  expect(stillFrozen.entities[selectedId].position.x).toBeCloseTo(frozen.selectedPosition.x, 5)
  expect(stillFrozen.entities[selectedId].position.y).toBeCloseTo(frozen.selectedPosition.y, 5)

  await command(page, 'advance_effects', { seconds: 5.1 })
  await expect.poll(async () => {
    const state = await gameState(page)
    return {
      globalEffects: state.hud.global_effects,
      activeEffects: state.effects.active_count,
      paused: catchables(state.entities).filter(entity => entity.movement_paused).length,
    }
  }).toEqual({ globalEffects: '', activeEffects: 0, paused: 0 })

  await expect.poll(async () => {
    const state = await gameState(page)
    return distance(state.entities[selectedId].position, frozen.selectedPosition)
  }).toBeGreaterThan(1)

  const resumed = await gameState(page)
  expect(resumed.entities[selectedId].movement_paused).toBe(false)
  expect(resumed.events.powerups).toHaveLength(1)
  expect(browserErrors).toEqual([])
})
