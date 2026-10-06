# T04 构建与 Brotli 集成

负责人：主 agent  
任务状态：[已完成]  
任务进度：100%

依赖：T03。

## 目标

将自定义模板、字体子集、正式导出、Brotli、体积 manifest 和安全清理组合为可重复一键构建。

## 小目标进度

| ID | 小目标 | 状态 | 交付物/证据 |
|---|---|---|---|
| G01 | 在 export preset 绑定模板 | [已完成] | preset diff |
| G02 | 为模板版本/哈希增加 fail-fast | [已完成] | build log |
| G03 | 实现确定性 Brotli 工具 | [已完成] | 压缩脚本 |
| G04 | 生成字段级 size manifest | [已完成] | JSON schema/sample |
| G05 | 维持固定目录清理安全检查 | [已完成] | stale-file test |
| G06 | 落地 Gate 0 选择的交付布局 | [已完成] | output tree |

## 允许修改

- `build.bat`
- `export_presets.cfg`
- `tools/` 下本任务新增构建/压缩脚本
- `.gitignore` 中对应生成目录规则

## 禁止修改

- 游戏玩法脚本、场景、美术
- 已冻结裁剪契约（需先 ADR）

## 验收标准

1. 一条命令完成正式构建并以非零退出码暴露任何失败。
2. 缺失/错版模板不能静默改用官方模板。
3. 构建前 stale 文件被删除，`build/` 其他目录不受影响。
4. manifest 和文件系统字节一致。

