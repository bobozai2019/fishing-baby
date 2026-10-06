# Gate 3 构建与 Brotli 报告

日期：2026-08-09  
结论：[已完成] PASS

| 项 | 结果 | 证据 |
|---|---|---|
| 一键构建 | `build.bat` 成功完成字体子集、模板校验、staging 导出、Brotli 与 manifest | `logs/custom-full-final-01.log` |
| 安全清理 | stale 文件被删除，`build/other-preserved/keep.txt` 保留 | 构建时断言 `CLEANUP_SCOPE_OK` |
| Fail-fast | template version/commit/profile/template SHA 全部验证 | `tools/web_package.py` |
| Brotli | quality 11，仅在压缩后更小时生成 `.br` | `manifests/custom-final-01.json` |
| HTTP | HTML/JS/PCK/WASM 均返回 `Content-Encoding: br`；WASM 为 `application/wasm`；含 `Vary`、COOP/COEP/CORP | `network/*.headers.txt` |
| 分目录布局 | `build/web_playtest/` 只含原始文件；`build/web_playtest_br/` 含 Brotli 发布文件 | manifest `delivery_layout=split_directories` |
| Brotli-only 发布目录 | `build-web.bat` 同步生成；可压缩资源只保留 `.br`，PNG 保留原文件 | `deployment-manifest.json` |

正式服务命令：`python tools/serve_web.py --directory build/web_playtest --port 8011`。

Brotli-only 发布目录本地验证：`python tools/serve_web.py --directory build/web_playtest_br --port 8012`。托管端必须按 `deployment-manifest.json` 将原请求路径映射到 `.br`，并发送 `Content-Encoding: br`。
