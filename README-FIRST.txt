土著内网验证码识别 - 便携版（Windows）

【从 GitHub 下载的包，解压后第一件事】
先双击根目录的 OCR-Panel.bat（不是带图标的快捷方式）。

原因：OCR 控制面板.lnk 里记录的是“这台电脑上的安装路径”，
所以它不会被打进下载包；从旧电脑复制过来的旧快捷方式在新电脑上
会提示“无法找到脚本文件 ...panel_launch.vbs”。
双击一次 OCR-Panel.bat 之后，快捷方式会自动按新路径重建，
以后就可以照常双击带 Logo 的快捷方式了。

【这是什么】
一个在局域网运行的验证码识别服务。在这台机器上双击一次即可启动；
局域网设备在浏览器安装油猴脚本后，业务系统等网站的验证码会自动识别并填入。
脚本地址里已经带好服务器地址和 token，局域网设备不需要手动配置。

【用哪个文件】（看不看文档都用这个判断）
- 日常启动/停止/更新/看连接信息：双击 OCR 控制面板.lnk（带 Logo 图标的快捷方式，推荐）
  · 这一步会弹出“用户账户控制”，点“是”即可（面板需要管理员权限）
  · 面板显示服务状态：绿=运行中、黄=启动中、红=已停止
  · 安装地址 / 服务器地址 / token 直接显示在面板上，每行有“复制”按钮
  · 启动时不弹黑色命令行窗口，只弹一次“用户账户控制”
  · 快捷方式丢了也没关系：双击 OCR-Panel.bat 一样能开面板，
    打开面板后会自动补回快捷方式；也可以在管理员 PowerShell 里运行
    tools\make_shortcut.ps1 -Desktop，顺便在桌面也放一份
- 只想先跑起来：双击 launchers\Start-OCR.bat
- 停止服务：面板上的“停止服务”，或双击 launchers\Stop-OCR.bat
- 更新服务端：面板上的“更新服务端”，或双击 launchers\Update-OCR.bat
- 显示/复制地址和 token：面板上直接显示（每行有“复制”按钮，还有“一键复制全部”），或双击 launchers\Show-OCR-Info.bat
- tools\start_server.ps1 / launchers\start_server.bat 只是开发者前台调试用的，日常不要点。

【第一次使用】
1. 把 OCR-portable.zip 完整解压到一个本地文件夹
   （例如 D:\OCR-portable）。不要直接在压缩包里运行，
   也不要放在网络共享路径下。
2. 双击 OCR 控制面板.lnk（或 launchers\Start-OCR.bat）。
   找不到快捷方式时双击 OCR-Panel.bat，效果一样。
3. Windows 弹出“用户账户控制”时点“是”。
   （如果出现 SmartScreen，点“更多信息” → “仍要运行”。）
4. 等待窗口显示 “Setup Complete!”。首次启动约需 10-30 秒。
5. 窗口里（或面板上）会显示一行 Userscript 地址，并且已经复制到剪贴板：
      http://<本机局域网IP>:1205/userscript.user.js
    把这行地址发给局域网内的其他设备。
6. 以后想查看/复制完整的“服务器地址 + token + 安装地址”：
   面板的“连接信息”区直接显示完整内容，点对应行的“复制”，
   或点“一键复制全部（含说明）”复制成一段话；也可双击 launchers\Show-OCR-Info.bat。

【局域网设备使用】
1. 浏览器安装 Tampermonkey（油猴）扩展。
2. 打开上面那个地址，点“安装”。
   脚本已经自动带好服务器地址和 token，不需要手动填写。
3. 打开业务系统等网站，验证码会自动识别并填入。

【局域网其他电脑】
其他电脑不需要下载 OCR-portable.zip，也不需要装 Python。只要：
1. 能访问这台服务器的 1205 端口（同一局域网/防火墙放行）
2. 浏览器安装 Tampermonkey
3. 打开服务器窗口里给出的脚本地址并安装

【查看/分享连接信息】
- 双击 launchers\Show-OCR-Info.bat：
  显示服务器地址、API token、安装地址，
  并把完整信息复制到剪贴板，直接粘贴到局域网群即可。
