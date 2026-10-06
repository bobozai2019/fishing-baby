import { test, expect } from './fixtures'
import {
  clickControl,
  clickWaterForPlayer,
  command,
  gameState,
  openGame,
} from './game'

test('E2E-CORE-01 开始、Web 输入焦点与空钩零分', async ({ page }) => {
  test.setTimeout(75_000)
  // Godot's Web payload can take longer than the shared 10 s action budget
  // to compile when the complete E2E matrix is running in parallel.
  page.setDefaultTimeout(30_000)
  await openGame(page)

  const ready = await gameState(page)
  expect(ready.round.state).toBe('READY')
  expect(ready.round.scores).toEqual({ '1': 0, '2': 0 })
  expect(ready.round.target_score).toBe(1800)
  expect(ready.round.seconds_left).toBe(90)
  expect(ready.hud.score).toBe('P1: 0 / 1800\nP2: 0 / 1800')
  expect(ready.hud.time).toBe('90')
  expect(ready.hud.ready_visible).toBe(true)
  expect(ready.hud.prompt).toContain('准备好了吗？')

  // Use the exported StartButton rectangle so this remains a real canvas click.
  await clickControl(page, 'start')
  await expect.poll(async () => (await gameState(page)).round.state).toBe('PLAYING')

  // The Control must consume the click instead of passing it through as a cast.
  const started = await gameState(page)
  expect(started.hooks['1'].state).toBe('SWINGING')
  expect(started.hooks['2'].state).toBe('SWINGING')
  expect(started.events.shots).toHaveLength(0)
  expect(started.events.catches).toHaveLength(0)
  await expect
    .poll(async () => (await gameState(page)).round.seconds_left, { timeout: 3_000 })
    .toBeLessThan(90)

  await command(page, 'clear_field', { player: 1, angle: 0 })
  await command(page, 'clear_events')
  await clickWaterForPlayer(page, 1)
  await expect.poll(async () => (await gameState(page)).hooks['1'].state).toBe('EXTENDING')
  await expect
    .poll(async () => (await gameState(page)).events.shots.length, { timeout: 15_000 })
    .toBe(1)

  const mouseShot = await gameState(page)
  expect(mouseShot.events.shots).toEqual([{ player: 1, caught: false }])
  expect(mouseShot.events.deliveries).toHaveLength(0)
  expect(mouseShot.round.scores).toEqual({ '1': 0, '2': 0 })

  // The real canvas click must focus Web input; Space then casts for P1.
  await command(page, 'clear_field', { player: 1, angle: 0 })
  await command(page, 'clear_events')
  await expect(page.locator('canvas')).toBeFocused()
  await page.keyboard.press('Space')
  await expect
    .poll(async () => (await gameState(page)).events.shots.length, { timeout: 15_000 })
    .toBe(1)

  const keyboardShot = await gameState(page)
  expect(keyboardShot.events.shots).toEqual([{ player: 1, caught: false }])
  expect(keyboardShot.events.deliveries).toHaveLength(0)
  expect(keyboardShot.round.scores).toEqual({ '1': 0, '2': 0 })
})
