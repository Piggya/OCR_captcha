# 部署迁移指南：迁移 OCR 服务到新设备

> 将整套验证码识别服务从一台电脑迁移到局域网内的另一台电脑。
> 新电脑**不需要安装 Python**——使用便携版 Python Embeddable。

---

## 快速流程

```
① 旧机器运行 tools\build_portable.ps1          → 生成 OCR-portable.zip
② OCR-portable.zip 传到新机器                   → U盘/共享文件夹/Release 下载
③ 新机器解压到 E:\OCR                           → 本地目录，不要在网络共享里运行
④ 双击 Start-OCR.bat                            → UAC 点“是”，自动完成全部配置
   （等价命令：powershell -File tools\setup_new_server.ps1 -NonInteractive）
⑤ 把窗口显示（已复制到剪贴板）的脚本地址发给同事
   http://<新机器IP>:1205/userscript.user.js
   → 同事打开安装即可，无需填 URL/token
```

`Start-OCR.bat` 会自提权并调用 `setup_new_server.ps1 -NonInteractive`：接受探测到的 IP → 生成 token → 开防火墙 → 设置电源 → 后台启动服务，并在结尾打印脚本地址。token 只在第一次运行时生成，之后重启不会变化。

> 重启电脑后服务停止，需设置开机自启 → 见末尾"开机自启"章节。

---

## 前提条件

- 新旧机器：Windows 10/11 x64
- 新旧机器在同一局域网（或通过 ZeroTier 互通）
- 新机器有管理员权限

---

## 阶段一：旧机器上构建便携包

在旧机器（当前服务端）上运行：

```powershell
cd D:\OCR
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_portable.ps1
```

构建脚本会自动完成：
1. 下载 Python 嵌入式版本
2. 安装所有依赖（ddddocr、onnxruntime、fastapi 等）
3. 清理缓存和测试文件
4. 打包为 `OCR-portable.zip`（约 350-470 MB）

构建完成后，在项目根目录生成 `OCR-portable.zip`。

> 如果下载失败，手动访问 https://www.python.org/downloads/windows/ 下载对应版本的 "Windows embeddable package (64-bit)"，放到 `%TEMP%` 目录后重跑脚本。

---

## 阶段二：传输到新机器

用任意方式把 `OCR-portable.zip` 拷贝到新机器：
- U盘
- 共享文件夹
- 局域网传输工具（LocalSend 等）

---

## 阶段三：新机器上部署

将 `OCR-portable.zip` 解压到目标目录（建议和旧机器目录一致，例如 `D:\OCR`）。

> 路径不要有中文或空格；不要直接在压缩包里运行，也不要放在 UNC 网络路径下。

双击 **`Start-OCR.bat`**（自动请求管理员权限）。如果 SmartScreen 拦截，点“更多信息” → “仍要运行”。

也可以手动执行：

```powershell
cd D:\OCR
powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup_new_server.ps1
# 想跳过 IP 确认（默认接受探测结果）：加 -NonInteractive
```

脚本会自动完成：
1. 验证便携 Python 和依赖
2. 探测本机 LAN IP（`-NonInteractive` 时自动接受；否则按 Enter 确认）
3. 生成 `server\config.json`（首次运行生成真实随机 token，之后保留）
4. 检查 `userscript\local-captcha-autofill.user.js`（供 `/userscript.user.js` 分发）
5. 开放防火墙 1205 端口
6. 设置电源（睡眠=从不，防止息屏后服务挂起）
7. 启动 uvicorn 服务
8. 健康检查

看到 `Setup Complete!` 和 `Health check: OK` 表示成功。结尾会打印脚本地址并复制到剪贴板，直接发给同事即可；服务端会在脚本里注入 URL 和 token。

### 如果没有管理员权限

脚本仍会配置 config 和启动服务，但跳过防火墙和电源设置。手动执行：

```powershell
netsh advfirewall firewall add rule name="OCR Service (1205)" dir=in action=allow protocol=TCP localport=1205
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
```

---

## 阶段四：安装油猴脚本

