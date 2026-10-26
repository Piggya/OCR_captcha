# 土著内网验证码识别 v0.9.5

公司局域网用的纯本地验证码识别 + 自动填充方案。基于 FastAPI + ddddocr + Tampermonkey。

---

## 系统架构

```
┌─────────────────────────┐     ┌─────────────────────────┐
│   服务端（你的电脑）      │     │    客户端（局域网）              │
│                         │     │                         │
│  FastAPI + ddddocr      │ ◄── │  Tampermonkey 油猴脚本   │
│  监听 0.0.0.0:1205      │     │  GM_xmlhttpRequest 调用  │
│  7×24 小时在线           │     │  验证码自动识别 + 填充   │
└─────────────────────────┘     └─────────────────────────┘
```

### 目录结构

```
D:\OCR
├─ assets/                  # 资源文件（logo 等）
├─ server/                  # 服务端代码
│  ├─ app.py                # FastAPI 应用
│  ├─ ocr_engine.py         # OCR 引擎
│  ├─ config.json           # 配置（含 api_token）
│  └─ config.example.json   # 配置模板
├─ userscript/              # 油猴脚本
│  └─ local-captcha-autofill.user.js  # 唯一脚本（无密钥）
├─ tools/                   # 工具脚本
│  ├─ build_portable.ps1    # 构建便携包
│  ├─ setup_new_server.ps1  # 新设备一键部署
│  ├─ update_ocr.ps1        # 便携版原地更新（保留 config/python）
│  ├─ show_info.ps1         # 显示/复制服务器地址、token、安装地址
│  ├─ check_version_bump.ps1 # 发布前校验 GreasyFork @version 递增
│  └─ restart_server.ps1    # 重启服务
├─ docs/                    # 文档
│  ├─ README.md             # 本文档 - 系统介绍
│  ├─ DEPLOY.md             # 部署迁移指南
│  ├─ GREASYFORK.md         # GreasyFork 发布文案
│  └─ CHANGELOG.md          # 开发日志
├─ Start-OCR.bat            # 便携版一键启动（自动提权）
├─ Stop-OCR.bat             # 便携版一键停止
├─ Update-OCR.bat           # 便携版一键更新（自动提权）
├─ Show-OCR-Info.bat        # 显示/复制服务器地址、token、安装地址
├─ README-FIRST.txt         # 便携版给使用者的说明
├─ start_server.ps1         # 启动脚本（开发环境用）
└─ requirements.txt         # Python 依赖
```

---

## 功能特性

- **纯本地运行**：所有 OCR 计算在服务端完成，数据不出公司局域网
- **自动识别填充**：页面加载后自动识别验证码，填入输入框
- **多框架兼容**：支持原生 HTML、Element UI、iView 等常见框架
- **双模型投票**：两个 ddddocr 模型同时识别，结果一致时可信度最高
- **自动重试**：识别结果不合预期时自动刷新重试（最多 5 次）
- **智能缓存**：相同图片直接命中缓存，微秒级返回
- **启发式查找**：页面无标准选择器时，通过关键词 + 尺寸自动定位验证码
- **断路器保护**：连续失败自动暂停 1 小时，避免无限重试
- **用户自定义规则**：可通过油猴菜单为任意网站添加识别规则
- **跨 iframe 支持**：自动遍历同源 iframe 查找验证码元素

---

## 快速开始

### 便携版（推荐给新机器/局域网内其他设备）
1. 下载并解压 `OCR-portable.zip` 到本地目录
2. 双击 `Start-OCR.bat`，UAC 点“是”
3. 把窗口里显示（且已复制到剪贴板）的
   `http://<服务器IP>:1205/userscript.user.js` 发给局域网内的其他设备
4. 这些设备装好 Tampermonkey 后打开该地址安装即可，**无需填写 URL/token**
5. 以后查看/复制完整连接信息：双击 `Show-OCR-Info.bat`（服务器地址 + token + 安装地址，自动进剪贴板）

> 局域网其他电脑**不需要**下载 zip 或安装 Python，只需能访问服务器的 1205 端口 + Tampermonkey。

### 更新

