# 内部 API 契约

状态：`frozen`

## 1. 边界

- 本 Demo 没有 HTTP API、WebSocket、OpenAPI、数据库或存档 API。
- 跨场景边界通过 Godot 信号和下列公开方法实现。
- 参数名与字段为 Gate 1 冻结内容；不传递未约束的通用 `Dictionary`，除非本契约明确列出字段。

## 2. HookController

### `try_launch() -> bool`

| 输入 | 类型 | 必需 | 说明 |
|---|---|---:|---|
| - | - | - | 使用当前摆角发射 |

| 返回 | 含义 |
|---|---|
| `true` | 当前为 `SWINGING` 且回合允许输入，已进入 `EXTENDING` |
| `false` | 其他任何状态，无副作用 |

### `set_input_enabled(enabled: bool) -> void`

- `enabled=false` 时忽略新的出钩请求。
- 若抓钩正在外部，已开始的回收继续，结束后进入 `DISABLED`。

### `reset_hook() -> void`

- 清空当前携带物，恢复默认长度与摆角，根据 `input_enabled` 进入 `SWINGING` 或 `DISABLED`。
- 只用于新局/重开，不结算分数。

### Hook 信号

| 信号 | 字段 | 类型 | 必需 | 发射时机 |
|---|---|---|---:|---|
| `state_changed` | `previous` | `HookState` | 是 | 状态成功改变 |
|  | `current` | `HookState` | 是 | 同上 |
| `catch_attached` | `catchable` | `Catchable` | 是 | 首个合法目标被挂载 |
| `shot_completed` | `caught_something` | `bool` | 是 | 每次出钩回到原点，且每次只发送一次 |

`RETRACTING_CATCH` 到达原点时，HookController 先调用携带物的 `collect()`，再发射 `shot_completed(true)` 并清空引用；得分信号由 Catchable 发送。

## 3. Catchable

### `attach_to_hook(carrier: Node2D) -> bool`

| 输入 | 类型 | 必需 | 校验 |
|---|---|---:|---|
| `carrier` | `Node2D` | 是 | 非空，且当前状态为 `AVAILABLE` |

- 成功返回 `true`，停止自主移动、关闭碰撞并保持为抓钩挂载物。
- 非法状态返回 `false`，不改变任何字段。

### `collect() -> void`

- 只允许 `HOOKED -> COLLECTED`。
- 发射 `collected(instance_id, definition.id, definition.score_value)` 后退出当前场景或隐藏至重开。

### Catchable 信号

| 信号 | 字段 | 类型 | 必需 |
|---|---|---|---:|
| `hooked` | `instance_id` | `StringName` | 是 |
|  | `definition_id` | `StringName` | 是 |
| `collected` | `instance_id` | `StringName` | 是 |
|  | `definition_id` | `StringName` | 是 |
|  | `score_value` | `int` | 是 |

## 4. RoundController

### `start_round() -> bool`

- 只有 `READY` 可进入 `PLAYING`；其他状态返回 `false`。
- 成功时：`score=0`、`seconds_left=level.duration_seconds`、启用抓钩输入。

### `add_score(instance_id: StringName, definition_id: StringName, amount: int) -> bool`

| 字段 | 类型 | 必需 | 校验 |
|---|---|---:|---|
| `instance_id` | `StringName` | 是 | 必须是关卡中存在且未结算的唯一实例 ID |
| `definition_id` | `StringName` | 是 | 必须匹配该实例绑定的 `definition.id` |
| `amount` | `int` | 是 | `>= 0`，必须与定义分值一致 |

- 只在 `PLAYING` 接受。
- 同一实例只能成功一次；重复结算返回 `false`。

### `restart_round() -> void`

- 只从 `WON`/`LOST` 执行，恢复所有抓取物、分数、倒计时与抓钩。
- 重开后进入 `READY`，由用户再次开始。

### Round 信号

| 信号 | 字段 | 类型 | 必需 |
|---|---|---|---:|
| `round_state_changed` | `previous` / `current` | `RoundState` | 是 |
| `score_changed` | `score` / `target_score` | `int` / `int` | 是 |
| `time_changed` | `seconds_left` | `int` | 是 |
| `round_finished` | `result` | `RoundResult` (`WON`/`LOST`) | 是 |
|  | `final_score` / `target_score` | `int` / `int` | 是 |

## 5. GameHud

| 方法 | 字段 | 类型 | 校验 |
|---|---|---|---|
| `set_score` | `score`, `target` | `int`, `int` | 显示为 `score / target` |
| `set_time` | `seconds_left` | `int` | 向上取整显示，不小于 0 |
| `show_ready` | - | - | 展示操作提示 |

## 6. RoundResultOverlay

| 方法/信号 | 字段 | 类型 | 口径 |
|---|---|---|---|
| `show_result` | `result`, `score`, `target` | `RoundResult`, `int`, `int` | 展示胜/负、最终分和重开操作 |
| `hide_result` | - | - | 返回 READY 时隐藏 |
| `restart_requested` | - | signal | 重开按钮或等价输入只发送一次 |

## 7. 错误与无效调用约定

- 玩家可预期的重复按键、无效状态调用返回 `false`，不打印 error。
- 缺失必需资源、空定义、未知 ID 等契约违反必须 `push_error()` 并使 headless 测试失败。
- 不捕获或吞掉脚本 parse error、资源 load error。
