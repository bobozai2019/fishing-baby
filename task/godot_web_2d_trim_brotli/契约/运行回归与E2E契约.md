# 运行回归与 E2E 契约

状态：frozen（Gate 1，2026-08-09）

## 验收层级

| 层级 | 对象 | 必测内容 | 证据 |
|---|---|---|---|
| L0 | 引擎模板/PCK | 主场景加载、autoload、class_name | headless/PCK log |
| L1 | 核心逻辑 | round、hook×20、capture、data、waves、powerups | `tests/run_core_tests.gd` |
| L2 | Custom E2E | bridge、真实 canvas 输入、双钩、道具、结算、视口 | Playwright report |
| L3 | Final release 黑盒 | 无 `?e2e=1`，开始、出钩、canvas、控制台 | Playwright smoke |
| L4 | 网络 | Brotli/MIME/跨源隔离/无重复 raw 下载 | headers + HAR/response log |
| L5 | 视觉 | 中文、布局、角色和鱼贴图 | 截图 |

## 视口

- 1280×720
- 1365×768
- 1920×1080

## Release 与 E2E 差异

- `Web E2E` 允许 `custom_features="e2e"` 与 JavaScript eval bridge。
- 正式 `Web` 不得注册 `window.__fishingBabyE2ECommand`。
- 若两者模板不同，必须证明除 JS bridge/eval 外裁剪 profile 相同。
- 最终包体只统计正式 release；完整 E2E 结果不能替代 release 黑盒 smoke。

## 失败条件

1. 中文出现方框或缺字。
2. 任何资源、autoload UID、全局类型解析失败。
3. 抓钩碰撞、计分、道具或波次行为与现有契约不同。
4. 浏览器下载 `.br` 后出现 MIME/encoding 错误。
5. 控制台出现自定义模板新增 error。
