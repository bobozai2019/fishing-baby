# 契约目录

状态：frozen（Gate 1，2026-08-09）

| 契约 | 解决的问题 | 冻结 Gate |
|---|---|---|
| `构建产物与体积契约.md` | 构建输入、输出、manifest、预算与回滚 | Gate 1 |
| `引擎裁剪功能契约.md` | 哪些引擎能力必须保留、允许关闭 | Gate 1 |
| `Web托管与Brotli契约.md` | `.br` 生成、URL、响应头、交付布局 | Gate 1 |
| `运行回归与E2E契约.md` | Headless、正式 release、E2E 和视觉验收 | Gate 1 |

本任务不新增业务 API 或数据库，因此不创建空的 API/数据库契约；字段级边界集中在构建 manifest 与 HTTP 响应契约中。


