# Playwright E2E 失败台账

## 2026-08-08 - PLAYING 状态下 Space 无法触发 P1

- Scope: `tests/e2e/start-empty.spec.ts`，Web canvas 键盘输入
- Command: `npx playwright test --project=chromium`、`npx playwright test --project=edge`
- Status: resolved
- Classification: product-bug
- Evidence: canvas 已聚焦，鼠标 P1 空钩能够完成且保持零分；按 Space 后等待 15 秒仍无 shot，P1 保持 `SWINGING`。两个浏览器首跑与 retry 一致，无 console/pageerror。
- Reproduction: 开始回合；点击 canvas；确认 P1 为 `SWINGING`；按 Space；观察 shot 事件。
- Expected: Space 发射 P1，空场最终产生 `{ player: 1, caught: false }`。
- Actual: 无 shot 事件。
- Next action: 调整 `Main._unhandled_input()` 分支；PLAYING 时不能让同样绑定 Space 的 `start_round` 条件阻止 `cast_hook` 处理。
- Resolution: `start_round` 仅在 READY 状态消费输入；2026-08-09 Chromium 回归确认鼠标与 Space 空钩均产生 P1 `caught=false`、保持零分。

## 2026-08-08 - 主场景挂钩目标持续落后一物理帧

- Scope: `tests/e2e/capture-scoring.spec.ts`，真实捕获与当帧挂钩
- Command: `npx playwright test --project=chromium`、`npx playwright test --project=edge`
- Status: resolved
- Classification: product-bug
- Evidence: RAF 观察器稳定捕获 `HOOKED`、catch=1、delivery=0；目标与 carrier 距离在 Chromium 为 8.23529px、Edge 为 8.23532px。两个浏览器 retry 一致。
- Reproduction: 开始回合；将目标布置在 P1 路径；真实点击发射；逐帧读取 HOOKED 目标与钩爪碰撞中心距离。
- Expected: 距离小于 0.1px，与核心回归和设计文档一致。
- Actual: 目标持续落后约 8.24px。
- Next action: 修正主场景处理顺序或挂钩跟随机制，确保 Catchable 使用当前物理帧的钩爪位置。
- Resolution: HookRig 更新本帧绳长和碰撞点后同步已挂钩目标；2026-08-09 Chromium 回归确认 `carrierDistance` 接近 0 且仅交付计分一次。

## 2026-08-08 - 右侧水域左键错误发射 P1

- Scope: `tests/e2e/powerup-giant-hook.spec.ts`、`tests/e2e/powerup-race.spec.ts`，左右点击分区
- Command: `npx playwright test --project=chromium`、`npx playwright test --project=edge`
- Status: resolved
- Classification: product-bug
- Evidence: P2 路径上的巨钩保持 AVAILABLE；竞态用例中左区点击使 P1 进入 `EXTENDING`，随后右区点击后 P2 始终 `SWINGING`。两个浏览器首跑与 retry 一致。
- Reproduction: 开始回合；左键点击右侧水域；观察 P1/P2 状态。
- Expected: P2 进入 `EXTENDING`。
- Actual: 普通左键先匹配 `cast_hook_p1`，区域分流未执行。
- Next action: 让普通鼠标左键先按水域位置决定玩家；保留独立键盘动作，但避免与通用鼠标动作重叠抢占。
- Resolution: 鼠标左键和触摸现在优先按水域坐标分区；2026-08-09 Chromium 的 P2 巨钩与双钩竞态用例均通过。

## 2026-08-08 - 重开后隐藏波次实体重新变为可碰撞

- Scope: `tests/e2e/result-win-restart.spec.ts`，完整重开复原
- Command: `npx playwright test --project=chromium`、`npx playwright test --project=edge`
- Status: resolved
- Classification: product-bug
- Evidence: 1800 分胜利、计时停止、禁用输入和真实重开均通过；重开后 Wave2/3 实体 `visible=false`，但 `monitorable=true`。两个浏览器首跑与 retry 一致。
- Reproduction: 开始回合；达到 1800 分；真实点击重开；读取 Wave2/3 Area2D 状态。
- Expected: 隐藏且不可碰撞，直到波次激活。
- Actual: 隐藏实体恢复 monitorable，存在“看不见目标却被钩中计分”的风险。
- Next action: 修正 `reset_catchable/reset_powerup` 与 `set_wave_active(false)` 的 deferred 写入顺序，确保最终禁用状态不会被帧末覆盖。
- Resolution: 已将波次激活状态直接传入 reset，并由 `E2E-WAVE-02` 验证隐藏目标真实出钩为空、激活同 ID 后可正常捕获。

## 2026-08-09 - Web 导出无法创建 res://logs

- Scope: `tests/e2e/wave-hidden-collision.spec.ts`
- Command: `npx playwright test tests/e2e/wave-hidden-collision.spec.ts --project=chromium`
- Status: resolved
- Classification: environment
- Evidence: 隐藏态空钩和激活后捕获的业务断言全部通过；自动 `browserErrors` fixture 捕获 `Could not create directory: 'res://logs'`，重试结果一致。
- Reproduction: 导出 Web E2E 构建；打开 `/?e2e=1`；运行 E2E-WAVE-02。
- Expected: Web 页面无 console error。
- Actual: Web 导出运行时尝试写入只读的 `res://logs`。
- Next action: 已将日志路径改为 `user://logs/godot.log`；同一 Chromium 用例重跑通过（1 passed）。

## 2026-08-10 - Web 导出遗漏竖屏九宫格背景资源

- Scope: `tests/e2e/viewport-matrix.spec.ts`，Web 视口布局
- Command: `npx playwright test tests/e2e/viewport-matrix.spec.ts --project=chromium --retries=0`
- Status: resolved
- Classification: environment
- Evidence: 主场景可运行，但浏览器控制台报告九宫格背景与沙床 PNG 无 loader；导出预设明确排除了 `environment_sliced/background/**` 和 `environment_sliced/sand/**`。
- Reproduction: 导出 Web E2E 构建；打开 `/?e2e=1`；执行视口矩阵。
- Expected: 九宫格背景与沙床正常加载，浏览器无 console/page error。
- Actual: 两张新接入纹理未进入 PCK，场景退化为无背景资源。
- Next action: 已从三个 Web 导出预设的排除列表移除背景与沙床目录；重新导出并回归视口矩阵。
