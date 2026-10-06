# 契约索引

| 文件 | 职责 | 状态 |
|---|---|---|
| `API契约.md` | Godot 内部公开方法、信号及字段契约 | frozen |
| `数据与关卡契约.md` | `Resource` schema、12 类抓取物及关卡平衡 | frozen |
| `状态机与信号契约.md` | Hook/Catchable/Round 状态与迁移 | frozen |
| `场景与视觉契约.md` | 场景树、资源绑定、视觉层级 | frozen |
| `输入平台与E2E契约.md` | Windows/Web 输入、视口、导出及 E2E | frozen |

规则：
- Gate 1 前为 `draft`；Gate 1 通过后改为 `frozen`。
- 契约只描述实现边界，实际测试结果写入 `../验收/`。
- 冻结后变更必须先记录 ADR，再更新受影响任务。
