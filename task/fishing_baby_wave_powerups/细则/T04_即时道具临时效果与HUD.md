# T04 即时道具、临时效果与 HUD

负责人：主 agent  
任务状态：[已完成]  
任务进度：100%

依赖：T01

可并发：PowerupPickup 与 PowerupEffectController 单元测试可并行；Hook、Main 和 HUD 集成需串行。

## 目标

实现三种即时道具、个人/全局临时效果、同类刷新规则和 HUD 倒计时，并确保道具碰撞不中断当前出钩。

## 小目标进度

| ID | 小目标 | 状态 | 交付物/证据 |
|---|---|---|---|
| G01 | 道具实体、场景与即时消费 | [已完成] | PowerupPickup 测试 |
| G02 | 个人速度与大钩效果 | [已完成] | Hook 倍率与对齐测试 |
| G03 | 全局冰冻 | [已完成] | aquatic_life 暂停测试 |
| G04 | 计时、同类刷新和回合清除 | [已完成] | EffectController 测试 |
| G05 | P1/全局/P2 HUD 状态行 | [已完成] | HUD 状态和截图 |

## 允许修改

- 新增道具实体脚本/场景与效果控制器
- `scripts/gameplay/hook_controller.gd`
- `scripts/main.gd` 中道具、效果和 HUD 接线
- `scripts/ui/game_hud.gd`、`scenes/ui/game_hud.tscn`
- `scenes/gameplay/hook_rig.tscn` 仅必要碰撞 mask 调整
- `tests/` 中道具、Hook、效果和 HUD 测试
- 本任务包状态和验收文件

## 禁止修改

- 波次时间、实例表、分值和目标分
- 现有输入映射与胜负状态机
- 背景、船和无关 UI

## 实施内容

1. 道具使用独立碰撞层，Hook mask 同时检测 Catchable 与 PowerupPickup。
2. `consume()` 成功后隐藏/禁用并发出 Hook 信号，Hook 保持 EXTENDING。
3. EffectController 按 `(effect_kind, player_id)` 管理计时；同类重取重置为 5 秒。
4. 速度倍率应用于伸出和两种收回；尺寸倍率从基础值重算精灵、碰撞和热点偏移。
5. 冰冻调用 `aquatic_life` group，AVAILABLE 目标仍可捕获。
6. HUD 状态行按 P1/全局/P2 显示向上取整秒数，0 秒隐藏。
7. 回合结束和重开清除全部效果。

## 验收标准

- 道具触发不进入 RETRACTING_CATCH，不计分且一次只能被一个钩消费。
- 加速仅作用于拾取者，倍率为 1.75，摆动不变。
- 大钩仅作用于拾取者，倍率为 1.60，绳端和碰撞对齐。
- 冰冻全局生效 5 秒，不影响垃圾、宝物和道具。
- 同类效果只刷新时长，不叠加；不同效果可共存。
- 回合结束和重开后所有倍率为 1.0、无冰冻、HUD 无残留。

## 验收命令

```powershell
& 'D:\godot\Godot_v4.6.2\godot.exe' --headless --path . --script res://tests/run_core_tests.gd
```
