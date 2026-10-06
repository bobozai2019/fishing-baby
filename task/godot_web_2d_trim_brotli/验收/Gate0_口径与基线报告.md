# Gate 0 口径与基线报告

日期：2026-08-09  
结论：[已完成] PASS

## 冻结口径

目标分发平台未在项目中指定，因此冻结任务契约中的浏览器 HTTP Brotli 传输量为硬门禁：`brotli_transfer_bytes < 25 MiB`（26,214,400 bytes）。`raw_total_bytes` 与 Brotli 发布目录体积独立报告，不互相替代。

## 官方模板基线

| 指标 | 结果 |
|---|---:|
| raw total | 47,545,859 bytes |
| upload ZIP | 17,696,673 bytes |
| Brotli transfer | 14,581,877 bytes |
| `index.wasm` | 39,513,091 bytes |
| `index.pck` | 7,698,092 bytes |

证据：`manifests/stock-baseline.json`、`tmp/web_size_reports/baseline/stock-build.log`。

## 工具链

- Godot：`4.7.1.stable.official.a13da4feb`
- Python：3.13.12
- SCons：4.10.1
- Emscripten SDK：5.0.7
- 官方 tag commit：`a13da4feb8d8aefc283c3763d33a2f170a18d541`
