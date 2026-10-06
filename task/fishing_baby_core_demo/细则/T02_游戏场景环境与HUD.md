# T02 游戏场景、环境与 HUD

负责人：主 agent  
任务状态：[已完成]  
任务进度：100%

依赖：T01（开始本任务前必须为 [已完成]）  
可并发：T03、T04（契约冻结后）

## 目标

用现有美漫卡通资源固化海面/水下关卡环境和 HUD，建立后续抓钩与回合整合所需的 `RopeOrigin`、世界边界和 UI 方法边界。

## 小目标进度

| ID | 小目标 | 状态 | 交付物/证据 |
|---|---|---|---|
| G01 | 固化天空、水体、沙床和装饰层 | [已完成] | `ocean_environment.tscn` |
| G02 | 放置船、波浪和 RopeOrigin | [已完成] | 场景截图 |
| G03 | 实现分数/目标/倒计时 HUD | [已完成] | `game_hud.tscn/.gd` |
| G04 | 实现 Ready/胜/负/重开面板 | [已完成] | `round_result_overlay.tscn` |
| G05 | 通过 1920×1080 和 1280×720 布局检查 | [已完成] | Gate 2 截图占位 |

## 允许修改

- `scenes/environment/ocean_environment.tscn`
- `scenes/ui/`
- `scripts/ui/`
- 与 T02 相关的测试或验收记录

## 禁止修改

- `scripts/gameplay/hook_controller.gd`、`scenes/gameplay/hook_rig.tscn`
- `scripts/entities/`、`scenes/entities/`、`scenes/gameplay/demo_catchables.tscn`
- 冻结契约和现有美术原文件

## 实施要点

1. [已完成] 复用 `environment_sliced` 场景/贴图，所有可预知节点保存在 `.tscn`。
2. [已完成] 以 `Marker2D` 固化船上绳索起点，不把世界坐标写死到 HookController。
3. [已完成] HUD 使用现有 SVG 与 Godot 字体/Panel，无需生成新图。
4. [已完成] UI 只实现契约方法和 `restart_requested` 信号，不直接计时或计分。

```powershell
godot --headless --path . --editor --quit
```

验收标准：场景可独立加载，固定视觉层级完整，HUD 公开方法可被测试调用，两种视口下无关键遮挡或拉伸。
