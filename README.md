# 土著内网验证码识别

内网自托管的验证码 OCR 服务 + Tampermonkey 油猴脚本。服务端用 [ddddocr](https://github.com/sml2h3/ddddocr) 识别验证码，浏览器脚本自动填入验证码输入框，适合 10~40 人的局域网 OA / 内部系统。

- 服务端：FastAPI + ddddocr（双模型投票 + 置信度门控 + LRU 缓存）
- 客户端：Tampermonkey 用户脚本，自动发现验证码图片/输入框
- 部署：Windows，支持便携版 Python，也可用普通 Python 虚拟环境
- **无需外网**；脚本可在线更新（GitHub 或内网服务器）

## 功能

- 多站点通用：默认 `host: "*"` + 启发式元素发现，也可按站点配置 CSS 选择器
- 双模型投票、逐字符置信度门限、失败重试与断路器
- 图片指纹缓存（同图直接返回，延迟约 1~3ms）
- 大小写可配置（ddddocr 输出小写，可统一转大写或按站点切换）
- 内网鉴权（token）+ IP 白名单 + 请求体大小限制
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
2. 解压到本地目录，双击 `Start-OCR.bat`，UAC 点“是”
3. 把窗口显示（已复制到剪贴板）的 `http://<本机IP>:1205/userscript.user.js` 发给同事
4. 同事装 Tampermonkey 后打开该地址安装，**无需填 URL/token**

> 资产尚未发布时，请到 [Releases](https://github.com/Piggya/OCR_captcha/releases) 下载对应版本。

## 从源码部署（开发/服务器）

> 需要 Windows 10/11、Python 3.10+（已在 3.14.2 验证）。

```powershell
git clone https://github.com/Piggya/OCR_captcha.git OCR
cd OCR
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\start_server.ps1
```

`start_server.ps1` 首次运行会：

1. 从 `server/config.example.json` 生成 `server/config.json`
2. 自动生成随机 `api_token`
3. 启动 uvicorn：`http://0.0.0.0:1205`（Ctrl+C 停止）
4. 在控制台打印**同事所需的 Server URL 和 token**

健康检查：

```powershell
Invoke-WebRequest http://127.0.0.1:1205/health -UseBasicParsing
# {"ok":true,"engine":"ddddocr"}
```

### 便携版（不装 Python）

在已配置好的机器上运行 `tools/build_portable.ps1` 生成 `OCR-portable.zip`，拷到新机器解压后**双击 `Start-OCR.bat`** 即可（自动提权、生成 token、开防火墙、后台启动）。详见 [docs/DEPLOY.md](docs/DEPLOY.md)。

## 安装油猴脚本

1. 浏览器安装 [Tampermonkey](https://www.tampermonkey.net/)
2. 打开 `http://<服务器IP>:1205/userscript.user.js` 安装
   - 或把仓库里的 `userscript/local-captcha-autofill.user.js` 直接拖进 Tampermonkey
3. **从服务器地址安装时不需要任何手动配置**：服务端会把当前 URL + token 注入脚本
   - 只有直接使用公开 GitHub 脚本时，才需要在菜单「**设置服务器地址与 token…**」填一次

> 内网脚本地址包含 token，且只对 `allowed_clients` 中的 IP 返回；公开 GitHub 脚本保持无 token。两种安装方式保存的配置都在浏览器本地（`GM_setValue`），升级脚本不会丢失。

## 在线更新

脚本头包含：

```js
// @updateURL    https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js
// @downloadURL  https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js
```

脚本头已指向本仓库。发布后，`@version` 变大时 Tampermonkey 会自动拉取（也可手动“检查用户脚本更新”）。

**隔离内网**（无法访问 GitHub）：服务端同样托管了脚本，菜单「**从服务器更新脚本（内网）**」会打开 `http://<服务器IP>:1205/userscript.user.js`，由 Tampermonkey 完成更新。服务端返回的脚本会把 `@updateURL` / `@downloadURL` 改成自身地址，并重新注入当前 token，所以内网更新也能自动同步 token。

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
{ "image": "data:image/png;base64,...", "kind": "text", "site": "oa.company.local" }
// 响应
{ "ok": true, "text": "A8K3", "engine": "ddddocr-dual", "confidence": 0.99, "cached": false, "time_ms": 54.3 }
```

鉴权头：`X-API-Token: <token>` 或 `Authorization: Bearer <token>`。

## 目录结构

```
server/         FastAPI 应用、OCR 引擎、配置示例
userscript/     Tampermonkey 脚本（唯一源，无密钥）
tools/          部署、构建、测试、基准工具
docs/           使用文档、部署指南、更新日志
install.ps1     首次安装（建 venv + 依赖）
start_server.ps1 生成配置并启动服务
Start-OCR.bat   便携版一键启动（自动提权）
Stop-OCR.bat    便携版一键停止
README-FIRST.txt 便携版给使用者的说明
```

## 安全说明

- `server/config.json`（含真实 token）已被 `.gitignore` 忽略，**不要提交**
- 公开的油猴脚本不含 token；token 只存在于服务器配置和用户浏览器本地
- 内网 `/userscript.user.js` 会注入 token，只对 `allowed_clients` 中的 IP 返回；该地址不要发到公网
- 默认只监听内网：`allowed_clients` 白名单 + `trust_proxy=false`
- 不要把 1205 端口映射到公网

## 常见问题

- **识别结果大小写不对**：菜单「切换验证码大小写（大写/小写/原样）」
- **识别不准**：`tools/benchmark.py` 跑分定位；见 `docs/README.md`
- **服务端更新**：`docs/CHANGELOG.md`

## 许可证

[MIT](LICENSE)。第三方依赖（ddddocr、onnxruntime、FastAPI、Pillow 等）遵循各自许可证。
