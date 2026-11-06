# 土著内网验证码识别

局域网自托管的验证码 OCR 服务 + Tampermonkey 油猴脚本。服务端用 [ddddocr](https://github.com/sml2h3/ddddocr) 识别验证码，浏览器脚本自动填入验证码输入框，适合 10~40 人使用的局域网业务系统/ 内部系统。

- 服务端：FastAPI + ddddocr（双模型投票 + 置信度门控 + LRU 缓存）
- 客户端：Tampermonkey 用户脚本，自动发现验证码图片/输入框
- 部署：Windows，支持便携版 Python，也可用普通 Python 虚拟环境
- **无需外网**；脚本可在线更新（GitHub 或局域网服务器）

## 功能

- 多站点通用：默认 `host: "*"` + 启发式元素发现，也可按站点配置 CSS 选择器
- 双模型投票、逐字符置信度门限、失败重试与断路器
- 图片指纹缓存（同图直接返回，延迟约 1~3ms）
- 大小写可配置（ddddocr 输出小写，可统一转大写或按站点切换）
- 局域网鉴权（token）+ IP 白名单 + 请求体大小限制
- 调试图片分桶保存（可选）
- 准确率/延迟测试工具 `tools/benchmark.py`

## 架构

```
浏览器 (Tampermonkey)
   │  POST /recognize  (X-API-Token)
   ▼
FastAPI (uvicorn :1205)
   │  base64 → Pillow 规范化 → ddddocr(默认+beta)
   ▼
返回 { ok, text, engine, confidence, cached, time_ms }
```

## 最快：下载即用（免 Python）

1. 下载 [`OCR-portable.zip`](https://github.com/Piggya/OCR_captcha/releases/latest/download/OCR-portable.zip)
2. 解压到本地目录，双击 `OCR-Panel.bat` → 点「启动服务」，UAC 点“是”
3. 面板上显示（可点「复制连接信息」）的 `http://<本机IP>:1205/userscript.user.js` 发给局域网内的其他设备
4. 这些设备装 Tampermonkey 后打开该地址安装，**无需填 URL/token**

> **控制面板**（`OCR-Panel.bat`）：状态/版本/地址一览、启动/停止/重启服务、首次配置修复、
> 更新服务端、复制连接信息、查看日志，以及「开机自启」开关（默认关闭）。
> **关闭面板不会停止服务**；需要停止请点「停止服务」。详  [docs/PANEL.md](PANEL.md)。
>
> 根目录的 `launchers\Start-OCR.bat` / `launchers\Stop-OCR.bat` / `launchers\Update-OCR.bat` / `launchers\Show-OCR-Info.bat`
> 是面板里同名功能的命令行后备；`tools\start_server.ps1` 只给开发人员前台调试。

> 局域网其他电脑不需要下载便携包或安装 Python，只要能访问服务器的 1205 端口，并有 Tampermonkey 即可。
>
> 资产尚未发布时，请到 [Releases](https://github.com/Piggya/OCR_captcha/releases) 下载对应版本。

## 从源码部署（开发/服务器）

> 需要 Windows 10/11、Python 3.10+（已在 3.14.2 验证）。

```powershell
git clone https://github.com/Piggya/OCR_captcha.git OCR
cd OCR
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start_server.ps1
```

`tools\start_server.ps1` 首次运行会：

1. 从 `server/config.example.json` 生成 `server/config.json`
2. 自动生成随机 `api_token`
3. 启动 uvicorn：`http://0.0.0.0:1205`（Ctrl+C 停止）
4. 在控制台打印**局域网设备所需的 Server URL 和 token**

健康检查：

```powershell
Invoke-WebRequest http://127.0.0.1:1205/health -UseBasicParsing
# {"ok":true,"engine":"ddddocr"}
```

### 便携版（不装 Python）

在已配置好的机器上运行 `tools/build_portable.ps1` 生成 `OCR-portable.zip`，拷到新机器解压后**双击 `OCR-Panel.bat` 点「启动服务」**即可（自动提权、生成 token、开防火墙、后台启动）。详  [docs/DEPLOY.md](DEPLOY.md)。

启动后如需查看/复制服务器地址、token 和安装地址，在面板上点 **「复制连接信息」**（或双击 `launchers\Show-OCR-Info.bat`），完整信息会自动进剪贴板。

## 更新

**服务端**
- 能访问 GitHub：面板上点「更新服务端」，或双击 `launchers\Update-OCR.bat`（自动提权）。它会下载最新源码，保留 `server/config.json` 和 `python/`，更新前备份到 `backup-时间戳/`，更新后自动重启。
- 局域网无法访问 GitHub：在能上网的机器下载 [源码 zip](https://github.com/Piggya/OCR_captcha/archive/refs/heads/main.zip)，拷过来后以管理员运行：
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"
  ```
- **不要删 `server/config.json`**，否则会生成新 token。
- 从 0.9.1 及更早版本升级：旧包没有 `launchers\Update-OCR.bat`，需把新版里的 `launchers\Update-OCR.bat` 和 `tools\update_ocr.ps1` 复制进去，或解压完整新包后复制旧 `server/config.json`。

**局域网设备脚本**
- 局域网安装：Tampermonkey 管理面板 →「检查用户脚本更新」（`@updateURL` 指向服务器），或脚本菜单「从 OCR 服务器更新脚本…」。
- GitHub 安装：从 GitHub 更新；建议重开一次局域网脚本地址并点“更新”，之后切换到服务器托管更新。
- 轮换 token：升一次 `@version`，客户端自动拉取；否则让局域网设备重新打开安装地址安装一次。

## 安装油猴脚本

1. 浏览器安装 [Tampermonkey](https://www.tampermonkey.net/)
2. 打开 `http://<服务器IP>:1205/userscript.user.js` 安装
   - 或把仓库里的 `userscript/local-captcha-autofill.user.js` 直接拖进 Tampermonkey
3. **从服务器地址安装时不需要任何手动配置**：服务端会把当前 URL + token 注入脚本
   - 只有直接使用公开 GitHub/GreasyFork 脚本时，才需要在油猴扩展菜单「**OCR 服务器设置…**」打开设置对话框填一次
   - Tampermonkey 管理面板不支持自定义入口，入口只能在扩展菜单里

> 局域网脚本地址包含 token，且只对 `allowed_clients` 中的 IP 返回；公开 GitHub 脚本保持无 token。两种安装方式保存的配置都在浏览器本地（`GM_setValue`），升级脚本不会丢失。

## 在线更新

脚本头包含：

```js
// @updateURL    https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js
// @downloadURL  https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js
```

脚本头已指向本仓库。发布后，`@version` 变大时 Tampermonkey 会自动拉取（也可手动“检查用户脚本更新”）。

**无法访问 GitHub 时**：服务端同样托管了脚本。菜单「**从 OCR 服务器更新脚本…**」会打开 `http://<服务器IP>:1205/userscript.user.js`，由 Tampermonkey 检查/重装脚本。它只更新脚本，不更新服务端程序；服务端升级用 `launchers\Update-OCR.bat`。服务端返回的脚本会把 `@updateURL` / `@downloadURL` 改成自身地址，并重新注入当前 token，所以更新后也能自动同步 token。

**公开发布（GreasyFork）**：可把无 token 的公开脚本发布到 GreasyFork，方便搜索“局域网验证码 OCR”。发布文案、分类、隐私说明  [docs/GREASYFORK.md](GREASYFORK.md)。服务端仍需用户自行部署；局域网内的设备仍建议使用服务器注入地址。

> 仓库已配置 GreasyFork GitHub Webhook。**每次修改脚本并 push 前必须严格递增 `@version`**（同版本会被拒绝，用户收不到更新）；发布前运行 `tools\check_version_bump.ps1`。

## API

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/health` | 否 | 健康检查 |
| GET | `/version` | 否 | 版本信息 |
| GET | `/userscript.user.js` | IP 白名单 | 油猴脚本（注入 URL + token） |
| GET | `/docs` | 否 | Swagger UI |
| POST | `/recognize` | 是 | 识别验证码 |

```json
// 请求
{ "image": "data:image/png;base64,...", "kind": "text", "site": "app.company.local" }
// 响应
{ "ok": true, "text": "A8K3", "engine": "ddddocr-dual", "confidence": 0.99, "cached": false, "time_ms": 54.3 }
```

鉴权头：`X-API-Token: <token>` 或 `Authorization: Bearer <token>`。

## 目录结构

```
server/         FastAPI 应用、OCR 引擎、配置示例
userscript/     Tampermonkey 脚本（唯一源，无密钥）
tools/          部署、构建、测试、基准工具
docs/           全部文档：README-zh、AGENTS、PUBLISH、DEPLOY、CHANGELOG 等
launchers/      启动、停止、更新等快捷脚本
assets/         图标资源
python/         便携版内置的 Python 运行时与依赖

OCR-Panel.bat   根目录唯一入口（首次运行会自动生成带 Logo 的快捷方式）
README-FIRST.txt 便携版使用说明
LICENSE
requirements.txt 依赖清单
```

`launchers\` 下的脚本：

```
launchers\Start-OCR.bat      便携版一键启动（自动提权、配置 token、放行防火墙）
launchers\Stop-OCR.bat       便携版一键停止
launchers\Update-OCR.bat     便携版一键更新（保留 config / python）
launchers\Show-OCR-Info.bat  显示并复制服务器地址、token、安装地址
```

开发调试入口（日常不使用）：`tools\start_server.ps1`、`tools\restart_server.ps1`、
`launchers\start_server.bat`。

## 安全说明

- `server/config.json`（含真实 token）已被 `.gitignore` 忽略，**不要提交**
- 公开的油猴脚本不含 token；token 只存在于服务器配置和用户浏览器本地
- 局域网 `/userscript.user.js` 会注入 token，只对 `allowed_clients` 中的 IP 返回；该地址不要发到公网
- 默认只监听局域网：`allowed_clients` 白名单 + `trust_proxy=false`
- 不要把 1205 端口映射到公网

## 常 问题

- **识别结果大小写不对**：菜单「切换验证码大小写（大写/小写/原样）」
- **识别不准**：`tools/benchmark.py` 跑分定位；见 `README-zh.md`
- **服务端更新**：`CHANGELOG.md`

## 许可证

[MIT](LICENSE)。第三方依赖（ddddocr、onnxruntime、FastAPI、Pillow 等）遵循各自许可证。