### 本机 + 同事

1. 浏览器安装 Tampermonkey 扩展
2. 打开 `http://<服务器IP>:1205/userscript.user.js`，Tampermonkey 会提示安装
   - 隔离内网也可直接把 `userscript\local-captcha-autofill.user.js` 拖入 Tampermonkey
3. 安装完成即可使用：服务端已经把服务器地址和 token 注入脚本，**不需要填**
   - 注入值优先于浏览器本地存储；服务器换 IP 或轮换 token 后，升一次脚本版本即可自动同步
4. 只有手动安装公开 GitHub 脚本时，才需要菜单「设置服务器地址与 token…」
5. 重配/查看：菜单「设置服务器地址与 token…」/「查看当前服务器」

> 内网脚本地址包含 token，只对 `allowed_clients` 中的 IP 返回，不要发到公网。
> 更新方式：能上外网时脚本按 `@updateURL` 自动更新；隔离内网用菜单「从服务器更新脚本（内网）」。

### 局域网其他电脑（不装服务端）

其他电脑**不需要**解压 `OCR-portable.zip`，也**不需要** Python。只需：

1. 能访问服务器的 1205 端口（同一内网；防火墙已由服务器端放行）
2. 浏览器安装 Tampermonkey
3. 打开 `http://<服务器IP>:1205/userscript.user.js` 并安装

安装后 Tampermonkey 的更新地址会指向该服务器；服务器升级 `@version` 后即可检查更新。
如果同事之前从公开 GitHub 安装，建议重开一次内网地址并点“更新”，切换到服务器托管更新。

---

## 阶段五：验证

1. 打开需要识别验证码的网页（如公司 OA 登录页）
2. 右下角应弹出"正在本地识别验证码..."
3. 1-2 秒后弹出"验证码已填入: xxxx"
4. 验证码输入框自动填入

服务端验证：
```powershell
Invoke-WebRequest http://127.0.0.1:1205/health -UseBasicParsing
# 应返回 {"ok":true,"engine":"ddddocr"}
```

---

## 阶段六：旧机器处理

### 停用旧服务（推荐）

```powershell
Get-NetTCPConnection -LocalPort 1205 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

### 保留备用

保持旧服务运行，同事脚本已指向新机器。如果新机器故障，可临时切回旧机器。

---

## 跨网络部署（ZeroTier）

如果新设备和同事不在同一局域网（如不同网段、分公司、家里），需要用内网穿透工具。

**服务端操作：**
1. 安装 ZeroTier，加入网络
2. ZeroTier 后台批准设备
3. 防火墙已由 setup_new_server.ps1 自动配置

**客户端操作：**
1. 安装 ZeroTier，加入同一网络
2. 油猴脚本 `serverUrl` 改为 ZeroTier IP（如 `172.30.0.171:1205`）
3. `@connect` 加上 ZeroTier IP

> `allowed_clients` 已默认包含 `172.16.0.0/12`，覆盖 ZeroTier 网段。

---

## 故障排查

### OCR service returned 401
检查 token 是否匹配：
```powershell
Get-Content D:\OCR\server\config.json | ConvertFrom-Json | Select-Object -ExpandProperty api_token
```
从内网地址安装的脚本带服务端注入的 token；公开 GitHub 脚本不含 token（存在浏览器本地）。
若轮换了服务端 token：重启服务后，升一次脚本 `@version` 让内网脚本自动更新；或让同事重新打开 `http://<服务器IP>:1205/userscript.user.js` 安装一次。
如果同事是手动安装的公开脚本，则在菜单「设置服务器地址与 token…」里改成新 token。

### OCR 请求超时
```powershell
Test-NetConnection <服务器IP> -Port 1205
```
返回 `False` 说明防火墙问题，在服务器上以管理员运行：
```powershell
New-NetFirewallRule -DisplayName "OCR Service (1205)" -Direction Inbound -Protocol TCP -LocalPort 1205 -Action Allow
```

### 息屏后服务不可用
```powershell
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
```

