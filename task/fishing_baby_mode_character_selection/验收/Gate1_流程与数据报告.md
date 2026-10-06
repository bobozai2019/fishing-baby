# Gate 1 流程与数据报告

日期：2026-08-10

## 结论

- 通过。

## 证据

| 验收项 | 证据 | 结果 |
|---|---|---|
| 男孩、女孩 Resource 合法 | 核心测试加载并调用 `is_valid_definition()` | pass |
| 第三角色扩展 | 测试动态加入第三 Resource，排序结果为 3 项，选择 UI 自动生成第三张卡 | pass |
| 非法会话迁移拒绝 | 未选模式确认角色、未知角色、PLAYING 返回菜单均返回 false 且状态不变 | pass |
| 单人活动玩家 | `active_player_ids=[1]`；P2 计分与个人道具被拒绝 | pass |
| 单人结算 | P1 达标胜利；未达目标超时进入 LOST | pass |

验证命令：

```powershell
godot --headless --path . --script tests/run_core_tests.gd
```

结果：`CORE TESTS PASSED (scene, session, single player, round, hook x20, capture, data, movement, waves, powerups)`。
