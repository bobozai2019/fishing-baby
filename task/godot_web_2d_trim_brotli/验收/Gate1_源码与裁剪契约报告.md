# Gate 1 源码与裁剪契约报告

日期：2026-08-09  
结论：[已完成] PASS

| 项 | 结果 | 证据 |
|---|---|---|
| 隔离源码 | 官方 4.7.1 stable commit 精确匹配，clean | `tools/godot_web_template/godot` |
| Build profile | 保留 GDScript、Godot 2D physics、OpenGL/WebGL、fallback text、WebP；禁用 3D/3D physics/navigation/XR/advanced GUI/RenderingDevice/Forward renderers 与未使用模块 | `tools/godot_web_template/fishing_baby_2d.gdbuild` |
| 中文 | fallback text + 205 字符字体子集，中文 HUD 无缺字 | `screenshots/gate4-release-1280x720.png` |
| 纹理 | 运行时 `.ctex` 确认为 WebP，保留 `module_webp`，Basis 不需要 | Gate 2 迭代日志 |
| Release/E2E | 共用裁剪模板；staging 隔离 GodotIQ 编辑器 autoload，preset 控制 E2E bridge | `tools/export_godot_web.py` |

四份契约已在 Gate 1 冻结。

