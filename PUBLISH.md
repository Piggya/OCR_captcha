# 发布到 GitHub 指南

本文件说明如何把项目安全地发布到 GitHub，并启用油猴脚本在线更新。

## 0. 发布前检查

- [ ] `server/config.json` 不在版本库中（已被 `.gitignore` 忽略）
- [ ] `userscript/local-captcha-autofill.user.js` **不含 token/服务器地址**（0.9.0 起）
- [ ] 已轮换旧 token（旧 token 曾出现在历史提交里，见下方“干净历史”）
- [ ] 不需要提交的文件：`server/config.json`、`docs/TEST-REPORT-*.md`、`tools/test-assets/benchmark-report.html`、`.venv/`、`python/`、`debug-images/`、`OCR-portable.zip`

## 1. 设置更新地址

把脚本头里的占位用户名替换成你的 GitHub 用户名/仓库名：

```powershell
$user = "你的GitHub用户名"
$repo = "OCR_captcha"
$files = @("userscript\local-captcha-autofill.user.js", "README.md")
foreach ($f in $files) {
    $text = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)
    $text = $text -replace 'YOUR_GITHUB_USER', $user -replace 'OCR-captcha', $repo
    # 注意：必须写无 BOM 的 UTF-8，否则可能影响油猴脚本头识别
    [IO.File]::WriteAllText($f, $text, (New-Object System.Text.UTF8Encoding($false)))
}
```

> 只要 `@version` 递增，Tampermonkey 便会从 `@updateURL` 自动拉取新版本。
> 无法访问 GitHub 时，用脚本菜单「从 OCR 服务器更新脚本…」（只更新脚本，不更新服务端）。

## 2. 用“干净历史”发布（重要）

**不要直接推送现有的 `.git`**：旧提交里包含 `server/config.json` 的真实 token。推荐用孤立分支只发布当前文件：

```powershell
# 在项目根目录
git checkout --orphan public
git add -A
git commit -m "Initial public release v0.9.0"

git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git push -u origin public:main
```

这样远端只有这一个提交，旧历史（含 token）不会被推送。

> 如果你坚持保留历史，请使用 `git filter-repo --path server/config.json --invert-paths` 清理后再推送，并务必轮换 token。

## 3. 发布后

- GitHub 仓库主页会直接显示根目录 `README.md`
- 局域网设备安装：打开 `http://<服务器IP>:1205/userscript.user.js` 即可，服务端会自动注入 Server URL + token，无需手动填写
- 外网用户安装：`https://raw.githubusercontent.com/<用户>/<仓库>/main/userscript/local-captcha-autofill.user.js`

## 4. 后续发版流程

1. 改代码，更新 `server/app.py` 与脚本头的 `@version`（保持一致）
2. 更新 `docs/CHANGELOG.md`
3. 跑测试：
   ```powershell
   .\.venv\Scripts\python.exe tools\test_e2e.py
   ```
4. 提交并推送：
   ```powershell
   git add -A
   git commit -m "v0.9.x: ..."
   git push
   ```

> Tampermonkey 默认每 24 小时检查一次更新，也可手动“检查用户脚本更新”。

## 5. 安全提醒

- 永远不要把 `server/config.json`、真实 token、局域网 IP 提交到公开仓库
- 局域网部署也建议定期轮换 token
- 不要把 1205 端口暴露到公网
