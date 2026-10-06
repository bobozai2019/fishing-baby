import { test, expect } from './fixtures'
import { clickWaterForPlayer, command, gameState, openGame, startRound } from './game'

const POWERUP_ID = 'giant-hook-01'
const POWERUP_DEFINITION_ID = 'giant-hook'
const MAGNITUDE = 1.6

type Point = { x: number; y: number }

function vector(from: Point, to: Point): Point {
  return { x: to.x - from.x, y: to.y - from.y }
}

function length(value: Point): number {
  return Math.hypot(value.x, value.y)
}

function hookOffsets(hook: Record<string, any>): { sprite: Point; collision: Point } {
  return {
    sprite: vector(hook.tip_position, hook.sprite_position),
    collision: vector(hook.tip_position, hook.collision_position),
  }
}

function expectScale(actual: Point, base: Point, multiplier: number): void {
  expect(actual.x).toBeCloseTo(base.x * multiplier, 5)
  expect(actual.y).toBeCloseTo(base.y * multiplier, 5)
}

function expectOffsetLengths(
  actual: { sprite: Point; collision: Point },
  base: { sprite: Point; collision: Point },
  multiplier: number,
): void {
  expect(length(actual.sprite)).toBeCloseTo(length(base.sprite) * multiplier, 3)
  expect(length(actual.collision)).toBeCloseTo(length(base.collision) * multiplier, 3)
}

test('E2E-PWR-02 P2 巨钩增大、P1 隔离、热点对齐与到期恢复', async ({ page, browserErrors }) => {
  await openGame(page)
  await startRound(page)

  const baseline = await gameState(page)
  const p1Base = structuredClone(baseline.hooks['1'])
  const p2Base = structuredClone(baseline.hooks['2'])
  const p1BaseOffsets = hookOffsets(p1Base)
  const p2BaseOffsets = hookOffsets(p2Base)

  await command(page, 'clear_events')
  await command(page, 'prepare_entity', { id: POWERUP_ID, player: 2, isolate: true })

  const collectedObservation = page.waitForFunction(id => {
    const state = window.__fishingBabyE2EState
    const powerup = state?.entities?.[id]
    if (state?.events?.powerups?.length !== 1 || powerup?.state !== 'CONSUMED') return false
    return structuredClone({
      powerupState: powerup.state,
      powerupVisible: powerup.visible,
      powerupCollisionDisabled: powerup.collision_disabled,
      powerups: state.events.powerups,
      deliveries: state.events.deliveries,
      shots: state.events.shots,
      p1Hook: state.hooks['1'],
      p2Hook: state.hooks['2'],
      p1Effects: state.hud.p1_effects,
      p2Effects: state.hud.p2_effects,
      activeEffects: state.effects.active_count,
    })
  }, POWERUP_ID, { polling: 'raf', timeout: 5_000 })

  await clickWaterForPlayer(page, 2)

  const collected = await (await collectedObservation).jsonValue()
  expect(collected.powerupState).toBe('CONSUMED')
  expect(collected.powerupVisible).toBe(false)
  expect(collected.powerupCollisionDisabled).toBe(true)
  expect(collected.powerups).toEqual([
    { player: 2, id: POWERUP_DEFINITION_ID, effect_kind: 1 },
  ])
  expect(collected.deliveries).toHaveLength(0)
  expect(collected.shots).toHaveLength(0)
  expect(collected.p2Hook.state).toBe('EXTENDING')
  expect(collected.p2Hook.size_multiplier).toBeCloseTo(MAGNITUDE, 5)
  expectScale(collected.p2Hook.sprite_scale, p2Base.sprite_scale, MAGNITUDE)
  expectScale(collected.p2Hook.collision_scale, p2Base.collision_scale, MAGNITUDE)

  expect(collected.p1Hook.size_multiplier).toBe(1)
  expectScale(collected.p1Hook.sprite_scale, p1Base.sprite_scale, 1)
  expectScale(collected.p1Hook.collision_scale, p1Base.collision_scale, 1)
  expectOffsetLengths(hookOffsets(collected.p1Hook), p1BaseOffsets, 1)

  const enlargedOffsets = hookOffsets(collected.p2Hook)
  expectOffsetLengths(enlargedOffsets, p2BaseOffsets, MAGNITUDE)
  const cross = enlargedOffsets.sprite.x * enlargedOffsets.collision.y
    - enlargedOffsets.sprite.y * enlargedOffsets.collision.x
  const dot = enlargedOffsets.sprite.x * enlargedOffsets.collision.x
    + enlargedOffsets.sprite.y * enlargedOffsets.collision.y
  expect(Math.abs(cross)).toBeLessThan(0.1)
  expect(dot).toBeGreaterThan(0)
  expect(collected.p1Effects).toBe('')
  expect(collected.p2Effects).toContain('巨钩 5')
  expect(collected.activeEffects).toBe(1)

  await command(page, 'advance_effects', { seconds: 5.1 })
  await expect.poll(async () => {
    const state = await gameState(page)
    return {
      p1Size: state.hooks['1'].size_multiplier,
      p2Size: state.hooks['2'].size_multiplier,
      p1Effects: state.hud.p1_effects,
      p2Effects: state.hud.p2_effects,
      activeEffects: state.effects.active_count,
    }
  }).toEqual({
    p1Size: 1,
    p2Size: 1,
    p1Effects: '',
    p2Effects: '',
    activeEffects: 0,
  })

  const expired = await gameState(page)
  expectScale(expired.hooks['1'].sprite_scale, p1Base.sprite_scale, 1)
  expectScale(expired.hooks['1'].collision_scale, p1Base.collision_scale, 1)
  expectScale(expired.hooks['2'].sprite_scale, p2Base.sprite_scale, 1)
  expectScale(expired.hooks['2'].collision_scale, p2Base.collision_scale, 1)
  expectOffsetLengths(hookOffsets(expired.hooks['1']), p1BaseOffsets, 1)
  expectOffsetLengths(hookOffsets(expired.hooks['2']), p2BaseOffsets, 1)
  expect(expired.events.powerups).toHaveLength(1)
  expect(expired.events.deliveries).toHaveLength(0)
  expect(expired.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(browserErrors).toEqual([])
})
