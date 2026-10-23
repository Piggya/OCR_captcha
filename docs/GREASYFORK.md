# GreasyFork 发布指南

## 结论

可以发布。GreasyFork 只托管**油猴脚本**，不托管服务端；适合把公开、无 token 的脚本放到 GreasyFork 让更多人搜到，再在脚本介绍里引导用户去 GitHub 下载 Windows 便携服务端。

但要注意：

- 必须使用你自己的 GreasyFork 账号登录后手动发布，Agent 不能代注册/代发布。
- **只能发布仓库里的公开脚本**：`userscript/local-captcha-autofill.user.js`。它不含 token、不含真实内网 IP。
- **绝对不要**发布 `server/config.json`、`/userscript.user.js` 的服务端注入版、`OCR-portable.zip` 里的 config，或任何含 token 的截图/日志。
- GreasyFork 的内网用户仍需自己部署服务端；GreasyFork 版脚本不包含服务器地址和 token。
- 内网同事仍优先用 `http://<服务器IP>:1205/userscript.user.js`（自动注入 URL/token）；GreasyFork 是公开渠道，不是内网自动配置渠道。

---

## 发布前检查

1. 版本号已升，且 `server/app.py`、脚本 `@version`、`docs/README.md`、CHANGELOG 一致。
2. 脚本头包含：
   - `@name 土著内网验证码识别`
   - `@namespace http://local-captcha-ocr.internal/`（**不要改**，否则油猴视为新脚本）
   - `@license MIT`
   - `@homepageURL` / `@supportURL` / `@source`
   - `@description:zh-CN`
3. `@match *://*/*`、`@connect *` 保持现状（全站自动填码 + 用户可配置任意内网服务器）。
4. 仓库脚本仍是 `const INJECTED_CONFIG = null;`，无 token。
5. GitHub Release 已发布，便携包可下载。

---

## GreasyFork 表单填写

| 字段 | 建议值 |
|------|--------|
| 脚本名称 | `土著内网验证码识别` |
| 命名空间 | `http://local-captcha-ocr.internal/`（保持原值） |
| 版本 | 与脚本 `@version` 一致，例如 `0.9.2` |
| 描述 | 用下面的「简介」 |
| 分类 | `Productivity`（效率/生产力） |
| 许可证 | `MIT` |
| 脚本代码 | 粘贴 `userscript/local-captcha-autofill.user.js` 全文，或从 raw 地址导入 |
| 附加信息 | 用下面的「脚本介绍」 |
| 标签 | `验证码`、`OCR`、`captcha`、`自动填码`、`内网`、`自托管`、`ddddocr` |

> GreasyFork 可能会自动改写 `@updateURL` / `@downloadURL` 指向 GreasyFork。这是正常的，不要为了保留 GitHub 地址去对抗平台。内网安装的脚本由服务端注入，更新地址仍会指向内网服务器。

### 简介（短描述）

```text
自托管内网验证码识别：用你自己的 OCR 服务自动识别并填入验证码。需自行部署服务端，GitHub 提供 Windows 便携包。
```

### 脚本介绍（可直接粘贴）

```markdown
## 这是什么

一个**自托管**的验证码自动识别/填码脚本。它把页面上的验证码图片发送到**你自己的 OCR 服务**，识别后自动填入输入框。

- 服务端：FastAPI + ddddocr，双模型投票、置信度门控、LRU 缓存
- 客户端：本脚本，自动发现验证码图片/输入框
- 默认端口：`1205`
- 适用：公司内网、OA、自建系统等需要反复输入验证码的场景

> 本脚本**不包含**服务器地址和 token，也不提供公用服务器。必须自己部署服务端。

## 先部署服务端（Windows，推荐便携包）

1. 打开 GitHub Releases：
   https://github.com/Piggya/OCR_captcha/releases/latest
2. 下载 `OCR-portable.zip`
3. 解压到本地目录（例如 `D:\OCR`），双击 `Start-OCR.bat`
4. 窗口会显示并复制脚本地址：
   `http://<服务器IP>:1205/userscript.user.js`
5. 内网同事直接打开这个地址安装即可，**URL/token 会自动注入，无需手填**

服务端源码、部署文档、更新工具：
https://github.com/Piggya/OCR_captcha

## 从 GreasyFork 安装后怎么配置

本脚本从 GreasyFork 安装时不含服务器信息。安装后：

1. 打开 Tampermonkey 菜单
2. 选择「设置服务器地址与 token…」
3. 填入你的服务端地址，例如 `http://192.168.1.10:1205`
4. 填入 `server/config.json` 里的 `api_token`

也可以直接打开服务端的内网脚本地址重装一次，脚本会自动带上配置。

## 更新

- 服务端：便携版双击 `Update-OCR.bat`；保留 `server/config.json` 和 `python/`。
- 脚本：Tampermonkey 按 `@version` 检查更新；内网安装的脚本走服务器更新地址。
- 轮换 token 后请升一次脚本版本，或让同事重开内网脚本地址安装。

## 隐私与安全

- 验证码图片只发送到**你自己配置的 OCR 服务**，不经过第三方服务器。
- 脚本不收集、不上传浏览记录、表单内容或账号信息。
- `@connect *` 是为了允许用户填写任意内网服务器地址；脚本本身不含远程服务器。
- `@match *://*/*` 是为了全站发现验证码；这是用户明确需要的功能。
- 请只在内网分发含 token 的脚本地址，不要把 `server/config.json` 或带 token 的 URL 发到公网。

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
   - 能搜到「验证码 OCR」「内网验证码」等关键词
   - 代码里没有 token / 真实内网 IP
   - `@version` 正确
   - 安装按钮可用
7. 可选：上传 1-2 张截图（只截菜单和填码结果，**不要截 token、config.json、内网地址**）

## 后续更新 GreasyFork

1. 本地升 `@version`、写 CHANGELOG、跑测试、推 GitHub
2. 在 GreasyFork 脚本页点 **更新脚本**（Update script），粘贴新代码
3. 确认 GreasyFork 显示的版本号递增
4. 不要改 `@name` / `@namespace`，否则会变成新脚本，老用户收不到更新

> GreasyFork 的版本必须不小于当前版本；否则平台会拒绝更新。

---

## 常见审核问题

**为什么匹配所有网站？**
脚本需要在任意 OA/自建系统上发现验证码；用户可随时在 Tampermonkey 里禁用。

**为什么 `@connect *`？**
服务器地址由用户自己填写，可能是任意内网 IP/端口，无法预先枚举。

**会不会偷数据？**
不会。脚本只把验证码图片 POST 到用户配置的 OCR 服务；不读取账号密码，不向第三方发送数据。服务端代码公开可审计。

**能不能直接给一个能用的服务器？**
不能。这是自托管项目，不提供公用 token；请按 README 部署自己的服务端。
