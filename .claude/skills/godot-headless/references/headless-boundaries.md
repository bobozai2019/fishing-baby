# Godot Headless 边界

## headless 适用于

- 场景加载冒烟测试
- 在初始化期间捕获缺失的脚本路径或缺失节点
- 确认场景已准备好，再进行单独的捕获步骤

## headless 不能证明

- 鼠标点击命中测试
- 拖动行为
- 焦点和选中状态正确性
- 按钮 `pressed` 行为
- 键盘和鼠标混合导航正确性
- 在本项目构建中可靠地捕获截图，因为 `--headless` 使用虚拟渲染器

## 推荐顺序

1. 运行 headless 场景加载
2. 如果需要布局对比，用 `scripts/run_capture_scene.py` 运行截图捕获
3. 单独进行真实运行时交互检查

如果项目在 `scripts/autotest/` 下已有窗口化交互探测工具，建议在此记录并复用。对于 `slg-card-test`，`scripts/autotest/test_combat_hud_interactions.gd` 是当前运行时点击检查辅助工具的示例。它属于 headless/运行时测试工具链，而非 HTML 转换 skill 本身。

## 项目说明

在本项目中，第一个捆绑辅助工具是 `capture_scene.gd`。它应位于：

```text
scripts/tools/capture_scene.gd
```

典型场景加载调用：

```powershell
godot --headless --path d:\godot\project\slg-card-test --scene res://scenes/settings2/SettingsMenu.tscn --quit-after 1
```

典型截图调用：

```powershell
python .codex\skill\godot-headless\scripts\run_capture_scene.py --project-root . --scene res://scenes/settings2/SettingsMenu.tscn --output res://html_ui/screenshots/godot/settings2/SettingsMenu-1280x720.png --width 1280 --height 720
```
