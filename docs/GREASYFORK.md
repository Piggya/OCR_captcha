# GreasyFork 发布指南

## 结论

可以发布。GreasyFork 只托管**油猴脚本**，不托管服务端；适合把公开、无 token 的脚本放到 GreasyFork 让更多人搜到，再在脚本介绍里引导用户去 GitHub 下载 Windows 便携服务端。

但要注意：

- 必须使用你自己的 GreasyFork 账号登录后手动发布，Agent 不能代注册/代发布。
- **只能发布仓库里的公开脚本**：`userscript/local-captcha-autofill.user.js`。它不含 token、不含真实局域网 IP。
- **绝对不要**发布 `server/config.json`、`/userscript.user.js` 的服务端注入版、`OCR-portable.zip` 里的 config，或任何含 token 的截图/日志。
- GreasyFork 的局域网用户仍需自己部署服务端；GreasyFork 版脚本不包含服务器地址和 token。
- 局域网内的设备仍优先用 `http://<服务器IP>:1205/userscript.user.js`（自动注入 URL/token）；GreasyFork 是公开渠道，不是局域网自动配置渠道。

---

## 发布前检查

1. 版本号已升，且 `server/app.py`、脚本 `@version`、`docs/README.md`、CHANGELOG 一致。
2. 脚本头包含：
   - `@name 土著内网验证码识别`
   - `@namespace http://local-captcha-ocr.internal/`（**不要改**，否则油猴视为新脚本）
   - `@license MIT`
   - `@homepageURL` / `@supportURL` / `@source`
   - `@description:zh-CN`
3. `@match *://*/*`、`@connect *` 保持现状（全站自动填码 + 用户可配置任意局域网服务器）。
4. 仓库脚本仍是 `const INJECTED_CONFIG = null;`，无 token。
5. GitHub Release 已发布，便携包可下载。
6. `@version` **严格大于** GreasyFork 线上版本，并运行 `tools\check_version_bump.ps1` 通过。

---

## Webhook 自动同步（推荐，配置一次）

仓库 `main` 已配置 GitHub Webhook；之后正常 `git push` 就会自动更新 GreasyFork，不需要再手动粘贴代码。

> **硬性要求**：GreasyFork 只在 `userscript/` 文件发生变化且 `@version` **严格递增**时发布新版本。同版本重复 push 会被拒绝，用户也收不到更新。每次发布前必须运行：
>
> ```powershell
> git fetch origin
> powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check_version_bump.ps1
> ```
>
> `[FAIL]` 时禁止 push，先同时升 `server/app.py __version__` 和油猴 `// @version`。

### 1. 设置脚本同步地址

GreasyFork 脚本页 → 编辑 → 源代码同步（Source syncing）：

```text
https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js
```

保存时选择 **Update and sync**。地址必须与 GitHub 实际文件路径完全一致。

### 2. GreasyFork 生成 Webhook Secret

登录后打开 `https://greasyfork.org/zh-CN/users/webhook-info`，复制页面给出的 **Payload URL**，点 **Generate** 生成 Secret。

### 3. GitHub 添加 Webhook

仓库 `Settings → Webhooks → Add webhook`：

- **Payload URL**：GreasyFork 页面给出的地址
- **Content type**：`application/json`
- **Secret**：GreasyFork 生成的 Secret（只放在 GitHub/GreasyFork 设置里，**不要提交到仓库**）
- **Which events**：`Just the push event`（推荐）
- **Active**：勾选

保存后 GitHub 会发 ping，GreasyFork 显示成功即可。

### 4. 以后发布

```powershell
# 先升版本并跑检查
powershell -File tools\check_version_bump.ps1
git add -A
git commit -m "vX.Y.Z: ..."
git push
```

GitHub push → GreasyFork 拉取 raw 文件 → 自动发布新版本。

不要再用 GreasyFork 的“更新脚本”手动粘贴；如果没更新，检查 GitHub Webhook 的 Recent Deliveries 和 GreasyFork 的同步错误。

> 选 `Release` 事件时，同步地址要改成 `https://github.com/Piggya/OCR_captcha/releases/latest/download/local-captcha-autofill.user.js`，并且每次 Release 都要上传同名 `.user.js` 资产。当前 Release 只上传 `OCR-portable.zip`，所以用 **push 事件**最简单。

---

## GreasyFork 表单填写

| 字段 | 建议值 |
|------|--------|
| 脚本名称 | `土著内网验证码识别` |
| 命名空间 | `http://local-captcha-ocr.internal/`（保持原值） |
| 版本 | 与脚本 `@version` 一致，例如 `0.9.5` |
| 描述 | 用下面的「简介」 |
| 分类 | `Productivity`（效率/生产力） |
| 许可证 | `MIT` |
| 脚本代码 | 粘贴 `userscript/local-captcha-autofill.user.js` 全文，或从 raw 地址导入 |
| 附加信息 | 用下面的「脚本介绍」 |
| 标签 | `验证码`、`OCR`、`captcha`、`自动填码`、`局域网`、`自托管`、`ddddocr` |

