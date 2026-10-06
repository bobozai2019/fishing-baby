# Playwright E2E 验收报告

日期：2026-08-08  
范围：Godot Web、Chromium、Microsoft Edge、10 个玩家流程

## 结论

已从玩法设计、架构文档和两套冻结 E2E 契约生成 10 个独立 Playwright 用例。Chromium 与 Edge 结果完全一致：每个浏览器 5 个通过、5 个失败；失败归并为 4 个可重复产品缺陷，没有 console error、pageerror、资源加载或 WebGL 致命错误。

| ID | Chromium | Edge | 结果摘要 |
|---|---|---|---|
| E2E-CORE-01 | 失败 | 失败 | 鼠标空钩零分通过；PLAYING 状态 Space 被开始动作分支吞掉 |
| E2E-CORE-02 | 失败 | 失败 | 捕获成功；HOOKED 目标持续落后钩爪约 8.24px |
| E2E-WAVE-01 | 通过 | 通过 | 三波阈值、旧波保留、HUD 和反馈正确 |
| E2E-PWR-01 | 通过 | 通过 | P1 加速、隔离、倒计时和恢复正确 |
| E2E-PWR-02 | 失败 | 失败 | 右侧左键错误发射 P1，P2 无法取得巨钩 |
| E2E-PWR-03 | 通过 | 通过 | 冰冻、可捕获性、非水生隔离和续动正确 |
| E2E-COMP-01 | 失败 | 失败 | 同一右区输入缺陷阻止 P2 进入争抢 |
| E2E-RESULT-01 | 失败 | 失败 | 胜利与真实重开通过；重开后隐藏 Wave2/3 恢复可碰撞 |
| E2E-RESULT-02 | 通过 | 通过 | P2 超时获胜、平局与两次重开正确 |
| E2E-VIEW-01 | 通过 | 通过 | 三物理视口、1920×1080 逻辑布局与坐标映射正确 |

## 命令与结果

```powershell
npx playwright test --project=chromium
npx playwright test --project=edge
```

- Chromium：`5 passed, 5 failed (3.4m)`。
- Edge：`5 passed, 5 failed (3.6m)`。
- 两个项目均使用 1 worker，每个失败自动 retry 一次，结果一致。
- 改为独立 `Web E2E` preset 后冒烟复验：`waves.spec.ts` 为 `1 passed (7.3s)`。

失败截图、error context 和 retry trace 位于被忽略的 `test-results/`；HTML 报告位于 `playwright-report/`。长期问题记录见 [playwright-e2e-failures.md](playwright-e2e-failures.md)。

## 证据边界

- 真实浏览器输入覆盖 canvas 按钮、左右水域点击、焦点和键盘。
- 状态桥用于读取 Godot canvas 内不可由 DOM 定位的 HUD、状态机、实体和碰撞状态，并提供时间/实体位置等确定性测试入口。
- 视口测试保存运行截图，但布局合格由逻辑/物理坐标断言决定，不使用易碎像素基线。
- 普通 `Web` preset 不包含 `e2e` feature；仅 `Web E2E` 构建在同时带 `?e2e=1` 时注册命令 API。
