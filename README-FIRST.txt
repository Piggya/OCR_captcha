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

【日常】
- 启动：双击 Start-OCR.bat（已启动时会重启服务，token 不变）
- 停止：双击 Stop-OCR.bat
- 查看日志：server.log、server.err.log
- 修改端口/白名单：server\config.json，改完重启服务

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
