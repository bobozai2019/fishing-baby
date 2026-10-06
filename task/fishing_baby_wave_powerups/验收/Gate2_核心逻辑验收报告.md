# Gate 2 核心逻辑验收报告

日期：2026-08-08  
状态：[已完成]  
范围：数据、移动、波次、道具、效果、计分和重开

## 结论

- 数据、移动、三波、即时道具、临时效果、1800 分胜负与重开均通过完整自动回归；主场景 headless 加载无致命错误。

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| Resource | 7 份新定义合法且 ID 唯一 | 数据契约测试；19 个 definition/instance ID 唯一 | [已完成] |
| 移动 | 四种新轨迹、暂停、恢复与重置正确 | DRIFT/VERTICAL/ZIGZAG/ELLIPSE、冰冻可捕获与恢复测试 | [已完成] |
| 波次 | 0/30/60、幂等、跨波保留正确 | 29.9/30/60、大步进、重复调用与 reset 测试 | [已完成] |
| 道具 | 即时消费、双人归属、5 秒与刷新正确 | EXTENDING 保持、一次消费、P1/P2 隔离、刷新/共存/clear 测试 | [已完成] |
| 回合 | 1800 分、超时胜负和重开正确 | 目标分、独立计分、超时比较与 restart 测试 | [已完成] |
| 捕获计分回归 | 空钩不交付；有效目标当帧挂在钩爪上且只计分一次 | 连续 20 次空钩为 0 次交付/0 次命中；真实碰撞验证 HOOKED、挂载点和单次分数 | [已完成] |

## 命令与结果

```powershell
& 'D:\godot\Godot_v4.6.2\godot.exe' --headless --path . --script res://tests/run_core_tests.gd
& 'D:\godot\Godot_v4.6.2\godot.exe' --headless --path . --scene res://scenes/main.tscn --quit-after 3
```

关键输出：`CORE TESTS PASSED (scene, round, hook x20, capture, data, movement, waves, powerups)`；两条命令退出码均为 0。

### 2026-08-08 缺陷回归补充

修复“视觉上未勾到鱼但仍然得分”：捕获目标原先在下一物理帧才跟随绳端，命中当帧可能仍停留在原位置；交付代码也只检查缓存引用是否有效，没有二次确认 `HOOKED` 状态。现改为命中当帧吸附到钩爪碰撞中心，并在交付前校验目标仍处于 `HOOKED`。

回归命令：

```powershell
godot --headless --path . --script res://tests/run_core_tests.gd
godot --headless --path . --scene res://scenes/main.tscn --quit-after 2
```

结果：核心测试输出 `CORE TESTS PASSED`，主场景加载退出码为 0。Headless 验证覆盖状态、信号、挂载坐标与场景初始化；最终视觉手感仍应在窗口化运行中检查。

## 问题与返工

| 问题 | 严重度 | 状态 |
|---|---|---|
| 命中当帧目标尚未附着到钩爪，造成“空钩得分”的视觉与计分不一致 | 中 | [已修复]：即时吸附、交付状态校验及空钩回归已通过 |
