# Gate 4 Web 最终验收报告

日期：2026-08-08  
状态：[已完成]  
范围：Web 导出、浏览器双人输入、三波、道具、胜负和重开

## 结论

- 正式 Web release 导出成功；本地服务器跨源隔离头正确；1365×768 浏览器中开始按钮、左右双人点击区、计分、道具 HUD 与 Wave 3 布局均通过。
- 胜负、平局与完整重开由相同 Web 运行代码的自动回归覆盖；浏览器后台会节流游戏计时，因此 Wave 3 视觉使用同一导出流程加载 `tests/visual/wave3_capture.tscn`，不把墙钟等待冒充阈值证据。

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| Web 导出 | release export 成功且资源完整 | `tmp/build/web/index.html/.pck/.wasm` | [已完成] |
| 页面启动 | 无致命控制台或资源加载错误 | 修复后正式构建复验新增 error/warn 为 0 | [已完成] |
| 双人输入 | 左右点击/触控分区正确 | 浏览器左/右水域分别触发 P1/P2 钩；P1/P2 分数独立 | [已完成] |
| 三波与道具 | 浏览器中规则与桌面一致 | P1 实际拾取卷线器显示倒计时；`screenshots/web-wave3-1365x768.png` | [已完成] |
| 胜负与重开 | 1800/超时结算与完整重置正确 | Round/Wave/Effect restart 自动回归；Web 使用同一脚本路径 | [已完成] |

## 命令与结果

```powershell
& 'D:\godot\Godot_v4.6.2\godot.exe' --headless --path . --export-release 'Web' 'tmp/build/web/index.html'
python tools/serve_web.py --directory tmp/build/web --port 8000
```

服务器返回 `Cross-Origin-Opener-Policy: same-origin`、`Cross-Origin-Embedder-Policy: require-corp`。浏览器视口覆写为 1365×768，并检查正式构建与 Wave 3 验收构建。

## 问题与返工

| 问题 | 严重度 | 状态 |
|---|---|---|
| 道具消费在 `area_entered` 内直接修改 `monitorable`，Web 报物理信号期错误 | 中 | 已改为 `set_deferred`，重导出后新增错误为 0 |
| 浏览器后台节流导致墙钟与游戏倒计时不同步 | 低 | 逻辑阈值由自动测试验证，Web Wave 3 用专用验收场景验证视觉 |
