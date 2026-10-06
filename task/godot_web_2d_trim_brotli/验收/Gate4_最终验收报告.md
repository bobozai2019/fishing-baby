# Gate 4 最终验收报告

日期：2026-08-09  
结论：[已完成] PASS

## 最终包体

| 指标 | Stock baseline | Custom final | 变化 | 预算 | 结果 |
|---|---:|---:|---:|---:|---|
| WASM raw | 39,513,091 | 16,749,392 | -57.61% | ≤17 MiB | PASS |
| PCK raw | 7,698,092 | 7,655,272 | -0.56% | ≤7.5 MiB | PASS |
| raw total | 47,545,859 | 24,710,085 | -48.03% | 报告项 | PASS（亦低于 25 MiB） |
| raw 发布目录 | 47,545,859 | 24,710,085 | -48.03% | 报告项 | PASS |
| Brotli 发布目录 | 14,581,877 transfer | 10,798,623 | -25.95% | <25 MiB | PASS |
| Brotli transfer | 14,581,877 | 10,798,623 | -25.95% | <25 MiB | PASS |

最终 `build_id`：`custom_release-0d1b6cea0a80900c`。证据：`manifests/custom-final-01.json`。

## 回归与复现

| 项 | 结果 | 证据 |
|---|---|---|
| Core tests | PASS：scene、round、hook×20、capture、data、movement、waves、powerups | `logs/core-tests-final.log` |
| Custom E2E | 22/22 PASS，Chromium + Edge | `logs/e2e-full-final.log` |
| Release smoke | PASS，标题 `fishing_baby`，当前端口控制台 0 error，E2E bridge 为 `undefined` | 三视口浏览器验收 |
| 中文/纹理/布局 | PASS；补齐 Catchable Label 字体后无方框，三视口画面完整 | `screenshots/gate4-release-*.png` |
| Brotli 网络 | PASS | `network/*.headers.txt` |
| 可重复构建 | 两次完整 manifest 的文件集合、SHA-256、raw/Brotli 字节完全一致 | `manifests/custom-final-01.json`、`custom-final-02.json` |
| Stock rollback | `build.bat --stock` PASS，stock WASM 39,513,091；随后恢复 custom | `logs/stock-rollback.log`、`stock-rollback.json` |

## 交付与回滚

- 正式构建：`build-web.bat`
- 本地 Brotli 服务：`python tools/serve_web.py --directory build/web_playtest --port 8011`
- 最终发布目录：`build/web_playtest_br/`（Brotli-only，10,798,623 bytes 运行载荷）
- 官方模板回滚：`build.bat --stock`
- 当前 `build/web_playtest/` 已恢复为最终 custom release。
