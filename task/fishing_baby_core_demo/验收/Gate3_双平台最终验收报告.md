# Gate 3 双平台最终验收报告

日期：2026-08-07  
状态：[已完成]

## 结论

通过，带一项非阻塞限制：Windows 发布包已完成真实启动冒烟，原生窗口点击自动化因 computer-use 通道不可用未执行；同一玩法的完整交互已在 Edge Web 构建完成。

| 验收项 | 命令/证据 | 结果 |
|---|---|---|
| 导入 | `godot --headless --path . --import` | [已完成] |
| 主场景加载 | `godot --headless --path . --scene res://scenes/main.tscn --quit-after 3` | [已完成] |
| 核心测试 | `godot --headless --path . --script res://tests/run_core_tests.gd` | [已完成] |
| Windows 导出 | `--export-release "Windows Desktop"`；EXE 约 95 MB（含中文字体） | [已完成] |
| Windows 启动 | 导出 EXE `--headless --quit-after 3`，引擎与 PCK 正常启动 | [已完成] |
| Web 导出 | `--export-release "Web"`；HTML/JS/WASM/PCK 完整 | [已完成] |
| 无持久化/网络 | `rg` 扫描运行时代码无 `user://`、FileAccess、ConfigFile、localStorage、HTTPClient、HTTPRequest | [已完成] |

## E2E 矩阵

| 用例 | Windows | Edge Web | 证据 |
|---|---|---|---|
| E2E-01 开始与出钩 | 启动 + 自动回归 | 通过 | 点击开始，计时下降，鼠标/空格可出钩 |
| E2E-02 捕获与单次结算 | 自动回归 | 通过 | 首次实际捕获 180 分目标 |
| E2E-03 胜利与重开 | 自动回归 | 通过 | 1500/1200 胜利；Enter 重开恢复 0/1200、90 与全部目标 |
| E2E-04 失败与重开 | 自动回归 | 自动回归 | 归零失败状态与重开逻辑通过 |

Web 使用 Edge 1365×768，游戏相关控制台 error/warning 为 0。当前 4.7 beta nothreads 模板在普通 HTTP 下仍要求跨源隔离，使用 `python tools/serve_web.py --port 8000 --directory tmp/build/web` 服务；详见 ADR-006。

## 产物

- Windows：`tmp/build/windows/fishing_baby.exe`
- Web：`tmp/build/web/index.html`

## 已知限制

- 原生窗口的鼠标点击未由自动化通道复验；发布包启动、共享核心测试和 Web 完整交互均已通过。
- 换用修正后的正式 4.7 Web 模板后，应复测普通静态服务器并视结果移除隔离头辅助工具。
