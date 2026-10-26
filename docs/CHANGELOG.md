# 开发日志

## 0.9.5 (2026-10-26)
- **文案统一**：界面和文档统一使用“局域网”“局域网设备”“业务系统”，不再使用旧称呼；`Show-OCR-Info.bat`、部署指南、GreasyFork 文案同步更新。
- **菜单重命名**：设置项改为 `OCR 服务器设置…`；服务器更新项改为 `从 OCR 服务器更新脚本…`，明确它只更新油猴脚本，不更新服务端程序（服务端升级仍用 `Update-OCR.bat`）。
- **兼容**：脚本 `@name` / `@namespace` 保持不变，避免 Tampermonkey/GreasyFork 把老用户识别成新脚本；产品名保持不变。

## 0.9.4 (2026-10-26)
- **新增**：`Show-OCR-Info.bat` + `tools/show_info.ps1`，在服务器上双击即可显示并复制“服务器地址 + API token + 安装地址”，方便直接发局域网群聊。
- **变更**：油猴菜单精简为 5 项：识别并填码、刷新后识别、OCR 服务器设置…、高级功能…、从 OCR 服务器更新脚本…；大小写切换、断路器重置、站点规则的添加/查看/删除/清空收进「高级功能…」对话框。
- **文档**：更新便携版说明、部署指南、油猴菜单说明；`Show-OCR-Info.bat` 已加入便携包和更新器。
- **兼容**：识别逻辑、服务端接口、token 注入和 GreasyFork 更新机制不变。

## 0.9.3 (2026-10-23)
- **变更**：油猴菜单「OCR 服务器设置…」不再弹两个 `prompt()`，改为独立设置对话框：可填 URL/token、显示 token、测试 `/health`、保存；首次未配置时自动弹出同一对话框。Tampermonkey 管理面板不提供自定义入口 API，入口仍在油猴扩展菜单。
- **修复**：配置探测只接受 `/health` 的 2xx 响应，避免错误地址返回 404 也被当成连接成功。
- **说明**：从局域网 `/userscript.user.js` 安装的脚本仍以服务端注入值为准；手动修改只在当前会话生效，下次更新会恢复服务端配置。

## 0.9.2 (2026-10-23)
- **一键更新**：新增 `Update-OCR.bat` + `tools/update_ocr.ps1`。默认从 GitHub 下载最新源码，停止服务 → 备份 `server/config.json`、`server/`、`userscript/` 到 `backup-时间戳/` → 替换代码（**保留 `server/config.json` 和 `python/`**）→ 依赖变化时自动 `pip install` → 重启服务。局域网无法访问 GitHub 时可用 `-SourceZip` 指定离线源码包。
- **局域网分发**：明确其他设备只需 Tampermonkey + 打开 `http://<服务器IP>:1205/userscript.user.js`，无需下载便携包；服务端自动注入 URL/token。
- **油猴更新**：局域网安装的脚本 `@updateURL` 指向服务器，可直接使用油猴“检查用户脚本更新”；GitHub 安装的脚本继续从 GitHub 更新，建议老用户重开一次局域网地址切换到服务器托管更新。
- **GreasyFork 准备**：油猴头新增 `@license`、`@homepageURL`、`@supportURL`、`@source`、`@description:zh-CN`；新增 `docs/GREASYFORK.md`（可直接粘贴的发布文案与注意事项）。
- **构建**：便携包加入 `Update-OCR.bat`；`.gitignore` 忽略更新备份目录。
- **修复**：`setup_new_server.ps1` 停止服务、防火墙规则和提示改用配置端口，不再硬编码 1205（便于测试/自定义端口）。

## 0.9.1 (2026-10-23)
- **免手动配置**：`GET /userscript.user.js` 现在把当前服务器地址和 token 注入 `INJECTED_CONFIG`，并把 `@updateURL` / `@downloadURL` 指向服务器本身。局域网设备从局域网地址安装脚本后无需再填 URL/token；注入值优先于本地存储，轮换 token 后升版本即可自动下发。
- **安全**：该端点只对 `allowed_clients` 中的 IP 返回，并带 `Cache-Control: no-store`；公开 GitHub 脚本仍保持 `INJECTED_CONFIG = null`、无 token。
- **一键便携包**：新增 `Start-OCR.bat`（自动提权）、`Stop-OCR.bat`、`README-FIRST.txt`；`setup_new_server.ps1` 新增 `-NonInteractive`，自动接受探测到的局域网 IP，并把脚本地址复制到剪贴板。
- **构建**：`tools/build_portable.ps1` 打包上述启动/说明文件。
- **文档**：README/DEPLOY 改为“解压 → 双击 → 发链接”的流程，并说明局域网脚本自动带 token、公开脚本需手动配置。

