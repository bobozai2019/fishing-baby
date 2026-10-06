# Gate 0 基线与契约报告

日期：2026-08-10

## 结论

- 通过。
- 三份契约已冻结；后续如修改字段或流程语义，必须先记录 ADR 并重新验收 Gate 0。

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| 核心基线 | 现有逻辑与场景测试通过 | `godot --headless --path . --script tests/run_core_tests.gd` | pass |
| Web 基线 | Chromium 全量 E2E 通过 | `npm run test:e2e:chromium`：11 passed | pass |
| 1280×720 基线 | 当前双人准备页可完整显示 | `baseline-1280x720.png` | pass |
| 1920×1080 基线 | 当前双人准备页可完整显示 | `baseline-1920x1080.png` | pass |
| 契约冻结 | 会话、角色、场景输入契约无 P0 未决项 | `../契约/*.md` | pass |

## 基线摘要

- 核心测试包含场景、回合、20 次空钩、真实捕获、数据、运动、波次和道具。
- Chromium E2E 共 11 项，覆盖捕获计分、三类道具、双钩竞争、超时/胜负/重开、输入、视口和波次。
- `godot-headless` 只证明加载和逻辑运行；真实点击、焦点和 Web canvas 行为以 Playwright 及最终截图为准。
