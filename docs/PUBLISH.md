# 发布到 GitHub 指南

本文件说明如何把项目安全地发布到 GitHub，并启用油猴脚本在线更新。

> **发布前必须先获得开发者许可。** 每轮开发完成后，Agent 要主动询问「是否发布？」，
> 得到明确答复后才能执行下面第 4 节的推送步骤。见见 `AGENTS.md` 第 0.1 节。

## 0. 发布前检查

- [ ] `server/config.json` 不在版本库中（已被 `.gitignore` 忽略）
- [ ] `userscript/local-captcha-autofill.user.js` **不含 token/服务器地址**
- [ ] 不需要提交的文件：`server/config.json`、`docs/TEST-REPORT-*.md`、`tools/test-assets/benchmark-report.html`、`.venv/`、`python/`、`debug-images/`、`OCR-portable.zip`
- [ ] **工作区已清理**：没有临时脚本（`__*`）、临时笔记/报告、下载的 zip、解压临时目录
- [ ] `git status --porcelain --untracked-files=all` 里每个未跟踪文件都有结论（入库/忽略/删除）

> AI 协作的完整清理清单见 `AGENTS.md` 第 9 节。

## 1. 更新地址

脚本头里的 `@updateURL` / `@downloadURL` 已指向正式仓库
`Piggya/OCR_captcha`，正常发版无需再改。

> 只要 `@version` 递增，Tampermonkey 便会从 `@updateURL` 自动拉取新版本。
> 无法访问 GitHub 时，用脚本菜单「从 OCR 服务器更新脚本…」（只更新脚本，不更新服务端）。

## 2. 仓库历史现状

仓库 `main` 分支以**孤立分支**方式创建（0.9.0 时的 `Initial public release`），
远端只包含当前文件，历史里没有 `server/config.json` 或旧 token，**不需要再重建历史**。

如果将来确实需要清理历史，用：

```powershell
git filter-repo --path server/config.json --invert-paths
```

并务必轮换 token。**不要**随意执行 `git checkout --orphan` 重建分支，会影响 GreasyFork 的更新链路。

## 3. 发布后

- GitHub 仓库主页不显示文档（根目录只保留 `OCR-Panel.bat` 与 `README-FIRST.txt`），
  完整说明在 `docs/README-zh.md`
- Release 必须上传 **`OCR-portable.zip`** 附件：只有它能做到零环境运行，
  源码 zip 不含 `python\`，新电脑无法直接启动
- 局域网设备安装：打开 `http://<服务器IP>:1205/userscript.user.js` 即可，服务端会自动注入 Server URL + token，无需手动填写
- 外网用户安装：`https://raw.githubusercontent.com/<用户>/<仓库>/main/userscript/local-captcha-autofill.user.js`

## 4. 后续发版流程

1. 改代码，更新 `server/app.py` 与脚本头的 `@version`（保持一致）
2. 更新 `docs/CHANGELOG.md`
3. 跑测试：
   ```powershell
   python tools\test_e2e.py
   ```
4. 清理工作区（见 `AGENTS.md` 第 9 节）
5. 构建便携包（会重新下载 Python embeddable 并安装依赖，耗时较长）：
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_portable.ps1
   ```
   > 构建前必须先停止服务，`cv2.pyd` 被占用会失败。
6. 提交并推送：
   ```powershell
   git add -A
   git commit -m "vX.Y.Z: ..."
   git push
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
7. **创建 Release 时必须上传 `OCR-portable.zip` 附件**（关键步骤）。

## 4.1 Release 必须附带便携包

源码 zip（GitHub 自动生成）**不包含 `python\` 目录**，目标电脑若没有安装
Python 与全部依赖，双击 `OCR-Panel.bat` 会报 `No module named 'ddddocr'`。

因此每次创建 Release 都必须把 `OCR-portable.zip` 作为附件上传：

```powershell
# 需要 GitHub token（从凭据管理器读取，不要打印）
$tok = (git credential fill <<< ...)   # 见 AGENTS.md 第 10 节
$rel = Invoke-RestMethod -Uri "https://api.github.com/repos/Piggya/OCR_captcha/releases" `
    -Method Post -Headers @{ Authorization = "token $tok" } `
    -ContentType "application/json" -Body (@{
        tag_name = "vX.Y.Z"; name = "vX.Y.Z"; draft = $false
    } | ConvertTo-Json)

# upload_url 去掉 {?name,label} 模板后缀
$upload = ($rel.upload_url -split "\{")[0] + "?name=OCR-portable.zip"
Invoke-RestMethod -Uri $upload -Method Post `
    -Headers @{ Authorization = "token $tok"; "Content-Type" = "application/zip" } `
    -InFile "OCR-portable.zip"
```

发布后必须验证附件确实可下载（浏览器打开 Release 页面，确认能看到
`OCR-portable.zip` 并显示约 160 MB）。

> Tampermonkey 默认每 24 小时检查一次更新，也可手动“检查用户脚本更新”。

## 5. 安全提醒

- 永远不要把 `server/config.json`、真实 token、局域网 IP 提交到公开仓库
- 局域网部署也建议定期轮换 token
- 不要把 1205 端口暴露到公网