## 0.9.0 (2026-10-23)
公开发布准备：支持 GitHub 拉取部署 + 油猴脚本在线更新。
- **去密钥发布**：油猴脚本不再内嵌 token / 服务器地址；首次运行提示或菜单「OCR 服务器设置…」填写，保存到 `GM_setValue`。移除了 local/office profile 自动探测（同时消除 B5 类首跑 401 断路器问题）。
- **在线更新**：脚本头新增 `@updateURL` / `@downloadURL`（GitHub raw）；服务端新增 `GET /userscript.user.js` 托管脚本，菜单「从 OCR 服务器更新脚本…」供无法访问 GitHub 时使用。
- **单源化**：`userscript/local-captcha-autofill.user.js` 成为唯一脚本来源，删除 `templates/` 及“生成脚本/烘 token”逻辑；`start_server.ps1`、`setup_new_server.ps1` 改为打印局域网设备所需的 Server URL + token。
- **GitHub 就绪**：新增根 `README.md`、`LICENSE`（MIT）、`install.ps1`、`PUBLISH.md`；`.gitignore` 允许跟踪无密钥脚本，并忽略测试报告/基准报告。
- **可移植性**：修正 `tools/restart_server.ps1`、`tools/test_e2e.py`、`tools/mock_oa_server.py` 的硬编码 `D:\OCR` 路径，改为相对仓库。
- **依赖锁定**：`requirements.txt` 固定为已验证版本（fastapi 0.137.0 / uvicorn 0.49.0 / pydantic 2.13.4 / ddddocr 1.6.1 / onnxruntime 1.26.0 / Pillow 12.2.0）。
- **安全**：轮换 `api_token`；旧 token 仍存在于旧 git 历史中，发布请按 `PUBLISH.md` 使用干净历史。

## 0.8.5 (2026-10-23)
基于 `docs/TEST-REPORT-0.8.4.md` 的缺陷修复。
- **B1（P1）base64 尾字节截断**：`_base64_decode` 在 payload 长度 ≡1 mod 3（base64 以 `==` 结尾）时多删 1 个有效字节，导致 JPEG/WebP 等原始流 100% 返回 400。删除多余的 `skip_bytes` 裁剪（手动解码器本就会自然丢弃残余位）。已验证 `b"A"` 及 len%3==1 的 JPEG 均能正确解码。
- **B2（P1）密钥入库**：`git rm --cached userscript/local-captcha-autofill.user.js` 停止追踪含真实 token/工作 IP 的生成脚本（文件保留在工作区，`.gitignore` 已覆盖，未提交）。
- **B3（P2）empty 桶不清理**：`_cleanup_debug_buckets` 桶列表加入 `empty`，移除从不写文件的死项 `cache-hit`。
- **B4（P2）快速开始链路断裂**：`start_server.ps1` 末尾恢复 uvicorn 启动（前台，Ctrl+C 停止），与 README 描述一致。
- **B5（P2）服务端本机 local profile 401**：`start_server.ps1`、`setup_new_server.ps1` 生成脚本时同时替换 `local.token`，避免首跑自动选中 local 后断路器秒开。
- **B6（P3）**：token 比较改用 `secrets.compare_digest`（按 UTF-8 字节，常数时间）。
- **B7（P3）**：`api_token` 缺失时不再放行请求，改为 403 拒绝。
- **B11（P3）**：油猴「为本网站添加规则」现在询问最小/最大长度（默认 4/6），不再硬编码。
- **B12（P3）**：`tools/test_browser.py` 脚本路径修正为 `userscript/local-captcha-autofill.user.js`，并改为相对仓库路径。
- **B15**：CHANGELOG 中 onnxruntime 版本对齐为实测 1.26.0。
- **接受/暂缓**：B8（`/docs` 公开——0.8.3 U3 明确要求保留）、B9（无速率限制/单飞，LRU 缓存已吸收重复）、B10（LRU 无 TTL）、B13（`@match`/`@connect` 过松——用户要求全站匹配）、B14（空图最多 2 次推理）。

## 0.8.4 (2026-10-23)
- **修复大小写验证码**：ddddocr 无法可靠保留大小写（默认输出小写，实测 `A8K3`→`a8k3`、`M2X5`→`M2x5`、`W7P9`→`w7p9`）。经测试 `set_ranges` 强制大写会直接破坏识别（`A8K3`→`83`），不可行。
- **客户端后处理**：`normalizeText` 新增 `rule.letterCase`（`upper` / `lower` / `preserve`），优先级高于旧的 `uppercase` / `lowercase`。默认规则设为 `upper`（匹配 业务系统大写验证码，且对不区分大小写的站点同样安全）。
- **每站点可切换**：新增 `caseOverrides`（按 host 存 `GM_setValue`）与油猴菜单「切换验证码大小写（大写/小写/原样）」，切换后自动重新识别，无需改代码。
- **评估结论**：`set_ranges`/`charsets` 不能用于控制大小写（会丢字符），大小写只能在客户端处理。

