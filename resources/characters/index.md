# 角色资源

存放玩家角色、船只及角色操作装置的美术资源。

直属子目录：无。

## 运行时资源

| 文件 | 尺寸 | 用途 |
|---|---:|---|
| `boat_body.png` | 1536 × 1024 | 船身、船员身体和吊机；由 `scenes/entities/boat.tscn` 的 `Body` 节点使用 |
| `boy_head.png` | 1254 × 1254 | 男孩头部；`boat.tscn` 的默认 `Head` 贴图 |
| `girl_head.png` | 1254 × 1254 | 女孩头部；由女孩船只实例覆盖 `Head.texture` |

## 兼容保留资源

| 文件 | 尺寸 | 状态 |
|---|---:|---|
| `boat-fisherman-crane.png` | 2048 × 1024 | 旧的船、渔夫和吊机合成图；保留供历史对照，当前运行时场景不再引用 |

船只采用分层组合方式：`boat_body.png` 作为船身，`boy_head.png` 或 `girl_head.png` 作为头部。具体缩放、对齐和绳索参考点统一保存在 `scenes/entities/boat.tscn`，不在资源索引中重复维护坐标。
