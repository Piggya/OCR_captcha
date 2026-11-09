# 土著内网验证码识别

局域网自托管的验证码 OCR 服务 + Tampermonkey 油猴脚本。服务端用 ddddocr 识别验证码，
浏览器脚本自动填入输入框；**无需外网**，适合局域网内的业务系统 / 自建系统。

- 服务端：FastAPI + ddddocr（双模型投票 + 置信度门控 + LRU 缓存），默认端口 `1205`
- 客户端：Tampermonkey 用户脚本，自动发现验证码图片与输入框
- 部署：Windows 10/11，支持便携版 Python，也可用普通 Python 虚拟环境

> **完整说明在 [`docs/README-zh.md`](../docs/README-zh.md)**。本页只做导航，
> 所有内容以那份文档为准，避免两份说明各说各话。

## 最快上手（免装 Python）

1. 下载 [`OCR-portable.zip`](https://github.com/Piggya/OCR_captcha/releases/latest/download/OCR-portable.zip)
2. 解压到本地目录，双击 `OCR-Panel.bat` → 点「启动服务」，UAC 选“是”
3. 把面板上显示的 `http://<本机IP>:1205/userscript.user.js` 发给局域网内的其他设备
4. 这些设备装好 Tampermonkey 后打开该地址安装，**不需要手填 URL 或 token**

局域网里的其他电脑不用下载便携包，也不用装 Python —— 只要能访问服务器的 1205 端口、
并且有 Tampermonkey 即可。

## 从源码部署

需要 Windows 10/11、Python 3.10+（已在 3.14.2 验证）。

```powershell
git clone https://github.com/Piggya/OCR_captcha.git OCR
cd OCR
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start_server.ps1
```

首次运行会生成 `server/config.json`、随机 `api_token`，启动 uvicorn 到 `http://0.0.0.0:1205`，
并在控制台打印局域网设备所需的地址和 token。

## 文档

| 文档 | 内容 |
|---|---|
| [README-zh.md](../docs/README-zh.md) | 完整说明：功能、架构、安装、更新、API、常见问题 |
| [DEPLOY.md](../docs/DEPLOY.md) | 部署细节、便携版构建、局域网穿透 |
| [PANEL.md](../docs/PANEL.md) | 控制面板说明 |
| [GREASYFORK.md](../docs/GREASYFORK.md) | 公开发布文案与分类 |
| [CHANGELOG.md](../docs/CHANGELOG.md) | 开发日志、各版本变更 |
| [PUBLISH.md](../docs/PUBLISH.md) | 发布流程 |
| [AGENTS.md](../docs/AGENTS.md) | 代码库约定（给后续开发者 / AI Agent） |

## 安全提示

- `server/config.json` 含真实 token，已被 `.gitignore` 忽略，**不要提交**
- 公开的油猴脚本不含 token；token 只存在于服务器配置与用户浏览器本地
- 局域网 `/userscript.user.js` 会注入 token，只对 `allowed_clients` 中的 IP 返回，
  **该地址不要发到公网**
- 默认只监听局域网（IP 白名单 + `trust_proxy=false`），**不要把 1205 端口映射到公网**

## 许可证

[MIT](../LICENSE)。第三方依赖（ddddocr、onnxruntime、FastAPI、Pillow 等）遵循各自许可证。
