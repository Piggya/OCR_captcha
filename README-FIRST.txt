土著内网验证码识别 - 便携版（Windows）

【这是什么】
一个在内网运行的验证码识别服务。在这台机器上双击一次即可启动；
同事在浏览器安装油猴脚本后，OA 等网站的验证码会自动识别并填入。
脚本地址里已经带好服务器地址和 token，同事不需要手动配置。

【第一次使用】
1. 把 OCR-portable.zip 完整解压到一个本地文件夹
   （例如 D:\OCR-portable）。不要直接在压缩包里运行，
   也不要放在网络共享路径下。
2. 双击 Start-OCR.bat。
3. Windows 弹出“用户账户控制”时点“是”。
   （如果出现 SmartScreen，点“更多信息” → “仍要运行”。）
4. 等待窗口显示 “Setup Complete!”。首次启动约需 10-30 秒。
5. 窗口里会显示一行 Userscript 地址，并且已经复制到剪贴板：
      http://<本机内网IP>:1205/userscript.user.js
   把这行地址发给同事。

【同事怎么用】
1. 浏览器安装 Tampermonkey（油猴）扩展。
2. 打开上面那个地址，点“安装”。
   脚本已经自动带好服务器地址和 token，不需要手动填写。
3. 打开 OA 等网站，验证码会自动识别并填入。

【局域网其他电脑】
其他电脑不需要下载 OCR-portable.zip，也不需要装 Python。只要：
1. 能访问这台服务器的 1205 端口（同一内网/防火墙放行）
2. 浏览器安装 Tampermonkey
3. 打开服务器窗口里给出的脚本地址并安装

【日常】
- 启动：双击 Start-OCR.bat（已启动时会重启服务，token 不变）
- 停止：双击 Stop-OCR.bat
- 查看日志：server.log、server.err.log
- 修改端口/白名单：server\config.json，改完重启服务

【更新服务端】
- 能访问 GitHub：双击 Update-OCR.bat，UAC 点“是”。
  它会下载最新代码，保留 server\config.json 和 python\，
  更新前备份到 backup-时间戳\，更新后自动重启。
- 不能访问 GitHub：在能上网的电脑下载
    https://github.com/Piggya/OCR_captcha/archive/refs/heads/main.zip
  拷到本机，管理员 PowerShell 运行：
    powershell -ExecutionPolicy Bypass -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"
- 更新不会改 token。如果手动改了 token，同事需要重新打开脚本地址安装一次。
- 0.9.1 及更早的包没有 Update-OCR.bat：把新版里的 Update-OCR.bat 和
  tools\update_ocr.ps1 复制到旧目录后再双击；或把旧 server\config.json
  复制到新解压的完整包里。

【更新同事脚本】
- 内网安装的脚本：油猴会按 @updateURL 自动检查更新；也可以打开
  Tampermonkey 管理面板 →“检查用户脚本更新”，或点脚本菜单
  “从服务器更新脚本（内网）”。
- 从公开 GitHub 安装的脚本：油猴会从 GitHub 更新；建议打开一次上面的
  内网地址并点“更新”，之后就会改走服务器更新。

【常见问题】
- 同事打不开脚本地址：确认在同一内网；确认 Windows 防火墙允许 1205；
  确认 server\config.json 的 allowed_clients 包含同事网段。
- 提示 token 无效：让同事重新打开脚本地址安装一次（服务端会自动注入最新 token）。
  如果脚本版本没变、油猴不触发更新，可以在油猴里手动重装，或先在服务器上升级版本。
- 换电脑/换 IP：重新运行 Start-OCR.bat；必要时修改 server\config.json 的 work_lan_ip。

【安全】
- 这个脚本地址包含 token，只发给内网同事，不要发到公网。
- 公开 GitHub 上的脚本不含 token，需要手动配置。
- 不要把 server\config.json 上传到任何公开位置。
