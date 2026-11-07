# AGENTS.md

给后续接手开发的 AI Agent 的项目交接手册。**开始修改前请完整阅读这一份，不要另建笔记文件。**

本文件只讲“怎么在这里安全工作”，不讲历史。开发过程中的临时脚本、临时笔记、调试记录
一律不入库，见第 1 节。

---

## 0. 开发者底线（最高优先级）

> 1. 开发者有强迫症，**必须保持文件夹整洁**：根目录不允许出现临时文件、脚本、日志、
>    备份、下载的 zip、笔记。
> 2. **每次版本更新、开发完成后，上传 GitHub 前，必须先把各种 Agent 留下的残留文件清理干净再上传。**
> 3. **每次版本更新、开发完成后，必须主动询问开发者「是否发布？」**，得到明确许可后才能
>    commit / push / 打 tag / 建 Release。**不要自作主张发布，也不要连续几轮默认“下次再说”。**

这三条是不可协商的要求。具体做法见第 1 节，执行清单见第 9 节。

### 0.1 收尾时必须问的那句话

一轮开发做完（代码改完、测试跑完、工作区清理完），**停止继续改动，直接问**：

> 本轮开发已完成：<改了什么>。版本 X.Y.Z。测试结果：<结果>。
> **是否现在发布到 GitHub？**
> - 是 → 我按第 9 节清理清单确认后 commit / push / 打 tag / 建 Release
> - 否 → 改动保留在本地，不提交

**在开发者回答之前，不要执行任何 git 写操作。**
如果开发者要求继续改别的功能，等全部改完再问一次，不要在中间反复打断。

---

## 1. 工作区整洁规则（强制）

### 1.1 什么算“Agent 残留”

工作过程中 AI 最容易留下的东西，**全部不得交付，也不得入库**：

- 临时诊断脚本：`__diag*`、`__check*`、`__probe*`、`__fix*`、`__patch*`、`__bump*`、
  `__gen*`、`__static*`、`__write*`、`__add*`、`__cleanup*`、`__rewrite*`（`.py/.ps1/.js` 都算）
- 临时输出：`__body_*.txt`、`*.err`、`result*.png`、`scratch.*`、`tmp*`、`test-out*`
- 临时笔记 / 计划 / 汇总：`NOTES*`、`TODO*`、`PLAN*`、`SUMMARY*`、`*-report.md`、
  `TEST-REPORT-*.md`、`CHANGELOG-DRAFT*` 等任何“给 Agent 自己看的”文档
- 下载物：`main.zip`、`OCR-portable.zip`（打包产物）、解压出的临时目录
- 运行产物：`server.log`、`server.err.log`、`debug-images/` 内容、`__pycache__/`、`backup-*/`
- 虚拟环境：`.venv/`、`node_modules/`、`python/`
- 任何含 token、真实局域网 IP、账号的截图或文本

**判断标准**：如果它不在下面的“正式结构”里，或者它对使用者/后续开发者没有价值，
那它就是残留，交付前必须删。

### 1.2 临时文件放哪里

**不要在仓库里创建临时文件。** 需要跑一次性脚本、抓图、生成对比图时，一律放到系统临时目录：

```powershell
$tmp = Join-Path $env:TEMP "ocr-scratch"
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
```

需要长期保留的测试能力，写进 `tools/` 并纳入正式结构；一次性的验证代码跑完即弃。

### 1.3 交付前清理（每次都要做）

```powershell
# 1. 所有未跟踪文件 —— 逐个人工确认，该留的入库/写进 .gitignore，其余删除
git status --porcelain --untracked-files=all

# 2. 清理运行产物
Get-ChildItem -Recurse -Directory -Filter '__pycache__' | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item server.log,server.err.log -Force -ErrorAction SilentlyContinue
if (Test-Path debug-images) { Get-ChildItem debug-images -Recurse -Force | Remove-Item -Recurse -Force }

# 3. 根目录应该只剩“正式结构”里的东西
Get-ChildItem -Force | Select-Object Mode,Length,Name
```

