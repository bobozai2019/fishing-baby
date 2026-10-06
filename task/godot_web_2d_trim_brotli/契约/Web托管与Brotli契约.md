# Web 托管与 Brotli 契约

状态：frozen（Gate 1，2026-08-09）

## 压缩输入

默认对以下文件生成 Brotli quality 11 表示：

- `*.wasm`
- `*.pck`
- `*.js`
- `*.worklet.js`
- Gate 0 判定值得压缩的 HTML/JSON

不得对 PNG 等已压缩资源强制生成无收益副本；阈值由压缩工具以 `brotli_bytes < raw_bytes` 判定。

## HTTP 响应字段

| 请求资源 | 实际表示 | `Content-Encoding` | `Content-Type` | `Vary` |
|---|---|---|---|---|
| `index.wasm` | `index.wasm.br` | `br` | `application/wasm` | `Accept-Encoding` |
| `index.pck` | `index.pck.br` | `br` | `application/octet-stream` | `Accept-Encoding` |
| `index.js` | `index.js.br` | `br` | `application/javascript` | `Accept-Encoding` |
| `*.worklet.js` | 对应 `.br` | `br` | `application/javascript` | `Accept-Encoding` |

继续保留当前跨源隔离头：

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`
- `Cross-Origin-Resource-Policy: cross-origin`

## 交付布局决策点

Gate 0 必须从以下模式中选一个并写入 ADR：

1. `dual_representation`：raw 与 `.br` 同目录，服务器内容协商；适合传输限制，不适合“目录所有文件求和”限制。
2. `split_directories`（当前正式布局）：`build/web_playtest/` 仅保存 raw，`build/web_playtest_br/` 保存 Brotli 发布表示和不可压缩资源。
3. `strict_brotli_upload`：上传制品只含平台可识别的 Brotli 表示与必要 shell；必须有平台 rewrite/header 支持证明。
4. `archive_upload`：上传单个 ZIP，解压后服务器使用 dual representation；仅在平台按 ZIP 统计时可用。

## 验收

```powershell
curl.exe -I -H "Accept-Encoding: br" http://127.0.0.1:8000/index.wasm
```

必须同时验证响应头、HTTP 200、浏览器成功编译 WASM，并从 Playwright `response` 事件记录实际传输资源集合。
