# Gate 2 自定义模板报告

日期：2026-08-09  
结论：[已完成] PASS

## 最终模板

- 路径：`tools/web_templates/godot-4.7.1-2d-release.zip`
- ZIP SHA-256：`58492abfb0a862f316c1b19b9fcd68827c440cd884eb6a48be68669e7efeb7f2`
- Profile SHA-256：`8bd8f7ddfaac730c2df707aeff7b5e2ecc69b7617703a14e07ae98d7b3f381b3`
- WASM：16,749,392 bytes（15.97 MiB，低于 17 MiB 预算）
- 模板 ZIP：4,899,365 bytes

## 迭代结论

| Variant | WASM bytes | 启动 | 结论 |
|---|---:|---|---|
| stock | 39,513,091 | PASS | 基线 |
| advanced text | 17,929,957 | PASS | 可继续缩减 |
| fallback、无纹理解码 | 16,502,570 | FAIL | `.ctex` 无法解码 |
| fallback + Basis | - | FAIL | 实际载荷不是 Basis |
| fallback + WebP | 16,749,392 | PASS | 最终选择 |

证据：`logs/custom-template-build-05-webp.log`、`screenshots/gate2-fallback-text-smoke-1280x720.png`、provenance JSON。