`git status` 里出现的每一个 `??` 文件，都必须给出明确结论：**入库、忽略、还是删除**，
不允许“先放着”。

---

## 2. 项目概况

- 局域网自托管验证码 OCR 服务 + Tampermonkey 自动填码脚本
- 服务端：FastAPI + ddddocr（双模型投票、置信度门控、LRU 缓存），默认端口 `1205`
- 客户端：单文件油猴脚本，自动发现验证码图片/输入框并填入
- 公开仓库：`https://github.com/Piggya/OCR_captcha`，发布分支 `main`
- 运行环境：Windows 10/11 + PowerShell 5.1 + Python 3.10+
- 依赖安装：`pip install -r requirements.txt`（`requirements.txt` 是唯一依赖清单）

## 3. 正式结构

根目录只允许出现下列内容，新增顶层文件前先确认是否真的必要。
**根目录必须保持极简，让用户一眼看到 `OCR-Panel.bat`；文档一律放 `docs\`。**

```
server/          FastAPI 应用、OCR 引擎、config.example.json
userscript/      唯一油猴脚本源（无 token / 无服务器地址）
tools/           部署、构建、测试、基准、mock 工具
docs/            全部文档：README-zh、AGENTS、PUBLISH、DEPLOY、CHANGELOG、GREASYFORK、PANEL
launchers/       面向用户的 .bat 入口
assets/          logo.png（图标源）、ocr-logo.png（原图）、icon.png、ocr-panel.ico
.github/         （可选）CI 配置

OCR-Panel.bat    根目录唯一入口（首次运行会自动生成带 Logo 的快捷方式）
README-FIRST.txt 便携版说明（面向用户，排在 OCR-Panel.bat 之后）
LICENSE
requirements.txt 依赖清单
.gitignore
```

根目录**不再**放以下文件（已迁入 `docs\`）：
`README.md` → `docs/README-zh.md`、`AGENTS.md` → `docs/AGENTS.md`、
`PUBLISH.md` → `docs/PUBLISH.md`。

`docs/` 目录说明：

| 文件 | 用途 |
|---|---|
| `README-zh.md` | 项目完整说明（中文），含标题里的 `vX.Y.Z` |
| `AGENTS.md` | 本文件，AI Agent 交接手册 |
| `PUBLISH.md` | 发布流程说明 |
| `DEPLOY.md` | 部署细节 |
| `CHANGELOG.md` | 开发日志 |
| `GREASYFORK.md` | GreasyFork 发布说明 |
| `PANEL.md` | 控制面板说明 |

`launchers/`：`OCR-Panel.bat`（静默提权）、`Start-OCR.bat`（首次配置/修复）、
`Stop-OCR.bat`、`Update-OCR.bat`、`Show-OCR-Info.bat`、`start_server.bat`（开发调试）。
日常推荐双击根目录 `OCR-Panel.bat`。

**路径约定**：`launchers\*.bat` 一律 `cd /d "%~dp0.."` 回到安装根目录；
`tools\*.ps1` 用 `Join-Path $PSScriptRoot ".."` 推断根目录。
新增脚本必须沿用，否则移动位置后会找不到 `server\` / `python\`。

**已被 git 忽略、不要提交**：`server/config.json`、`backup-*/`、`docs/TEST-REPORT-*.md`、
`tools/test-assets/benchmark-report.html`、`.venv/`、`python/`、`debug-images/`、
`server.log`、`server.err.log`、`OCR-portable.zip`。

---

## 4. 硬性规则

1. 版本号必须**同时**修改 `server/app.py` 的 `__version__` 与
   `userscript/local-captcha-autofill.user.js` 的 `// @version`，两者必须一致。
2. 每次更新在 `docs/CHANGELOG.md` 顶部新增 `## X.Y.Z (YYYY-MM-DD)`，
   并在油猴脚本头部 `// CHANGELOG` 加一行摘要。
