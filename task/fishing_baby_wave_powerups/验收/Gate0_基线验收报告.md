# Gate 0 基线验收报告

日期：2026-08-08  
状态：[已完成]  
范围：Godot 构建、仓库、当前测试、主场景与 Web preset

## 结论

- 基线可复现。核心测试通过，主场景在 headless 模式下无致命解析或初始化错误，双钩、双人输入和 Web preset 均存在。
- 任务文档指定的可执行文件路径有效，但实际版本为 `4.7.beta.custom_build.dff2b9bb6`，不是路径名所暗示的 4.6.2；后续验收统一记录实际版本。

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| Godot 版本 | 与项目基线一致 | `4.7.beta.custom_build.dff2b9bb6` | [已完成] |
| 核心测试 | 当前测试通过或基线失败被准确记录 | `CORE TESTS PASSED (scene, round, hook x20, capture delivery, catchable)` | [已完成] |
| 主场景加载 | 无致命解析或初始化错误 | headless 运行 3 帧，退出码 0 | [已完成] |
| 双钩与输入 | P1/P2 节点和输入路径存在 | `HookRigP1/P2`；`cast_hook_p1` 为左键/Q，`cast_hook_p2` 为右键/P | [已完成] |
| 导出预设 | Web 存在，Windows 不在本任务恢复 | `export_presets.cfg` 仅含 `Web` | [已完成] |

## 命令与结果

```powershell
& 'D:\godot\Godot_v4.6.2\godot.exe' --version
& 'D:\godot\Godot_v4.6.2\godot.exe' --headless --path . --script res://tests/run_core_tests.gd
& 'D:\godot\Godot_v4.6.2\godot.exe' --headless --path . --scene res://scenes/main.tscn --quit-after 3
```

关键输出：版本命令返回 `4.7.beta.custom_build.dff2b9bb6`；测试打印 `CORE TESTS PASSED`；主场景加载退出码为 0。

## 问题与返工

| 问题 | 严重度 | 状态 |
|---|---|---|
| 可执行文件目录名与实际 Godot 版本不一致 | 低 | 已记录，不阻塞 |
