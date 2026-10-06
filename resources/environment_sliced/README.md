# 海洋场景细分素材（九宫格 / 横向三宫格）

基准分辨率：`1920×1080`。所有素材直接从 `source-ocean-background.png` 的固定色块拆出，没有重新生成或增加灯光效果。

## 推荐层级

```text
SceneBackgroundNinePatch  天空 + 水体基础色
├── Clouds                 透明白云，可独立移动
├── LighthouseIsland      透明灯塔岛
├── SurfaceWave           原素材包的海面波浪条
├── UnderwaterObjects      鱼、抓钩、宝物
├── SeabedLeft/Right       透明水底远景装饰
└── SandThreeSlice         横向三宫格沙层
```

## 九宫格参数

| 纹理 | 左 | 上 | 右 | 下 | 用途 |
|---|---:|---:|---:|---:|---|
| `background/scene-background-9slice.png` | 320 | 393 | 320 | 160 | 完整天空/水体底色；上下拉伸时主要扩展水区 |
| `background/sky-9slice.png` | 128 | 128 | 128 | 128 | 单独天空纯色层 |
| `water/water-9slice.png` | 128 | 128 | 128 | 128 | 单独水体层；顶边保留 4px 水平分界色 |

上述整张 PNG 可直接交给 Godot `NinePatchRect`。同时提供 `cells/` 或 `scene-cells/` 中的 9 个独立单元，方便不用 `NinePatchRect` 时手工拼接。

## 沙层横向三宫格

- 整张：`sand/sand-3slice.png`，尺寸 `1920×130`。
- 左端固定：`sand/parts/sand-left.png`，宽 384。
- 中段拉伸：`sand/parts/sand-center-stretch.png`，宽 1152。
- 右端固定：`sand/parts/sand-right.png`，宽 384。

若使用 `NinePatchRect` 模拟横向三宫格，设置：

```text
patch_margin_left   = 384
patch_margin_right  = 384
patch_margin_top    = 0
patch_margin_bottom = 0
高度固定为 130，只改变宽度
```

## 云层

`clouds/` 中有 9 张透明 PNG。`cloud-02-edge-right.png` 来自原图右侧边缘，本身就是半截入镜云，适合贴在屏幕右边界；其余 8 张均为完整云团。

原始 1920×1080 构图位置记录在 `config/ninepatch-config.json`，可以先按这些坐标还原，再自行做水平漂移动画。

## 预览

- `previews/scene-background-9slice-guide.png`：紫线显示完整背景九宫格边界。
- `previews/sky-9slice-guide.png`、`water-9slice-guide.png`：独立天空/水体的九宫格边界。
- `previews/sand-3slice-guide.png`：紫线显示沙层左/中/右边界。
- `previews/clouds-contact-sheet.png`：9 张云层总览。
- `previews/separated-props.png`：灯塔岛和水底左右装饰总览。

## Godot 注意事项

- `NinePatchRect` 的水平和垂直拉伸模式建议先使用 `STRETCH`；纯色中心区不会产生接缝。
- 沙层只允许水平拉伸，节点高度保持 130；若整体缩放，按统一比例缩放父节点。
- 云和岛屿使用 `TextureRect`/`Sprite2D`，不要放进九宫格纹理，否则拉伸时会变形。
- 水底左右装饰应分别锚定左右下角，中央水域保持为空。
- `godot/` 已附带四个预配置 `.tscn`；如果素材目录保持为 `res://fishing_game_assets/`，可直接实例化。