## 0.8.3 (2026-10-23)
- **U1**: 新增 `tools/benchmark.py` 准确率/延迟跑分工具。读取文件名带答案的验证码图片，统计完全匹配率、字符准确率、平均/最小/最大延迟，可生成人工校验 HTML 报告（`--report`）。支持 `--ignore-case` 区分纯大小写差异与真实错字。
- **U2**: `/recognize` 响应新增 `time_ms` 字段（服务端处理耗时，毫秒）。
- **U3**: 确认 FastAPI Swagger UI `/docs` 与 `/openapi.json` 可访问，可直接在线调试接口。
- **评估**: Python 3.14 + onnxruntime 1.26.0 实测推理正常，暂不降级至 3.12。
- **发现**: ddddocr 默认模型输出小写字母，若目标站点区分大小写需处理（0.8.4 已改为客户端 `letterCase` 方案）。

## 0.8.2 (2026-07-21)
- **P17**: 合并本地开发脚本和局域网设备脚本为单一文件。首次运行时自动探测 OCR 服务器（本地 dev 优先，超时 1.5s 后回退到生产），结果缓存到 `GM_setValue`。Tampermonkey 菜单增加"切换到本地开发服务器"、"切换到生产服务器"、"查看当前服务器"命令，可随时切换。

## 0.8.1 (2026-07-20)
- **P14**: MutationObserver 增加 `attributes:true` + `attributeFilter:['src']`，验证码图片 `src` 变化时自动触发重新识别（解决点击刷新验证码后不识别的问题）
- **P15**: HTTP 400 错误时读取服务端响应体 `detail` 字段，输出具体错误原因（如 base64 解码失败、图片过大等）
- **P16**: data:image/ URL 不再直接发送原始 `src`，改为通过 canvas 重新编码后发送，消除部分网站 data URL 中嵌入 `%0D%0A` 导致的 base64 数据损坏问题
- **Server**: `decode_image_data` 解码前移除 base64 中的换行符，修复部分网站 data URL 含 `%0D%0A` 导致 400 的问题

## 0.8.0 (2026-07-20)
- **P12**: 断路器由 `sessionStorage` 改为 `localStorage`，跨标签页共享故障状态
- **P13**: MutationObserver 每 60 分钟自动断开重连，防止 SPA 页面 observer 累积泄漏
- **Server**: DdddOcrEngine 增加线程锁，消除 ONNX 非线程安全导致的并发结果串扰
- **Server**: 启动预热同时加载 default + beta 模型，消除首个请求的 beta 冷启动延迟
- **Server**: Debug 图片桶清理从每次写入中移除，改为 30 分钟后台定时任务，降低 IO 开销

## 0.7.0 (2026-06-17)
- **C1**: `divBackgroundToDataUrl` 支持 `<div style="background-image:url(...)">` 验证码
- **C2**: `rotationCorrectedDataUrl` 撤销 CSS `transform:rotate` 后再 OCR
- **A**: `setNativeValue` 展开 7 个 DOM 事件 + 调用 React fiber `__reactProps.onChange`
- **B**: `autoFindElements` 启发式兜底（关键词 + 尺寸 + 就近输入框）
- **P8**: per-host 断路器 + 图片指纹去重 + 401/403 立即跳闸
- **P10**: MutationObserver 只监听新增图片节点
- **Server**: 双模型投票、per-char 置信度、LRU 缓存、启动预热、分桶 debug dump
- **P11** (2026-07-01): `_classify_one` 概率模式返回空时回退到普通分类
- 单文件就地重写工作流（删除 generated 副本）
- 便携包迁移支持（`build_portable.ps1` + `setup_new_server.ps1`）
- (2026-07-20) 文档重构：拆分为系统介绍、部署指南、开发日志
- (2026-07-20) 部署流程简化：`setup_new_server.ps1` 一步完成
- (2026-07-20) 新增跨网络部署文档（ZeroTier）
- (2026-07-20) 定名"土著内网验证码识别"，logo 到位

## 0.6.0 (2026-06-17)
- A1: 同源 iframe 遍历
- A2: MutationObserver 800ms debounce 兜底
- A3: 油猴菜单用户规则（GM_setValue）
- A4: 扩展默认 selectors（kaptcha/secCode/verifyCode/authcode/.yzm）

## 0.5.0 (2026-06-16)
- P3: Pydantic `image` 字段 `max_length`
- P6: `requestTimeoutMs` 超时 + `maxAttempts` 自动重试
- 点击验证码图片自动触发识别
- 饿了么 UI selectors
- `async def recognize` + `ThreadPoolExecutor` 解决 GIL 阻塞
- `Get-PrimaryLanIPv4` 改用 `Get-NetRoute` 默认路由
- `@connect` 清理无效尾随通配
- `-replace` 改 `[regex]::Replace` + `MatchEvaluator`

## 0.1.0 (2026-06-15)
- 初始版本：FastAPI + uvicorn + ddddocr + Tampermonkey