> GreasyFork 可能会自动改写 `@updateURL` / `@downloadURL` 指向 GreasyFork。这是正常的，不要为了保留 GitHub 地址去对抗平台。局域网安装的脚本由服务端注入，更新地址仍会指向局域网服务器。

### 简介（短描述）

```text
自托管局域网验证码识别：用你自己的 OCR 服务自动识别并填入验证码。需自行部署服务端，GitHub 提供 Windows 便携包。
```

### 脚本介绍（可直接粘贴）

```markdown
## 这是什么

一个**自托管**的验证码自动识别/填码脚本。它把页面上的验证码图片发送到**你自己的 OCR 服务**，识别后自动填入输入框。

- 服务端：FastAPI + ddddocr，双模型投票、置信度门控、LRU 缓存
- 客户端：本脚本，自动发现验证码图片/输入框
- 默认端口：`1205`
- 适用：公司局域网、业务系统、自建系统等需要反复输入验证码的场景

> 本脚本**不包含**服务器地址和 token，也不提供公用服务器。必须自己部署服务端。

## 先部署服务端（Windows，推荐便携包）

1. 打开 GitHub Releases：
   https://github.com/Piggya/OCR_captcha/releases/latest
2. 下载 `OCR-portable.zip`
3. 解压到本地目录（例如 `D:\OCR`），双击 `Start-OCR.bat`
4. 窗口会显示并复制脚本地址：
   `http://<服务器IP>:1205/userscript.user.js`
5. 局域网内的设备直接打开这个地址安装即可，**URL/token 会自动注入，无需手填**

服务端源码、部署文档、更新工具：
https://github.com/Piggya/OCR_captcha

## 从 GreasyFork 安装后怎么配置

本脚本从 GreasyFork 安装时不含服务器信息。安装后：

1. 打开 Tampermonkey 菜单
2. 选择「OCR 服务器设置…」打开设置对话框
3. 填入你的服务端地址，例如 `http://192.168.1.10:1205`
4. 填入 `server/config.json` 里的 `api_token`
5. 点「测试连接」确认 `/health` 正常，再点「保存」

也可以直接打开服务端的局域网脚本地址重装一次，脚本会自动带上配置。

## 更新

- 服务端：便携版双击 `Update-OCR.bat`；保留 `server/config.json` 和 `python/`。
- 脚本：Tampermonkey 按 `@version` 检查更新；局域网安装的脚本走服务器更新地址。
- 轮换 token 后请升一次脚本版本，或让局域网设备重新打开安装地址安装。

## 隐私与安全

- 验证码图片只发送到**你自己配置的 OCR 服务**，不经过第三方服务器。
- 脚本不收集、不上传浏览记录、表单内容或账号信息。
- `@connect *` 是为了允许用户填写任意局域网服务器地址；脚本本身不含远程服务器。
- `@match *://*/*` 是为了全站发现验证码；这是用户明确需要的功能。
- 请只在局域网分发含 token 的脚本地址，不要把 `server/config.json` 或带 token 的 URL 发到公网。

## 许可

MIT。服务端与脚本源码：
https://github.com/Piggya/OCR_captcha
```

---

## 发布步骤

1. 登录 https://greasyfork.org/
2. 右上角头像 → **发布脚本**（Submit script）
3. 粘贴脚本全文；确认名称、命名空间、版本、描述、许可证
4. 分类选 `Productivity`，标签按上表填写
5. 附加信息粘贴「脚本介绍」
6. 提交后检查脚本页：
   - 能搜到「验证码 OCR」「局域网验证码」等关键词
   - 代码里没有 token / 真实局域网 IP
   - `@version` 正确
   - 安装按钮可用
7. 可选：上传 1-2 张截图（只截菜单和填码结果，**不要截 token、config.json、局域网地址**）

## 后续更新 GreasyFork

1. 同时升 `server/app.py __version__` 和油猴 `// @version`，写 CHANGELOG
2. 跑测试，再运行 `tools\check_version_bump.ps1`，必须 `[OK]`
3. `git commit` + `git push` 到 `main`
4. GitHub Webhook 自动同步 GreasyFork；到脚本页确认 `@version` 已递增
5. 只有 webhook 故障时才临时用 **更新脚本** 手动粘贴；修好后仍以 webhook 为准
6. 不要改 `@name` / `@namespace`，否则会变成新脚本，老用户收不到更新

> **同版本重复 push 会被拒绝，用户也收不到更新。** 每次都必须严格递增 `@version`。

---

## 常见审核问题

**为什么匹配所有网站？**
脚本需要在任意业务系统/自建系统上发现验证码；用户可随时在 Tampermonkey 里禁用。

**为什么 `@connect *`？**
服务器地址由用户自己填写，可能是任意局域网 IP/端口，无法预先枚举。

**会不会偷数据？**
不会。脚本只把验证码图片 POST 到用户配置的 OCR 服务；不读取账号密码，不向第三方发送数据。服务端代码公开可审计。

**能不能直接给一个能用的服务器？**
不能。这是自托管项目，不提供公用 token；请按 README 部署自己的服务端。