**服务端**
- 能访问 GitHub：双击 `Update-OCR.bat`（自动提权）。保留 `server/config.json` 和 `python/`，更新前备份到 `backup-<时间戳>/`。
- 局域网离线：下载 [main.zip](https://github.com/Piggya/OCR_captcha/archive/refs/heads/main.zip)，拷贝后运行
  `powershell -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"`。
- 不要删除 `server/config.json`，否则 token 会重新生成。
- 从 0.9.1 及更早版本升级：旧包没有 `Update-OCR.bat`，需把新版里的 `Update-OCR.bat` 和 `tools\update_ocr.ps1` 复制进去，或解压完整新包后复制旧 `server/config.json`。

**局域网设备脚本**
- 局域网安装：Tampermonkey 管理面板 →「检查用户脚本更新」，或菜单「从 OCR 服务器更新脚本…」。
- GitHub/GreasyFork 安装：按各自渠道更新；建议重开一次局域网地址切换到服务器托管更新。
- 轮换 token 后升一次 `@version`。

**公开发布**：GreasyFork 文案与步骤见 [GREASYFORK.md](GREASYFORK.md)。只能发布无 token 的公开脚本，服务端仍需用户自行部署。

> 仓库已配置 GreasyFork GitHub Webhook。**每次改脚本并 push 前必须严格递增 `@version`**；发布前运行 `tools\check_version_bump.ps1`，`[FAIL]` 时禁止 push。

### 开发环境
**前提**：Windows 10/11 + PowerShell 5.1+ + Python 3.10+

```powershell
cd <项目目录>
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
.\start_server.ps1
```

`start_server.ps1` 自动完成：
1. 探测本机局域网 IP
2. 生成配置和随机 api_token
3. 启动 uvicorn 服务
4. 打印局域网设备所需的脚本地址（token 由服务端自动注入）

打开 `http://<服务器IP>:1205/userscript.user.js` 安装脚本即可，脚本内的服务器地址和 token 由服务端注入，不需要手动填写。公开 GitHub 上的脚本不含 token，安装后才需要手动配置。

---

## 部署模式

### 单设备（自己用）
打开 `http://127.0.0.1:1205/userscript.user.js` 安装，服务端会自动注入 URL + token。

### 集中部署（推荐）
- 你的电脑作为服务端，7×24 在线
- 局域网设备只需装 Tampermonkey + 打开局域网脚本地址，不需要 Python，也不需要填 URL/token
- 局域网脚本地址只对 `allowed_clients` 中的 IP 提供，并且包含 token，不要发到公网
- 新设备部署详见 [DEPLOY.md](DEPLOY.md)

---

## HTTP 接口

| 方法 | 路径 | 说明 | 鉴权 |
|------|------|------|------|
| GET | `/health` | 健康检查 | 无 |
| GET | `/version` | 版本信息 | 无 |
| GET | `/userscript.user.js` | 油猴脚本（注入当前服务器 URL + token） | IP 白名单 |
| POST | `/recognize` | 识别验证码 | 需 token |

`/userscript.user.js` 只对 `allowed_clients` 中的 IP 返回，并把 `INJECTED_CONFIG`、`@updateURL`、`@downloadURL` 指向当前服务器；响应带 `Cache-Control: no-store`。公开 GitHub 上的同一脚本保持 `INJECTED_CONFIG = null`，不含 token。

### POST /recognize

请求头：`X-API-Token: <token>`（也支持 `Authorization: Bearer <token>`）

请求体：
```json
{ "image": "data:image/png;base64,...", "kind": "text", "site": "app.company.local" }
```

响应：
```json
{ "ok": true, "text": "a8k3", "engine": "ddddocr-dual", "confidence": 0.92, "cached": false, "time_ms": 54.3 }
```

`time_ms`：服务端处理耗时（毫秒），便于排查卡顿。

> 浏览器打开 `http://<服务器IP>:1205/docs` 可使用 Swagger UI 在线调试接口。

| 状态码 | 含义 |
|--------|------|
| 200 | 成功 |
| 400 | base64 错误 / 图片太大 |
| 401 | token 错误 |
| 403 | IP 不在白名单 |
| 422 | 参数校验失败 |
| 500 | OCR 引擎内部错误 |

`engine` 可能值：
- `ddddocr-dual`：双模型一致，最可信
- `ddddocr`：单模型
- `ddddocr-beta`：双模型分歧，取 beta 结果
- `ddddocr-cached`：来自缓存

---

## 配置项（server/config.json）

| 字段 | 默认 | 说明 |
|------|------|------|
| `api_token` | 自动生成 24 字节 | 客户端请求鉴权 |
| `work_lan_ip` | 探测到的 LAN IP | 启动脚本打印给局域网设备的服务器 IP（留空则自动探测） |
| `bind_host` | `0.0.0.0` | 监听地址 |
| `port` | `1205` | 服务端口 |
| `allowed_clients` | 见 config.json | IP 白名单（支持 CIDR） |
| `ocr.dual_model` | `true` | 双模型投票 |
| `ocr.min_char_confidence` | `0.6` | 字符置信度门限 |

---

## 油猴脚本使用说明

### 安装步骤

1. 安装 Tampermonkey 扩展（Edge / Chrome / Firefox 应用商店搜索）
2. **推荐**：直接打开 `http://<服务器IP>:1205/userscript.user.js` 安装（自动注入 URL/token）
3. 或打开油猴管理面板 → 实用工具 → 从文件导入 → 选择 `.user.js` 文件（需手动配置）
4. 打开局域网业务系统登录页，右下角自动弹出识别状态

### 识别结果标签

| 标签 | 含义 |
|------|------|
| `[ddddocr-dual 0.92]` | 双模型一致，最可信 |
| `[ddddocr 0.85]` | 单模型识别 |
| `[ddddocr-beta 0.78]` | 双模型分歧，取 beta 结果 |
| `[缓存]` | 来自本地缓存，微秒级返回 |

### 油猴菜单功能

油猴菜单已精简为 5 项：
- **识别并填码**：手动触发一次识别
- **刷新后识别**：点击验证码刷新按钮后识别
- **OCR 服务器设置…**：打开设置对话框，填写 URL/token、显示 token、测试 `/health`、保存（存浏览器本地）
- **高级功能…**：打开二级对话框，包含大小写切换、重置断路器、站点规则的添加/查看/删除/清空
- **从 OCR 服务器更新脚本…**：打开 `http://<服务器IP>:1205/userscript.user.js`，让 Tampermonkey 检查/重装脚本；无法访问 GitHub 时使用。**它只更新脚本，不更新服务端程序**；服务端升级用 `Update-OCR.bat`。

> 入口在 Tampermonkey **扩展菜单**（页面右上角油猴图标）里；Tampermonkey 管理面板没有开放自定义入口 API，脚本无法往面板里加按钮。
>
> 公开脚本不含 token。从局域网地址安装时，服务端会把 `@updateURL` 指向服务器并注入 URL/token；从 GitHub/GreasyFork 安装时按各自渠道更新。轮换 token 后请升一次 `@version`。

### 验证码规则字段

| 字段 | 说明 |
|------|------|
| `minLength` / `maxLength` | 验证码长度范围 |
| `minConfidence` | 单字符置信度门限，低于此值不自动填入（默认 0.55） |
| `maxAttempts` | 失败重试次数 |
| `charset` | 允许的字符正则集合，如 `0-9a-zA-Z` |
| `letterCase` | 结果大小写：`upper` / `lower` / `preserve`（默认 `upper`，因 ddddocr 输出小写，而部分业务系统的验证码为大写） |
| `uppercase` / `lowercase` | 旧字段，仍兼容；新规则建议用 `letterCase` |
| `imageSelector` / `inputSelector` | 验证码图片 / 输入框 CSS 选择器 |

### 自定义规则（默认选择器不匹配时）

如果目标网站的验证码不在默认选择器里：

**方法一（推荐）**：油猴菜单 → "为本网站添加规则..." → 依次输入验证码图片和输入框的 CSS 选择器

**方法二**：编辑 `userscript/local-captcha-autofill.user.js` 的 `imageSelector` / `inputSelector` 数组，保存后刷新页面即可（脚本直接生效，无需重新生成）

---

## 准确率测试（运维）

`tools/benchmark.py` 用带答案的图片（文件名形如 `captcha-A8K3.png`）对服务跑分，统计完全匹配率、字符准确率与延迟：

```powershell
# 默认扫描 tools\test-assets
& .\.venv\Scripts\python.exe tools\benchmark.py

# 指定自己的图片目录 + 多轮 + 生成 HTML 校验报告
& .\.venv\Scripts\python.exe tools\benchmark.py --dir D:\captchas --repeat 3 --report report.html

# 站点不区分大小写时，忽略大小写差异看真实准确率
& .\.venv\Scripts\python.exe tools\benchmark.py --ignore-case
```

> 提示：ddddocr 默认输出小写字母。若目标站点大写且区分大小写，脚本默认已把结果转成大写（`letterCase: "upper"`）；个别站点可用油猴菜单「切换验证码大小写（大写/小写/原样）」按站点调整。

---

## 安全建议

- 服务端不要暴露到公网（路由器不要做 1205 端口转发）
- 建议将油猴脚本的 `host` 从 `"*"` 改为公司具体域名
- `server/config.json` 含敏感 token，不要提交到代码仓库（已被 `.gitignore` 忽略）
- 油猴脚本**不含 token**：首次使用时在菜单「OCR 服务器设置…」填写，存于浏览器本地
- api_token 由系统自动生成，无需手动修改

---

## 故障排查（客户端）

### 识别多次失败，已暂停 1 小时
断路器已打开，油猴菜单 → "重置本网站断路器" 即可恢复。

### OCR 请求超时
检查网络连通性：
```powershell
Test-NetConnection <服务器IP> -Port 1205
```
返回 `False` 说明防火墙阻断，联系运维开放 1205 端口。

### 识别结果不准确
- 若是字母大小写问题：油猴菜单 →「切换验证码大小写（大写/小写/原样）」，选择与目标站点一致的规则
- 系统自动重试 3 次，成功率约 94%
- 如果持续失败，可通过油猴菜单尝试自定义选择器
- 联系管理员调整 OCR 参数

### 验息屏后服务不可用
服务端电源策略设置为睡眠=从不即可解决。
