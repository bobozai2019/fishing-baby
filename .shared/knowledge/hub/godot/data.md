# Data Knowledge

## 2026-05-17: 卡牌 keywords 统一为 StringName

卡牌资源的 `keywords` 字段统一使用 `StringName` 数组，不混用数字枚举、普通字符串和 `StringName`。

```gdscript
keywords = [&"attack"]
keywords = [&"exhaust"]
keywords = [&"retain"]
```

**Why:** 混用 `keywords = [3]`、`["exhaust"]`、`[&"attack"]` 会让规则判断、测试资源和生产资源出现隐式类型分叉，也让资源校验难以判断真实语义。

**How to apply:** 新增或修改卡牌 `.tres` 时只写 `&"keyword_id"`。需要新增关键字时，先补资源数据规范和校验，再批量迁移资源。
