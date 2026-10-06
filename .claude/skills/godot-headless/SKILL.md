---
name: godot-headless
description: 在处理需要 headless 场景加载、截图捕获或可复用 headless 辅助工具的 Godot 项目时使用本 skill。用于通过 `godot --headless` 验证场景、将捆绑的 `capture_scene.gd` 辅助脚本同步到项目中，以及为 HTML 转 Godot UI 工作运行布局截图流程。
---

# Godot Headless

## 概述

本 skill 帮助在项目中执行可重复的 Godot headless 和运行时检查工作流：场景加载检查、截图捕获、将共享的 `capture_scene.gd` 辅助脚本同步到 `scripts/tools/`，以及在需要验证截图或点击时使用项目本地窗口化交互探测。

## 使用场景

在以下情况使用本 skill：

- 以 `--headless` 模式运行 Godot 场景以捕获加载或脚本初始化错误
- 将场景捕获为 PNG 用于布局对比
- 在项目中安装或刷新共享的 `capture_scene.gd` 辅助脚本
- 在构建更多自动化之前，组织 headless 相关的项目工具
- 运行或记录项目本地运行时交互辅助工具，验证 `--headless` 之外的真实点击

不要把 headless 成功当作点击、拖动或焦点交互正常工作的证明。关于这一边界，请阅读 [references/headless-boundaries.md](references/headless-boundaries.md)。

本项目和 Godot 构建的重要边界：

- `--headless` 适用于场景加载验证
- `capture_scene.gd` 应使用真实显示驱动运行
- 捆绑的包装脚本 `scripts/run_capture_scene.py` 是截图捕获的首选方式

## 快速开始

### 1. 将截图辅助脚本同步到项目

运行：

```powershell
python .codex/skill/godot-headless/scripts/sync_capture_scene.py --project-root . --force
```

这会将捆绑的资产 `assets/godot/scripts/tools/capture_scene.gd` 复制到：

```text
scripts/tools/capture_scene.gd
```

### 2. 验证场景在 headless 模式下加载

```powershell
godot --headless --path <项目根目录> --scene res://scenes/<Scene>.tscn --quit-after 1
```

### 3. 捕获截图

```powershell
python .codex/skill/godot-headless/scripts/run_capture_scene.py --project-root . --scene res://scenes/<Scene>.tscn --output res://output/<name>.png --width 1280 --height 720
```

## 工作流程

1. 确认项目根目录和目标场景路径。
2. 如果 `scripts/tools/capture_scene.gd` 缺失或过时，用 `scripts/sync_capture_scene.py` 同步。
3. 先运行 headless 场景加载。
4. 如果场景加载成功，运行截图捕获包装脚本。
5. 报告使用的命令以及 headless 证明了什么或没能证明什么。

## 捆绑资源

### `scripts/sync_capture_scene.py`

将捆绑的 `capture_scene.gd` 复制到当前项目。在项目启动或编辑辅助脚本后刷新时使用。

### `scripts/run_capture_scene.py`

使用真实显示驱动和指定分辨率运行捕获辅助脚本。导出截图时使用此脚本而非 `--headless`。

### `assets/godot/scripts/tools/capture_scene.gd`

共享的 Godot 截图脚本。它：

- 读取命令行参数
- 通过 `SubViewport` 渲染目标场景
- 等待第一个稳定帧
- 捕获视口纹理
- 将 PNG 写入磁盘

### 项目本地交互探测

如果项目在 `scripts/autotest/` 下添加了用于真实点击验证的运行时辅助工具，请在本 skill 中记录，而不是在 HTML 转换 skill 中。在本项目中，`scripts/autotest/test_combat_hud_interactions.gd` 是示例：它运行窗口化场景，分发鼠标事件，捕获截图，并写入简短的验收报告。

### `references/headless-boundaries.md`

当用户过度依赖 headless 结果，或需要关于 headless 能验证和不能验证什么的准确措辞时阅读。