### 服务没有在运行
```powershell
Get-NetTCPConnection -LocalPort 1205 -State Listen
# 如果没有，手动启动
cd D:\OCR
Start-Process -FilePath ".\python\python.exe" -ArgumentList '-m','uvicorn','server.app:app','--host','0.0.0.0','--port','1205','--no-proxy-headers' -WorkingDirectory "D:\OCR" -WindowStyle Hidden
```

### 服务启动失败
```powershell
Get-Content D:\OCR\server.err.log -Tail 20
```

---

## 更新服务端

**能访问 GitHub**：双击 `Update-OCR.bat`（自动提权）。

更新流程：下载最新源码 → 停止 1205 服务 → 备份 `server/config.json`、`server/`、`userscript/` 到 `backup-<时间戳>/` → 替换代码（**保留 `server/config.json` 和 `python/`**）→ 依赖有变化时 `pip install` → 调用 `setup_new_server.ps1 -NonInteractive` 重启并健康检查。

**内网无法访问 GitHub**：在能上网的机器下载
`https://github.com/Piggya/OCR_captcha/archive/refs/heads/main.zip`，
拷到服务器后以管理员运行：

```powershell
cd D:\OCR
powershell -NoProfile -ExecutionPolicy Bypass -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"
```

可选参数：`-Force`（同版本也重装）、`-SkipDependencies`（跳过 pip）、`-InstallRoot`（指定安装目录）。

> 从 0.9.1 及更早版本升级时，旧目录里还没有 `Update-OCR.bat`：把新版中的 `Update-OCR.bat` 和 `tools\update_ocr.ps1` 复制到旧目录后再双击；或解压完整新包，把旧 `server\config.json` 复制过去。

> 不要删 `server/config.json`，否则会生成新 token，所有同事都会 401。
> 更新后同事脚本按 `@version` 自动更新；轮换 token 时必须升一次 `@version`，或让同事重开内网脚本地址安装。

---

## 日常运维

| 操作 | 命令 |
|------|------|
| 首次部署（一键） | 双击 `Start-OCR.bat` |
| 更新服务端（一键，保留 config/python） | 双击 `Update-OCR.bat` |
| 离线更新 | `powershell -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"` |
| 重启服务 | 双击 `Start-OCR.bat` 或 `powershell -File tools\restart_server.ps1` |
| 停止服务 | 双击 `Stop-OCR.bat` |
| 检查健康 | 浏览器打开 `http://127.0.0.1:1205/health` |
| 查看日志 | `Get-Content server.err.log -Tail 20` |
| IP 变了 | 重跑 `Start-OCR.bat`，把新脚本地址发给同事（旧地址会失效） |

### 开机自启

重启电脑后服务不会自动运行，需要手动启动。两种方式：

**方式一：放到启动文件夹（推荐）**

新建 `E:\OCR\start_service_bg.ps1`：

```powershell
Start-Process -FilePath "E:\OCR\python\python.exe" `
    -ArgumentList @('-m', 'uvicorn', 'server.app:app', '--host', '0.0.0.0', '--port', '1205', '--no-proxy-headers') `
    -WorkingDirectory "E:\OCR" `
    -WindowStyle Hidden
```

把这个脚本的快捷方式扔到开机启动文件夹：
1. 右键 `start_service_bg.ps1` → 创建快捷方式
2. 按 `Win+R` → 输入 `shell:startup` → 回车
3. 把快捷方式拖进去

以后开机自动在后台启动 OCR 服务，无窗口无感。

**方式二：注册为 Windows 服务（需下载 nssm）**

```powershell
# 下载 nssm，放到 E:\OCR\tools\
# 管理员运行：
E:\OCR\tools\nssm.exe install OCRService "E:\OCR\python\python.exe" `
    "-m uvicorn server.app:app --host 0.0.0.0 --port 1205 --no-proxy-headers"
E:\OCR\tools\nssm.exe set OCRService AppDirectory "E:\OCR"
E:\OCR\tools\nssm.exe start OCRService
```

之后服务会在"服务"管理器中显示为 `OCRService`，可设为自动启动、崩溃自动重启。
