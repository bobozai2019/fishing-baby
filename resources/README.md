# 美式卡通捕鱼游戏素材包（无灯光版）

本包从玩法概念图拆分，供 Godot 2D 项目直接使用。独立物体均为透明 PNG，HUD 为可无损缩放的 SVG。

## 美术规范

- 美式卡通、粗深色轮廓、夸张表情、清晰剪影。
- 不包含太阳光、光束、水下焦散、高光、轮廓光、发光、Bloom、投影或环境光渐变。
- PNG 内部颜色经过无抖动色彩归并，保留透明抗锯齿边缘，主体内部只使用少量固定色块。
- 绳子不做成贴图：建议使用 Godot `Line2D`，从船上吊机挂点连接抓钩挂点。

## 素材内容

- `fish/`：5 类鱼，每类各有 `swim` 和 `caught` 两张 1024×1024 透明 PNG。
- `characters/`：可组合船身、男孩/女孩头部，以及仅供历史对照的旧整船合成图。
- `tools/`：独立三爪抓钩，1024×1024。
- `creatures/`：螃蟹、水母。
- `pickups/`：宝箱、珍珠贝、旧靴子、轮胎、罐头。
- `environment/`：1920×1080 无灯光背景、海面波浪条、海底装饰组合。
- `environment_sliced/`：进一步拆分的天空/水体九宫格、沙层横向三宫格、9 张透明云、灯塔岛和水底左右装饰。
- `ui/`：HUD 面板、图标按钮框、时间/金币/抓钩/卷扬机/渔网 SVG 图标。
- `reference/`：原始玩法概念图。
- `sources/`：色键母版和自动抠图后的未拆分源文件，方便二次裁剪。
- `manifest.json`：尺寸、状态和建议挂点。

## 鱼类状态

| 品种 | 游泳 | 被抓挣扎 |
|---|---|---|
| 小型蓝鱼 | `blue-small-swim.png` | `blue-small-caught.png` |
| 绿色杂鱼 | `green-scrap-swim.png` | `green-scrap-caught.png` |
| 黄色条纹鱼 | `yellow-striped-swim.png` | `yellow-striped-caught.png` |
| 紫色巨型鱼 | `purple-giant-swim.png` | `purple-giant-caught.png` |
| 橙红稀有鱼 | `orange-rare-swim.png` | `orange-rare-caught.png` |

两张图代表两个玩法状态，不是完整逐帧动画。当前可在 `caught` 状态对整个鱼节点做约 `-8° ~ +8°` 往复旋转；若要让尾巴独立连续摆动，建议再补 2–4 帧或做简易骨骼切片。

## Godot 导入建议

1. 独立 PNG 使用 `Sprite2D`，默认中心锚点即可；碰撞体使用手工 `CapsuleShape2D` 或凸多边形，不建议按 Alpha 自动生成。
2. 同一品种的两个状态画布相同，状态切换时不会改变节点原点。
3. 背景按 1920×1080 设计；海面波浪条覆盖在背景水位线上。
4. 船只通过 `scenes/entities/boat.tscn` 组合：`boat_body.png` 作为船身，`boy_head.png` 或 `girl_head.png` 作为头部；绳索起点由场景中的 `RopeOrigin` 维护。
5. 抓钩连接点建议约为原图局部坐标 `(512, 64)`，最终以游戏缩放后微调。
6. 平滑缩放时开启纹理过滤；若希望线条更硬，可关闭 Mipmap。

生成提示词模板和各元素主题见 `PROMPTS.md`。