3. 版本号变更时同步更新 `docs/README-zh.md` 标题里的 `vX.Y.Z`。
4. **不提交任何密钥、真实 token、真实局域网 IP、账号、本机代理地址。**
5. 只推送 `main`。不要推送其它分支。
6. `.ps1` 保持 UTF-8 **BOM**（PowerShell 5.1 需要）。
7. `.user.js` 必须是无 BOM 的 UTF-8。
8. 不要删除 `host: "*"`、`@match *://*/*`、`@connect *`（全站匹配是需求）。
9. `userscript/local-captcha-autofill.user.js` 是唯一脚本源，不要恢复 `templates/`。
10. 改行为时同步更新 `docs/README-zh.md` / `docs/DEPLOY.md` / `README-FIRST.txt`。
11. `/userscript.user.js` 靠 `const INJECTED_CONFIG = null;` 这一行做服务端替换，
    **不要改写法、不要删**；仓库文件必须保持 `null`，token 只能运行时注入。
12. 局域网注入端点必须保留 `allowed_clients` 校验和 `Cache-Control: no-store`。
13. **GreasyFork Webhook 绑定 `main`**：推送前 `@version` 必须**严格递增**且与
    `server/app.py` 一致，否则 webhook 拒绝。推送前必跑 `tools\check_version_bump.ps1`。
14. `AGENTS.md` 本身**要提交**（它是给后续 Agent 的交接文档），但内容必须保持干净：
    不写开发过程、不写个人环境信息、不写临时验证步骤。
