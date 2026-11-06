# 开发日志

## 0.12.0 (2026-11-06)
- **修复**：便携包现在真正做到了「零环境可用」。`tools/build_portable.ps1` 生成的 `OCR-portable.zip` 内置 Python 运行时装全部依赖，在没有任何 Python 的电脑上解压后双击 `OCR-Panel.bat` 即可启动。此前 Release 从未上传过该附件，用户只能下载源码 zip（不含 `python\`），因此必然报 `No module named 'ddddocr'`。
- **修复**：新电脑启动失败时不再只输出 uvicorn 堆栈。新增 `tools/python_env.ps1`，启动前逐个候选解释器试导入 `fastapi/uvicorn/pydantic/ddddocr`，全部通过才使用；失败时 `start_service_bg.ps1` 以退出码 2 结束并打印中文原因与解决办法，控制面板弹窗显示具体缺失的模块。
- **修复**：`tools/setup_new_server.ps1` 在检测到依赖缺失时不再直接退出，而是自动创建 `.venv` 并执行 `pip install -r requirements.txt`，安装后二次校验。
- **修复**：`tools/panel_launch.ps1` 在首次运行时（`server\config.json` 不存在）静默生成配置与随机 token，使「解压 → 双击 → 可用」完整闭环；同时修掉把 `$args` 当变量名的问题。
- **变更**：文档统一收进 `docs\`。根目录 `README.md` → `docs/README-zh.md`、`AGENTS.md` → `docs/AGENTS.md`、`PUBLISH.md` → `docs/PUBLISH.md`。根目录只保留 `OCR-Panel.bat`、`README-FIRST.txt`、`LICENSE`、`requirements.txt`、`.gitignore`，让入口一目了然。
- **变更**：重写 `README-FIRST.txt`，改为正式文档口吻，按「安装与启动 / 控制面板 / 局域网接入 / 连接信息 / 日常操作 / 升级 / 故障处理 / 目录说明」组织，删除口语化说明。
- **变更**：`docs/PUBLISH.md` 新增 4.1 节，明确 **Release 必须上传 `OCR-portable.zip` 附件**，并给出上传命令与验证方法；`docs/AGENTS.md` 硬性规则新增第 15、16 条。

## 0.11.1 (2026-11-06)
- **修复**：新电脑从 GitHub 下载解压后，双击 `OCR 控制面板.lnk` 提示「无法找到脚本文件 ...panel_launch.vbs」。原因：快捷方式内嵌绝对路径，却被误提交进仓库，GitHub Release 源码 zip 里也带着旧电脑的路径。现已在 `.gitignore` 中忽略 `*.lnk` 并从版本库移除，仓库与发布包都不再包含快捷方式。
- **修复**：`OCR-Panel.bat` 在根目录没有 `.lnk` 时自动调用 `tools\make_shortcut.ps1` 重建，再启动面板，所以新机器解压后双击一次 `.bat` 就能恢复带 Logo 的快捷方式。
- **变更**：`README-FIRST.txt` 开头新增「从 GitHub 下载的包，解压后第一件事」说明，写明先双击 `OCR-Panel.bat` 以及旧快捷方式失效的原因。
- **修复**：`tools\build_portable.ps1` 打包时把 `*.lnk` 一并排除（此前只在复制完成后删除，根目录单文件分支未过滤）。

## 0.11.0 (2026-11-05)
- **变更**：脚本整理——面向用户的 `.bat` 入口全部移入 `launchers/`（`Start-OCR.bat`、`Stop-OCR.bat`、`Update-OCR.bat`、`Show-OCR-Info.bat`、`start_server.bat`、`OCR-Panel.bat`），`install.ps1`、`start_server.ps1` 移入 `tools/`。安装目录根下只剩 `OCR-Panel.bat`、`README-FIRST.txt`、`requirements.txt` 等少量文件。
- **兼容**：根目录保留 `OCR-Panel.bat` 作转发入口，老用户双击习惯不变；所有 `.bat` 用 `cd /d "%~dp0.."` 回到根目录，`tools/*.ps1` 用 `Join-Path $PSScriptRoot ".."` 推断根目录。
- **修复**：更新脚本现在会单独同步 `launchers/` 并备份旧入口，且**只有确认新版入口已就位才删除根目录旧 `.bat`**——旧版 updater 不认识 `launchers/`，直接删会导致升级后没有启动脚本可用。
- **新增**：面板「检查更新」按钮有完整反馈——连接 GitHub 时显示进度条与当前步骤，已是最新版时弹窗「已是最新版本」并显示绿色提示，发现新版本先确认再更新，更新过程按 `[PROGRESS]` 阶段显示百分比（下载 / 解压 / 停止服务 / 备份 / 复制 / 重启），失败时红色提示 + 弹窗并保留日志。
- **修复**：更新按钮原先在事件块里读脚本级变量，与 `New-StyleButton` 的参数同名冲突，已改为 `*Ref` 快照。
- **修复**：面板「检查更新」一直报「连不上 GitHub」——`Get-OnlineVersion` 用 `foreach ($args in ...)` 当循环变量，而 `$args` 是 PowerShell 自动变量，赋值会被丢弃，导致请求参数变成 `@($null)` 直接抛错。已改名 `$attempt`，并改为**依次尝试直连 / 7890 / 1080 代理**，同时比对 `server/app.py __version__` 与油猴 `@version` 取较大值（只改客户端脚本的版本也能检出）。
- **修复**：进度条与状态行不显示——`Set-UpdateUi` / `Set-UpdateProgress` 在函数里直接写 `$updateBar`，函数作用域看不到脚本级变量，已统一加 `$script:` 前缀；服务卡片加高到 148，窗口 860x894。
- **新增**：安装目录根下生成 **`OCR 控制面板.lnk`（带 Logo 图标）**，双击即可打开面板。`.bat` 的图标由系统固定，无法自定义（双击批处理只显示 cmd/脚本的默认图标），所以入口改为快捷方式；它直接调用 `wscript.exe //nologo tools\panel_launch.vbs`，不经过 `cmd.exe`，因此仍然不闪窗口、保留静默 UAC 提权。生成工具为新增的 `tools/make_shortcut.ps1`（支持 `-Desktop` 另建桌面副本、`-Quiet` 静默）。
- **变更**：快捷方式里是绝对路径，因此**不打进 zip**，而是在解压/安装/更新/打开面板时自动重建（`setup_new_server.ps1`、`update_ocr.ps1`、`panel.ps1` 都会调用 `make_shortcut.ps1`）。
- **修复**：`assets/ocr-panel.ico` 在 48px 及以上显示为噪点——旧实现把 PNG 数据配上 32bpp DIB 头写进 ICO，而 GDI+（Explorer / WinForms）不解码 PNG 压缩条目。`tools/make_icon.ps1` 改为**全部尺寸都写真正的 32bpp DIB**（16/24/32/48/64/128/256），并改为从高清 `assets/logo.png` 生成，各尺寸均清晰。
- **新增**：`assets/logo.png`（500x500 高清 Logo，图标源）与 `assets/ocr-logo.png`（32x32 原始 Logo）。

## 0.10.2 (2026-11-05)
- **美化**：控制面板改为自绘样式——深色头部 + 状态胶囊（绿/黄/红圆点 + 大字）、白色圆角卡片分区（服务状态 / 快捷操作 / 连接信息 / 服务控制 / 服务日志），按钮改为圆角药丸样式（主按钮蓝色、停止按钮红色描边），输入框套圆角底色。新增 `tools/ui_kit.ps1` 存放自绘控件与配色，面板只依赖 PowerShel​l，不引入第三方库。
- **变更**：把「更新服务端」「首次配置/修复」「刷新」等按钮重新分组；「开机自启」改为服务控制卡片里带说明的复选框，一眼能看出是否开启。
- **修复**：`Update-Status` 在函数作用域里看不到控件变量，导致状态卡与连接信息不刷新；改为把控件挂在 `$form.Tag` 上，并补回随状态变色的窗口图标。状态刷新出错时会写入面板日志，不再被静默吞掉。

## 0.10.1 (2026-11-04)
- **新增**：面板顶部状态徽标（🟢运行中 / 🟡启动中 / 🔴已停止）；运行中要求「端口在监听 + `/health` 返回 200」，不再只看端口。
- **新增**：面板直接完整显示「安装地址 / 服务器地址 / API token」，每行带独立「复制」按钮，并支持「一键复制全部（含说明）」；不用再点按钮或看脚本才知道地址和 token。
- **新增**：`assets/ocr-panel.ico`（绿圆 + OCR，7 种尺寸）作为 `OCR-Panel.bat` 的图标；窗口/任务栏图标随服务状态变色（运行中=绿，已停止=灰底红点）。缺失时自动用 `tools/make_icon.ps1` 重建。
- **变更**：面板改为**全程静默启动**，不再出现黑色命令行窗口；启动链改为 `OCR-Panel.bat` → `tools/panel_launch.vbs`（`wscript.exe` + `runas` 提权），只弹一次 UAC。新增 `tools/panel_launch.ps1` 作为有错误弹窗的后备入口。
- **修正**：面板内 `schtasks` 调用失败会中断面板的问题（统一走 `Invoke-Schtasks`）；改用 `tools/start_service_bg.ps1` 启动，避免每次启动都改配置。

## 0.10.0 (2026-10-26)
- **新增**：Windows 控制面板 `OCR-Panel.bat`（`tools/panel.ps1`，PowerShell + WinForms，零额外依赖）：状态/版本/局域网地址/安装地址一览，启停与重启服务、首次配置修复、更新服务端、复制连接信息、打开安装地址、查看日志。
- **新增**：面板内「开机自启」开关（任务计划，默认关闭）；自启任务调用新的 `tools/start_service_bg.ps1`，只启动服务、不改配置、不弹 UAC。
- **新增**：油猴菜单「切换本站识别（开/关）」，按 hostname 记忆；关闭后该站不再自动识别、不点刷新、不弹配置框，重新开启会立即识别一次。
- **约定**：关闭控制面板**不会**停止服务；需要停止请点面板上的「停止服务」。
- **文档**：新增 `docs/PANEL.md`（控制面板与启动方式评估与路径）；`README-FIRST.txt` 增加“用哪个脚本”对照表。

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
