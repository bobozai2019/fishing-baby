# T03 自定义 Web 模板编译与初筛

负责人：主 agent  
任务状态：[已完成]  
任务进度：100%

依赖：T01、T02。

## 目标

编译可追溯的纯 2D Web 模板，通过单变量裁剪循环在不破坏运行的前提下降低 WASM。

## 小目标进度

| ID | 小目标 | 状态 | 交付物/证据 |
|---|---|---|---|
| G01 | 编译 size/size_extra 基线 | [已完成] | template zip/log |
| G02 | 应用 disable_3d/3D physics | [已完成] | size delta |
| G03 | 应用 advanced GUI 与模块分组裁剪 | [已完成] | size delta matrix |
| G04 | 编译 release 变体 | [已完成] | release template |
| G05 | 必要时编译 E2E 变体 | [已完成] | e2e template |
| G06 | 生成 provenance 并做启动初筛 | [已完成] | Gate 2 报告 |

## 构建命令形态

实际参数以 4.7.1 `scons --help` 和冻结 profile 为准，禁止照抄未验证命令。目标形态：

```powershell
scons platform=web target=template_release optimize=size_extra build_profile=<profile> disable_3d=yes disable_physics_3d=yes disable_advanced_gui=yes threads=no dlink_enabled=no debug_symbols=no
```

## 验收标准

1. template zip 可被 Godot 4.7.1 export preset 接受。
2. 自定义模板导出的 WASM 能启动主场景。
3. 每轮参数、体积和结果均记录，不保留不可追溯“碰巧能跑”的模板。
4. 若 `index.wasm >17 MiB`，必须继续单变量迭代或在 Gate 2 明确未达 raw 预算。

