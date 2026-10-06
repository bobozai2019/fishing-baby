# Gate 2 UI 与集成报告

日期：2026-08-10

## 结论

- 通过。

## 证据

| 验收项 | 证据 | 结果 |
|---|---|---|
| 启动门禁 | E2E-MODE-01：初始 MODE_SELECT/NONE，无活动玩家 | pass |
| 单人男孩 | E2E-MODE-01：仅 P1 船/钩可见，P 键无效，P1 可真实发射 | pass |
| 单人女孩重开 | E2E-MODE-02：重开保留 SINGLE/girl 与女孩头像 | pass |
| 返回菜单并切多人 | E2E-MODE-02：选择清空、双船双钩恢复、LOCAL_MULTI READY | pass |
| 键盘焦点 | E2E-MODE-05：Enter、ArrowRight、Enter 选择女孩 | pass |
| 触控 | E2E-MODE-05：触控返回、选多人、开始并发射 P2 | pass |
| 视觉 | `setup-mode-final-1280x720.png`、`setup-characters-final-1280x720.png`、`single-girl-ready-final-1280x720.png` | pass |

窄用例均在 Chromium 实际 Web canvas 上通过，未使用任意固定等待。
