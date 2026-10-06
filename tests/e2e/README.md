# Playwright E2E 测试

本目录覆盖 Web 版完整玩家流程。测试通过真实 Godot canvas 点击和键盘输入驱动游戏；`?e2e=1` 状态桥只在 `Web E2E` 自定义导出特性中启用，用于读取可观察状态和建立确定性测试数据，普通 `Web` 导出不会注册测试命令。

## 运行

首次安装：

```powershell
npm install
npx playwright install chromium
```

运行完整 Chrome/Edge 矩阵：

```powershell
npm run test:e2e
```

分别运行：

```powershell
npm run test:e2e:chromium
npm run test:e2e:edge
```

`e2e:export` 会使用 `Web E2E` preset 生成 `tmp/build/web_e2e/`。Playwright 配置随后通过 `tools/serve_web.py` 在契约端口 8000 提供带跨源隔离响应头的静态服务。Godot WebGL/WASM 在当前机器并行运行不稳定，因此正式配置固定为单 worker。

当前存在已确认的产品缺陷，完整命令会以非零状态退出。不要跳过或削弱失败断言；修复产品后按失败台账逐项复跑。

## 用例矩阵

| ID | Spec | 覆盖 |
|---|---|---|
| E2E-CORE-01 | `start-empty.spec.ts` | READY、真实开始、输入消费、鼠标/Space 空钩零分 |
| E2E-CORE-02 | `capture-scoring.spec.ts` | 真实捕获、当帧挂钩、显示层级、单次交付计分 |
| E2E-WAVE-01 | `waves.spec.ts` | 0/30/60 秒三波、旧波保留、反馈唯一性 |
| E2E-WAVE-02 | `wave-hidden-collision.spec.ts` | 隐藏波次目标真实空钩零分、激活同 ID 后正常捕获 |
| E2E-PWR-01 | `powerup-speed.spec.ts` | P1 加速、继续伸钩、HUD、到期恢复 |
| E2E-PWR-02 | `powerup-giant-hook.spec.ts` | P2 巨钩、玩家隔离、视觉/碰撞热点、到期恢复 |
| E2E-PWR-03 | `powerup-freeze.spec.ts` | 全局冰冻、仍可捕获、非水生隔离、续动 |
| E2E-COMP-01 | `powerup-race.spec.ts` | 双钩左右分区与道具唯一消费 |
| E2E-RESULT-01 | `result-win-restart.spec.ts` | 1800 分即时胜利、禁用输入、完整重开复原 |
| E2E-RESULT-02 | `result-timeout.spec.ts` | 超时高分胜利、同分平局、连续重开 |
| E2E-VIEW-01 / E2E-VIEW-02 | `viewport-matrix.spec.ts` | 1920×1080、1280×720、1365×768 横屏与 390×844、768×1024 竖屏布局、截图和水域输入 |

共享文件：

- `fixtures.ts`：自动收集并断言 console error 与 pageerror。
- `game.ts`：游戏打开、状态读取、命令、canvas 坐标映射和真实控件点击。
- `scripts/tools/e2e_bridge.gd`：仅 E2E Web 构建启用的状态与确定性场景桥。

当前聚合结果与缺陷证据见 `docs/testing/playwright-e2e-report.md` 和 `docs/testing/playwright-e2e-failures.md`。
