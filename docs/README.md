# 土著内网验证码识别 v0.9.0

公司内网用的纯本地验证码识别 + 自动填充方案。基于 FastAPI + ddddocr + Tampermonkey。

---

## 系统架构

```
┌─────────────────────────┐     ┌─────────────────────────┐
│   服务端（你的电脑）      │     │   客户端（同事浏览器）    │
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
│  └─ restart_server.ps1    # 重启服务
├─ docs/                    # 文档
│  ├─ README.md             # 本文档 - 系统介绍
│  ├─ DEPLOY.md             # 部署迁移指南
│  └─ CHANGELOG.md          # 开发日志
├─ start_server.ps1         # 启动脚本（开发环境用）
└─ requirements.txt         # Python 依赖
```

---

## 功能特性

- **纯本地运行**：所有 OCR 计算在服务端完成，数据不出公司内网
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

## 快速开始（开发环境）

**前提**：Windows 10/11 + PowerShell 5.1+ + Python 3.10+

```powershell
cd <项目目录>
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
.\start_server.ps1
```

`start_server.ps1` 自动完成：
1. 探测本机内网 IP
2. 生成配置和随机 api_token
3. 启动 uvicorn 服务
4. 打印同事所需的 Server URL、token 和脚本地址

启动后打开 `http://<服务器IP>:1205/userscript.user.js` 安装脚本，再在油猴菜单「设置服务器地址与 token…」填入 URL + token。

---

## 部署模式

### 单设备（自己用）
打开 `http://127.0.0.1:1205/userscript.user.js` 安装，填入 URL + token。

### 集中部署（推荐）
- 你的电脑作为服务端，7×24 在线
- 同事只需装 Tampermonkey + 安装脚本 + 填一次 URL/token，不需要 Python
- 新设备部署详见 [DEPLOY.md](DEPLOY.md)

---

## HTTP 接口

| 方法 | 路径 | 说明 | 鉴权 |
|------|------|------|------|
| GET | `/health` | 健康检查 | 无 |
| GET | `/version` | 版本信息 | 无 |
| POST | `/recognize` | 识别验证码 | 需 token |

### POST /recognize

请求头：`X-API-Token: <token>`（也支持 `Authorization: Bearer <token>`）

请求体：
```json
{ "image": "data:image/png;base64,...", "kind": "text", "site": "oa.company.local" }
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
| `work_lan_ip` | 探测到的 LAN IP | 启动脚本打印给同事的服务器 IP（留空则自动探测） |
| `bind_host` | `0.0.0.0` | 监听地址 |
| `port` | `1205` | 服务端口 |
| `allowed_clients` | 见 config.json | IP 白名单（支持 CIDR） |
| `ocr.dual_model` | `true` | 双模型投票 |
| `ocr.min_char_confidence` | `0.6` | 字符置信度门限 |

---

## 油猴脚本使用说明

### 安装步骤

1. 安装 Tampermonkey 扩展（Edge / Chrome / Firefox 应用商店搜索）
2. 打开油猴管理面板 → 实用工具 → 从文件导入 → 选择 `.user.js` 文件
3. 打开公司 OA 登录页，右下角自动弹出识别状态

### 识别结果标签

| 标签 | 含义 |
|------|------|
| `[ddddocr-dual 0.92]` | 双模型一致，最可信 |
| `[ddddocr 0.85]` | 单模型识别 |
| `[ddddocr-beta 0.78]` | 双模型分歧，取 beta 结果 |
| `[缓存]` | 来自本地缓存，微秒级返回 |

### 油猴菜单功能

在油猴图标菜单中可使用以下功能：
- **识别并填入验证码**：手动触发一次识别
- **刷新验证码后识别**：点击验证码刷新按钮后识别
- **切换验证码大小写（大写/小写/原样）**：按站点修正字母大小写，切换后自动重新识别
- **重置本网站断路器**：连续失败被暂停后手动恢复
- **为本网站添加规则...**：添加自定义 CSS 选择器
- **查看本网站规则**：查看当前网站已保存的规则
- **删除本网站规则**：删除当前网站的规则
- **设置服务器地址与 token…**：首次使用或更换服务器时填写（存浏览器本地）
- **查看当前服务器**：显示当前 Server URL
- **从服务器更新脚本（内网）**：隔离内网时从 `http://<服务器IP>:1205/userscript.user.js` 更新

> 脚本不含 token。能上外网时按 `@updateURL` 自动更新；隔离内网用上面的菜单更新。

### 验证码规则字段

| 字段 | 说明 |
|------|------|
| `minLength` / `maxLength` | 验证码长度范围 |
| `minConfidence` | 单字符置信度门限，低于此值不自动填入（默认 0.55） |
| `maxAttempts` | 失败重试次数 |
| `charset` | 允许的字符正则集合，如 `0-9a-zA-Z` |
| `letterCase` | 结果大小写：`upper` / `lower` / `preserve`（默认 `upper`，因 ddddocr 输出小写而 OA 为大写） |
| `uppercase` / `lowercase` | 旧字段，仍兼容；新规则建议用 `letterCase` |
| `imageSelector` / `inputSelector` | 验证码图片 / 输入框 CSS 选择器 |

### 自定义规则（换 OA 系统时）

如果新 OA 的验证码不在默认选择器里：

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
- 油猴脚本**不含 token**：首次使用时在菜单「设置服务器地址与 token…」填写，存于浏览器本地
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