- 推荐把“安装地址”发给局域网设备，脚本会自动带好地址/token；
  只有手动安装公开版时，才需要把服务器地址和 token 一起发给对方。
- token 等同于访问密码，只发给局域网内的设备，不要发到公网。

【日常】
- 启动：双击 OCR 控制面板.lnk → “启动服务”（或直接双击 launchers\Start-OCR.bat）
- 停止：面板上点“停止服务”（或双击 launchers\Stop-OCR.bat）
- 查看/分享地址和 token：面板“连接信息”区直接显示，点“复制”或“一键复制全部”（或双击 launchers\Show-OCR-Info.bat）
- 查看日志：面板下方的日志区；文件是 server.log、server.err.log
- 修改端口/白名单：server\config.json，改完在面板上点“重启服务”
- 开机自启：面板上勾选“开机自启”（默认关闭）。开启后登录 Windows 会自动
  在后台启动服务，不会弹出窗口；要取消就取消勾选。
- 面板可以随手关掉，关面板不会停止服务；需要停服务请点“停止服务”。

【更新服务端】
- 能访问 GitHub：双击 OCR 控制面板.lnk → “更新服务端”，UAC 点“是”
  （或双击 launchers\Update-OCR.bat）。
  它会下载最新代码，保留 server\config.json 和 python\，
  更新前备份到 backup-时间戳\，更新后自动重启。
- 不能访问 GitHub：在能上网的电脑下载
    https://github.com/Piggya/OCR_captcha/archive/refs/heads/main.zip
  拷到本机，管理员 PowerShell 运行：
    powershell -ExecutionPolicy Bypass -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"
- 更新不会改 token。如果手动改了 token，局域网设备需要重新打开脚本地址安装一次。
- 0.9.1 及更早的包没有 launchers\Update-OCR.bat：把新版里的 launchers\Update-OCR.bat 和
  tools\update_ocr.ps1 复制到旧目录后再双击；或把旧 server\config.json
  复制到新解压的完整包里。

【更新局域网设备脚本】
- 局域网安装的脚本：油猴会按 @updateURL 自动检查更新；也可以打开
  Tampermonkey 管理面板 →“检查用户脚本更新”，或点脚本菜单
  “从 OCR 服务器更新脚本…”。
- 从公开 GitHub 安装的脚本：油猴会从 GitHub 更新；建议打开一次上面的
  局域网地址并点“更新”，之后就会改走服务器更新。
- 油猴菜单已精简为：识别并填码、刷新后识别、切换本站识别（开/关）、
  OCR 服务器设置…、高级功能…、从 OCR 服务器更新脚本…。
  大小写/站点规则/重置在“高级功能…”里。
- “切换本站识别（开/关）”只影响当前网站，关闭后该站不再自动识别；
  重新开启会立即识别一次，状态按域名记住。
- “从 OCR 服务器更新脚本…”只更新油猴脚本（打开服务器的安装地址），
  不会更新服务端程序；更新服务端请在面板上点“更新服务端”。

【常见问题】
- 局域网设备打不开脚本地址：确认在同一局域网；确认 Windows 防火墙允许 1205；
  确认 server\config.json 的 allowed_clients 包含这些设备的网段。
- 提示 token 无效：让局域网设备重新打开脚本地址安装一次（服务端会自动注入最新 token）。
  如果脚本版本没变、油猴不触发更新，可以在油猴里手动重装，或先在服务器上升级版本。
- 换电脑/换 IP：重新运行 OCR 控制面板.lnk 点“首次配置/修复”；必要时修改
  server\config.json 的 work_lan_ip。
- 换了安装目录后快捷方式打不开：快捷方式里存的是绝对路径。双击 OCR-Panel.bat
  打开一次面板即可自动重建；或运行 tools\make_shortcut.ps1。

【安全】
- 这个脚本地址包含 token，只发给局域网内的设备，不要发到公网。
- 公开 GitHub 上的脚本不含 token，需要手动配置。
- 不要把 server\config.json 上传到任何公开位置。