15. **Release 必须上传 `OCR-portable.zip` 附件。** 源码 zip 不含 `python\`，
    零环境的新电脑无法启动（会报 `No module named 'ddddocr'`）。只发源码 zip
    等于把安装门槛甩给用户。流程见 `docs/PUBLISH.md` 第 4.1 节。
16. **根目录只放 `OCR-Panel.bat` 和 `README-FIRST.txt`**，其余文档一律进 `docs\`。
    用户解压后第一眼必须看到 `OCR-Panel.bat`。
17. **`/userscript.user.js` 返回的地址不得取自请求**。`Host` 是客户端可控的，
    拿它拼 `serverUrl` / `@updateURL` 等于把更新源和明文 token 一起交给攻击者。
    一律走 `get_public_base_url()`（配置或探测的本机地址）。任何人不要"简化"回
    `request.base_url`。
18. **按端口杀进程前必须校验身份**。占用端口的进程要同时满足「命令行含
    `uvicorn.*server.app:app`」与「可执行文件在本目录下」才允许终止，否则只报告
    并退出。曾因无条件 Terminate 杀掉无关服务，还让临时目录的 uvicorn 接管了端口。
19. **`work_lan_ip` 必须验证真的绑定在本机**。配置可能来自别的机器或旧 DHCP 租约，
    不校验就会把不可达地址发给所有局域网设备（面板、自检、`show_info`、服务端注入
    四处都要校验，不在就回退到自动探测）。**还要排除回环 / 链路本地 / `0.0.0.0`**：
    它们在本机可绑定，但发给别人指的是「对方自己的回环」或干脆无效。
20. **判断「是不是本项目的进程」必须带路径分隔符**。`StartsWith("D:\OCR")` 会同时
    匹配 `D:\OCR-old`、`D:\OCR2`，导致把旧版安装的 python 当成自己的杀掉。用
    `GetFullPath($root).TrimEnd('\') + '\'` 后再比较。
21. **停完服务要轮询端口，不要固定 `Start-Sleep`**。`Stop-Process` 返回时套接字
    可能还在，慢机器上 2 秒不够；统一每 250ms 查一次、最长 20 秒，端口空了立即继续。
22. **`panel_launch.vbs` 必须保存为 UTF-16 LE + BOM**。VBScript 在 UTF-8 / ASCII 下
    读不了中文，会被写成 `?`，用户看到的就是一串问号。改这个文件时注意别被编辑器
    转成 UTF-8。

---

## 5. 本地运行

```powershell
# 安装依赖（venv 可选，不要提交）
pip install -r requirements.txt

# 前台启动（生成 server/config.json 和 token）
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start_server.ps1

# 后台重启（推荐给 Agent，会自动校验端口）
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\restart_server.ps1

# 便携版一键更新（保留 server/config.json 和 python/，自动备份）
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\update_ocr.ps1
# 离线：先下载 main.zip，再 -SourceZip "C:\path\main.zip"
```

uvicorn 必须在仓库根目录运行；`restart_server.ps1` 已处理工作目录。

## 6. 修改流程

1. 读相关文件，确认现有约定
2. 改代码
3. 升版本（第 7 节）
4. 写 CHANGELOG（第 7 节）
5. 跑完整验证（第 8 节）
6. **清理工作区（第 1 节）**
7. **主动询问「是否发布？」（第 0.1 节），等待开发者明确答复**
8. 得到许可后才按第 10 节发布

## 7. 版本号与 CHANGELOG

规则：修复升 patch（0.9.0 → 0.9.1），功能升 minor（0.9.1 → 0.10.0）。

需要改的位置：

- `server/app.py`：`__version__ = "X.Y.Z"`
- `userscript/local-captcha-autofill.user.js`：`// @version      X.Y.Z`
- `docs/README-zh.md`：标题 `# 土著内网验证码识别 vX.Y.Z`
- `docs/CHANGELOG.md`：顶部新增一节
- 油猴头部 `// CHANGELOG (see docs/README-zh.md):` 下新增一行摘要

检索旧版本号确认没漏改：

```powershell
Select-String -Path server\app.py,userscript\local-captcha-autofill.user.js,docs\README-zh.md,docs\CHANGELOG.md -Pattern '0\.9\.1'
```

CHANGELOG 格式：

```markdown
## 0.9.1 (2026-10-24)
- **修复**：一句话说明问题与修复方式
- **变更**：行为变化、兼容性影响
```

### 7.1 GreasyFork Webhook

- `main` 已配置 GitHub Webhook，push 后 GreasyFork 自动同步油猴脚本，**不要手动上传**。
- 改到 `userscript/` 就必须把 `// @version` 升到**严格大于**线上版本。
- 提交前运行（会对比 `origin/main`）：

```powershell
git fetch origin
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check_version_bump.ps1
```

- 出现 `[FAIL]` 禁止 commit/push，先修版本号。
- 发布后到 GreasyFork 脚本页确认版本已更新。

---

## 8. 测试与验证（每次改完必须全过）

### 8.1 语法检查

```powershell
node --check userscript\local-captcha-autofill.user.js
python -c "import py_compile; [py_compile.compile(f, doraise=True) for f in ['server/app.py','server/ocr_engine.py','tools/test_e2e.py','tools/test_browser.py','tools/benchmark.py','tools/mock_oa_server.py']]; print('PY OK')"
```

PowerShell 脚本解析：

```powershell
foreach ($f in (Get-ChildItem tools\*.ps1, launchers\*.ps1 -ErrorAction SilentlyContinue)) {
  $t=$null;$e=$null
  [System.Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$t,[ref]$e) | Out-Null
  if ($e.Count -eq 0) { Write-Host "$($f.Name) OK" } else { Write-Host "$($f.Name) ERRORS"; $e | ForEach-Object { $_.Message } }
}
```

### 8.2 启动并验证接口

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\restart_server.ps1
Invoke-WebRequest http://127.0.0.1:1205/version -UseBasicParsing
$us = (Invoke-WebRequest http://127.0.0.1:1205/userscript.user.js -UseBasicParsing).Content
Write-Host ('injected='      + ($us -match 'const INJECTED_CONFIG = \{'))
Write-Host ('server-update=' + ($us -match '// @updateURL\s+http://127\.0\.0\.1:1205/userscript\.user\.js'))
Write-Host ('repo-null='     + ((Get-Content userscript\local-captcha-autofill.user.js -Raw) -match 'const INJECTED_CONFIG = null;'))
```

`/version` 必须返回新版本号；三个布尔值必须全为 `True`。
**不要打印 served 脚本内容**（含真实 token）。

### 8.3 E2E

```powershell
python -X utf8 tools\test_e2e.py
```

必须全部 `[OK]`，不能有 FAIL。测试数量随新增用例变化，**以“无 FAIL”为准，不要写死数字**。

**不要用「文件里出现过某个词」来做断言**：`"Stop-Process" in panel_text` 这类检查
写进注释也能通过，等于没测。结构化文件（`.ps1` / `.py`）要用解析器看真实结构——
`tools/test_e2e.py` 的 `probe_panel_ast()` 用 PowerShell AST 取函数名、命令调用
和事件处理器实体，而不是匹配子串。新增此类断言时，先故意把对应代码删掉或注释掉，
确认断言真的会变红，再收工。

### 8.4 密钥扫描

```powershell
git add -A
$cfg=(Get-Content server\config.json -Raw | ConvertFrom-Json)
Write-Host ('token=' + (git grep --cached -n $cfg.api_token 2>$null | Measure-Object).Count)
if ($cfg.work_lan_ip) { Write-Host ('ip=' + (git grep --cached -n $cfg.work_lan_ip 2>$null | Measure-Object).Count) }
Write-Host ('config tracked=' + (git ls-files server/config.json | Measure-Object).Count)
```

三项都必须为 `0`。

### 8.5 可选跑分

```powershell
python -X utf8 tools\benchmark.py --ignore-case
```

### 8.6 版本递增检查（发布前必跑）

```powershell
git fetch origin
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check_version_bump.ps1
```

必须 `[OK]`。

---

## 9. 交付前检查清单

**上传 GitHub 之前逐条确认，任何一条不满足都不许 push。**

- [ ] `git status --porcelain --untracked-files=all` 干净，或每个 `??` 都有结论
- [ ] 根目录只有第 3 节“正式结构”里的内容
- [ ] 无 `__*` 临时脚本、无临时笔记/报告、无下载的 zip、无解压临时目录
- [ ] 已清 `__pycache__`、`server.log`、`server.err.log`、`debug-images/` 内容
- [ ] 无 token / 真实局域网 IP / 账号 / 个人代理地址
- [ ] `.ps1` 带 BOM、`.user.js` 无 BOM
- [ ] 版本号两处一致且严格递增
- [ ] `docs/CHANGELOG.md` 与油猴头部 CHANGELOG 已更新
- [ ] 第 8 节全部通过（语法、`/version`、E2E、密钥扫描、版本递增）
- [ ] 没有为了“方便”而留下的 `.venv/`、`python/`、`node_modules/`

---

## 10. 发布流程（必须先获得发布许可）

默认是**开发模式**：只改代码 + 跑测试，不 commit、不 push。

一轮开发完成后，**必须按第 0.1 节主动询问「是否发布？」并等待明确答复**：
- 开发者说「是 / 发布 / 发版 / 推送 / 更新线上 / 更新 GitHub」→ 执行本节
- 开发者说「否 / 先不发布 / 再改改」→ 改动留在本地，**不要 commit**

**不要默认发布，也不要把“没被否定”当成同意。**

```powershell
git status
git fetch origin
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check_version_bump.ps1
# 必须 [OK]
# ---- 此处先执行第 9 节清理清单 ----
git add -A
git commit -m "vX.Y.Z: 一句话说明"
git push
git tag vX.Y.Z
git push origin vX.Y.Z
```

push 后 GreasyFork Webhook 自动同步脚本，**不要**再手动上传。

在 GitHub 创建 Release：tag 选 `vX.Y.Z`，标题 `vX.Y.Z`，说明复制本次 CHANGELOG 条目。
用 API 时 token 从凭据管理器读取，**不要打印 token**。

发布后确认：

```powershell
git ls-remote origin refs/heads/main refs/tags/vX.Y.Z
```

并访问 raw 脚本地址确认可下载：
`https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js`

---

## 11. 已知坑（改代码前先看）

### 编码

- PowerShell 5.1 把无 BOM 的 UTF-8 当本地编码读，中文后紧跟引号会吞掉引号。
  **所有 `.ps1` 必须带 BOM。**
- `.user.js` 不要 BOM，用 `New-Object System.Text.UTF8Encoding($false)` 写入。
- `.ps1` 字符串里不要用中文全角引号 `“”`，PowerShell 会当成字符串结束，统一用 `「」`。

### 服务端

- ddddocr 不能可靠保留大小写；大小写由客户端 `rule.letterCase`
  （`upper`/`lower`/`preserve`）处理，默认 `upper`，不要改用 `set_ranges`。
- `_base64_decode` **不要**加入尾部 `skip_bytes` 裁剪，会让 JPEG 全部 400。
- `server/config.json` 的 `work_lan_ip` 用于打印给局域网设备的地址；换机器后改成新 IP
  或留空自动探测。**写错的地址不会再被采信**：面板、`show_info.ps1`、`get_public_base_url()`
  都会先确认该 IP 绑定在本机网卡上，否则回退到探测结果。
- 服务端代码改动需要重启 uvicorn；油猴脚本改动通过 `/userscript.user.js` 立即生效。
- `/userscript.user.js` 响应含真实 token，只对 `allowed_clients` 返回；
  验证时只输出布尔值，不要贴进日志、issue 或聊天。

### 油猴脚本

- Tampermonkey 管理面板没有开放自定义入口 API，配置入口只能用
  `GM_registerMenuCommand`，不要承诺往管理面板加按钮；配置用独立对话框，不用 `prompt()`。
- 顶层菜单保持精简（6 项）：识别并填码、刷新后识别、切换本站识别（开/关）、
  OCR 服务器设置…、高级功能…、从 OCR 服务器更新脚本…。
  站点规则、大小写切换、断路器重置放在 `openAdvancedDialog()`。
- 按站点开关用 GM 存储键 `ocr_disabled_hosts`；`recognizeAndFill()`、自动刷新和 boot
  都要先判断 `isCurrentSiteDisabled()`。
- 产品名 `土著内网验证码识别` / `@name` / `@namespace` 是更新身份，**不要改名**，
  改名会让老用户被识别成新脚本。界面正文统一用“局域网”“局域网设备”“业务系统”。
- 从局域网地址安装时 `INJECTED_CONFIG` 优先于浏览器存储；轮换 token 后升一次 `@version`
  客户端才会自动更新。

### 便携版与更新器

- `launchers/Update-OCR.bat` / `tools/update_ocr.ps1` 必须保留 `server/config.json` 和 `python/`，
  更新前备份到 `backup-*/`，并排除自身避免被覆盖。
- 更新时 `launchers/` 必须单独同步，且**只有确认新版入口到位后才删除根目录旧入口**。
- 便携版优先用面板「检查更新」或 `launchers\Update-OCR.bat`；离线用 `-SourceZip`。
- `Show-OCR-Info.bat` / `tools/show_info.ps1` 负责显示并复制“地址 + token + 安装地址”；
  token 只用于局域网分享，不要写入日志或提交。
- `start_server.ps1` / `start_server.bat` 是开发调试入口，**不要改名、不要删除**；
  文档统一说明“日常用 `OCR 控制面板.lnk`（找不到时用 `OCR-Panel.bat`）”。

### 控制面板

入口：`OCR 控制面板.lnk` 由 `tools\make_shortcut.ps1` 生成，
Target=`wscript.exe //nologo tools\panel_launch.vbs`；后备 `OCR-Panel.bat`（ASCII+CRLF）
→ `launchers\OCR-Panel.bat` → 同一个 VBS → `tools/panel.ps1`（UTF-8 BOM）。

- 关闭面板**不停服务**；停止服务只能点「停止服务」（按端口找 PID 再 `Stop-Process`）。
- **单实例靠全局 Mutex `Global\OcrControlPanel`**：启动时 `WaitOne(0)` 失败就把已有
  窗口切到前台并直接 `return`，`Add_FormClosing` 里释放。不要退回「按进程名数一数」的做法
  ——每多一个提权面板都是普通权限杀不掉的残留。新增任何「先启动再判断」的逻辑时，
  注意 `-SelfTest` 必须跳过判重。
- **UI 线程上禁止同步跑外部脚本或联网**。`start_service_bg.ps1` 要探测解释器、启动
  uvicorn、加载 ONNX 模型，耗时 7~18 秒；早先在 `Add_Click` 里直接
  `& powershell -File $startScript`，窗口整段时间卡死、Windows 显示「未响应」。
  正确做法（见 `Start-OcrServiceFromPanel`）：`[powershell]::Create()` +
  `BeginInvoke()` 在后台 runspace 执行，再用 `System.Windows.Forms.Timer`
  轮询 `$handle.IsCompleted`，完成后 `EndInvoke()` 收输出。
  按钮期间禁用并显示「启动中…」，完成后恢复。
  `Add_Shown` / `Timer.Tick` 里同样不能同步起子进程（`make_shortcut.ps1` 也是
  延迟到定时器里异步启动的）。
  「检查更新」也踩过同一个坑：在点击事件里同步调 `Get-OnlineVersion` 联网，
  网络不通时窗口卡死 48 秒。现在同样走后台 runspace + 定时器。
- **新 runspace 看不到本脚本的函数**。`[powershell]::Create()` 是干净的运行空间，
  `AddCommand("本脚本里的函数名")` 会报「无法将……识别为 cmdlet」。要么像启动服务那样
  传**脚本文件路径**，要么把函数定义整段用 `AddScript()` 送进去再调用
  （见「检查更新」里拼接 `(Get-Command Get-OnlineVersion).Definition` 的写法）。
- **忙碌守卫 `$script:svcBusy` 要配套绕过机制**：重启路径先置位 `svcBusy=$true`
  再调启动函数，会被函数开头的守卫直接 return，表现为「重启后服务不再起来」。
  重启必须传 `-AfterStop`（见 `Start-OcrServiceFromPanel` 的 param 块）。
- **绝对不要在轮询里用 `Get-NetTCPConnection`**。它在 PowerShell 5.1 上单次调用
  约 **950 ms**（每次遍历整张 TCP 表），面板每 3 秒刷新、启动/停止/重启时每 250ms
  轮询，一个操作能被它拖慢 3~10 秒。统一走 `panel.ps1` / `start_service_bg.ps1`
  里的 `Get-ListenerPid`，它内部用 `iphlpapi.dll` 的 `GetExtendedTcpTable`
  P/Invoke（单次 0.27 ms），失败才回退到 cmdlet。
- **端口释放有延迟**：`Stop-Process -Force` 返回后，进程还要 1~2 秒才真正退出，
  端口在这之后才释放。重启必须**等端口真正空了**再启动新进程，否则新 uvicorn
  会因「address already in use」失败。停止/重启都要带超时（本项目用 20 秒）。
- 开机自启默认关闭，`schtasks` 建 `OCR 服务自启` 登录任务，动作是隐藏运行
  `tools/start_service_bg.ps1`（只启动服务、不改配置、不弹 UAC）。
- 调 `schtasks.exe` 必须走 `Invoke-Schtasks` 包装，否则在
  `$ErrorActionPreference = "Stop"` 下会因 stderr 中断脚本。
- 自检：`powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\panel.ps1 -SelfTest`
  （不弹窗口，不打印 token，只输出 `token_present` / `token_len`）。
- **快捷方式不要指向 `.bat`**：会闪 cmd 窗口，图标也会变成 cmd 默认图标；
  也不要在 `.bat` 里加 `Start-Process -Verb RunAs`，会多闪一个窗口。
- **`.bat` 里禁止任何前台慢操作**。双击 `.bat` 时 cmd.exe 必然先开一个控制台，
  而且这个控制台**只在本文件执行完才关闭**。早先 `OCR-Panel.bat` 内联调
  `powershell -File make_icon.ps1` / `make_shortcut.ps1`，导致黑窗口停留 14 秒
  （用户描述为“打开面板会保留一个 powershell 框”）。现在 `.bat` 只做一件事：
  `start "" /b wscript.exe //nologo tools\panel_launch.vbs` 后立刻 `exit /b`，
  实测 0.14 秒关闭。图标/快捷方式生成全部移入 `tools\panel_launch.vbs`，
  用 `ShellExecute(..., "open", 0)` 异步隐藏执行，不阻塞面板。
- **验证“无窗口”要看 `IsWindowVisible`**，不能只看类名。每个 powershell 进程
  都带一个**隐藏的** `ConsoleWindowClass`（标题「管理员: Windows PowerShell」），
  它正常且不可见；误报通常来自旧进程残留或测试脚本自身的 `cmd`。判据：
  启动后可见控制台窗口数应保持不变，且 `.lnk`（`wscript`）路径下应为 0。
- `.bat` 图标由系统固定无法自定义，带图标的入口只能是 `.lnk`。快捷方式含绝对路径，
  **不打包**，由 `setup_new_server.ps1` / `update_ocr.ps1` / `panel.ps1`（`Add_Shown`）
  调用 `tools\make_shortcut.ps1` 重建；`build_portable.ps1` 打包时剔除残留 `.lnk`。
- **ICO 每个尺寸必须是真正的 32bpp DIB（含 256px）**：GDI+/WinForms/Explorer 不解码
  PNG 压缩条目，PNG 字节配 DIB 头会让 48px 以上全变噪点。验证时要逐个尺寸
  `ToBitmap().Save()` 看画面是否清晰，不能只看是否不报错。
- 面板上**完整显示安装地址 / 服务器地址 / token**（方便直接复制，不要做遮挡）。
- 状态判断用「端口监听 + `/health` 200」两层，只看端口会把“正在加载模型”误报成运行中。
- 端口、路径、地址全部从 `server/config.json` / `server/app.py` 读取，不要硬编码。
- 样式控件在 `tools/ui_kit.ps1`（`panel.ps1` 点源引入），配色只在 `$script:ui` 改。
  `Paint` 处理器里**不要用 `.GetNewClosure()`**（会遮蔽 `$script:ui`，卡片画成空白）。
- `Update-Status` 是独立作用域函数，要刷新的控件统一挂 `$form.Tag`，新增控件记得加进去。
- **函数里改脚本级控件必须带 `$script:` 前缀**，否则函数作用域看不到，控件永远不更新。
- **不要把 `$args` 当循环变量**（赋值会被丢弃，值变成 `@($null)`），
  同理避开 `$input`、`$error`、`$host`。
- `Add_Shown` / `Timer.Tick` 里的异常会被静默吞掉，两处都要 `try/catch` 写入面板日志。
- 「检查更新」比对 `server/app.py` 的 `__version__` 与油猴 `@version` 取较大值，
  并依次尝试直连 / 常见本地代理端口，不要假定系统代理可用。

### 环境

- 在非交互 shell 里执行含 `Start-Process` / `Stop-Process` 的脚本，可能报
  `Unknown: ChildProcess.kill`，但服务可能已启动；**以 `/version` 实际响应为准**。
- 提权会话与普通会话隔离：跨权限截图、`PrintWindow`、`mouse_event` 都不可靠，
  验证面板优先用 UI Automation 读控件树。
- **UI Automation 点不动自绘按钮**（`New-StyleButton`）：从非 STA 宿主调用时
  `GetCurrentPattern(InvokePattern)` 抛「不支持的模式」，`PostMessage(WM_LBUTTONDOWN)`
  也不会触发 WinForms 的 `Click`。要验证按钮行为，用
  `SetCursorPos` + `mouse_event` 发**真实鼠标事件**（先 `SetForegroundWindow`），
  或枚举子窗口句柄后匹配标题指纹。
- **中文标题在管道里会被控制台代码页吃掉**，导致字符串比较永远失败。
  比较按钮文字时用「长度 + 字符哈希」指纹，或从码点构造字符串，别直接比对中文。

---

## 12. Definition of Done

1. 代码改完，行为符合需求
2. 版本号两处一致，`docs/README-zh.md` 标题已更新
3. `docs/CHANGELOG.md` 与油猴头部 CHANGELOG 已更新
4. 第 8 节全部通过
5. **第 9 节清理清单全部满足**
6. **已主动询问「是否发布？」并收到答复**
7. 若开发者同意发布：`main` 已推送，tag/Release 已创建并验证
8. GreasyFork 已同步到新 `@version`（或确认本次没改 userscript）
9. 向开发者报告：改了什么、版本号、测试结果、是否已发布
