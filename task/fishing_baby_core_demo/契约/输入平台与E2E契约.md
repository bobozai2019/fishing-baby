# 输入、平台与 E2E 契约

状态：`frozen`

## 1. 输入动作

| InputMap action | Windows | Web | 可用状态 | 效果 |
|---|---|---|---|---|
| `cast_hook` | 空格、鼠标左键 | 空格、鼠标左键 | `PLAYING + SWINGING` | 出钩 |
| `start_round` | 空格、回车、开始按钮 | 空格、回车、点击 | `READY` | 开始倒计时 |
| `restart_round` | 空格、回车、重开按钮 | 空格、回车、点击 | `WON/LOST` | 恢复初始关卡 |

规则：
- 同一次物理帧内的多个等价输入只触发一次迁移。
- UI 按钮点击被 `Control` 消费后，不得继续传递成为出钩。
- Web 首次点击必须能聚焦 canvas，之后空格键正常工作且不滚动页面。

## 2. 视口和渲染

| 项 | 契约 |
|---|---|
| 基准大小 | 1920×1080 |
| 拉伸 | `canvas_items` |
| 比例 | `expand`，主体不非等比拉伸 |
| 渲染 | GL Compatibility |
| 验收视口 | 1920×1080、1280×720；附加 Web 窗口 1365×768 |
| 方向 | 横屏；MVP 不对竖屏做交互优化 |

## 3. 导出预设

| 预设名 | 产物 | 必需选项 |
|---|---|---|
| `Windows Desktop` | `tmp/build/windows/fishing_baby.exe` | x86_64，启用 PCK 默认打包 |
| `Web` | `tmp/build/web/index.html` | WebGL 2/Compatibility，导出配置禁用线程；当前 4.7 beta 模板需隔离响应头 |

导出命令：

```powershell
godot --headless --path . --export-release "Windows Desktop" "tmp/build/windows/fishing_baby.exe"
godot --headless --path . --export-release "Web" "tmp/build/web/index.html"
python tools/serve_web.py --port 8000 --directory "tmp/build/web"
```

ADR-006 记录了当前 `4.7.beta.custom_build` 的 nothreads 模板仍要求跨源隔离的环境偏差；切换到修正后的正式模板后可复测普通静态服务器并移除该辅助要求。

## 4. E2E 契约

### E2E-01 开始和空钩

1. 启动 Demo，看到 `0 / 1200`、`90`与开始提示。
2. 点击开始，时间开始下降。
3. 在无目标角度出钩，抓钩到边界后空回收，分数不变。

### E2E-02 捕获和单次结算

1. 对准任意可捕获物出钩。
2. 命中后目标跟随抓钩，鱼使用 caught 视觉。
3. 到达船上后仅增加一次对应分值，目标消失，抓钩恢复摆动。

### E2E-03 胜利与重开

1. 通过测试加速/可控关卡操作达到 1200 分。
2. 立即出现胜利面板，时间停止，抓钩不接受输入。
3. 点击重开，恢复 `0 / 1200`、`90`、12 类目标和初始抓钩。

### E2E-04 失败与重开

1. 让时间归零且分数小于 1200。
2. 出现失败面板，分数不再变化。
3. 重开后恢复初始状态。

### E2E-05 平台矩阵

- Windows：E2E-01、02、03 必须通过，E2E-04 至少在编辑器或 Windows 通过一次。
- Web Chrome/Edge：E2E-01、02、03 必须通过，控制台无资源加载、WebGL 或未捕获异常。
