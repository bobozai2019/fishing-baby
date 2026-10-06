# API 与持久化范围契约

状态：frozen（Gate 1，2026-08-08）

## 范围结论

| 项目 | 分类 | 结论 |
|---|---|---|
| HTTP/REST/GraphQL API | out_of_scope | 本项目为本地 Godot 游戏，不新增网络端点 |
| OpenAPI | out_of_scope | 无网络接口，不生成 OpenAPI |
| 数据库/迁移 | out_of_scope | 不新增数据库或迁移 |
| 存档/账号/云同步 | out_of_scope | 道具与波次只存在于当前回合内 |
| 遥测/排行榜 | vNext | 本任务不增加埋点、排行榜或远程数据 |
| Windows 导出预设 | out_of_scope | 当前仅保留已有 Web preset |

## 本地接口替代口径

本任务的字段级接口由以下契约承担：

- Resource 字段与校验：`数据与波次契约.md`。
- GDScript 方法、Signal 与状态流：`状态机与信号契约.md`。
- 场景路径、HUD 与输入/E2E：`场景视觉与E2E契约.md`。

验收标准：实现完成后，仓库中不得因本任务出现网络客户端、服务端地址、数据库驱动、存档文件或平台账号依赖。
