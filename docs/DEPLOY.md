# 部署迁移指南：迁移 OCR 服务到新设备

> 将整套验证码识别服务从一台电脑迁移到局域网内的另一台电脑。
> 新电脑**不需要安装 Python**——使用便携版 Python Embeddable。

---

## 快速流程

```
① 旧机器运行 tools\build_portable.ps1          → 生成 OCR-portable.zip
② OCR-portable.zip 传到新机器                   → U盘/共享文件夹
③ 新机器解压到 E:\OCR                           → 保持目录一致
④ 管理员 PowerShell 执行：                        → 一行搞定全部
   cd E:\OCR
   powershell -File tools\setup_new_server.ps1
⑤ 同事安装脚本地址 http://<新机器IP>:1205/userscript.user.js
   → 在油猴菜单「设置服务器地址与 token…」填入 URL 和 token
```

`setup_new_server.ps1` 自动完成：检测 IP → 生成 token → 开防火墙 → 设置电源 → 启动服务（后台运行，关窗口不影响），并在结尾打印同事所需的 Server URL 和 token。

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

> 路径不要有中文或空格。

**右键** PowerShell → **以管理员身份运行**，然后：

```powershell
cd D:\OCR
powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup_new_server.ps1
```

脚本会自动完成：
1. 验证便携 Python 和依赖
2. 探测本机 LAN IP（会提示确认，按 Enter 即可）
3. 生成 `server\config.json`（含真实随机 token）
4. 检查 `userscript\local-captcha-autofill.user.js`（供 `/userscript.user.js` 分发）
5. 开放防火墙 1205 端口
6. 设置电源（睡眠=从不，防止息屏后服务挂起）
7. 启动 uvicorn 服务
8. 健康检查

看到 `Setup Complete!` 和 `Health check: OK` 表示成功，结尾会打印同事所需的 Server URL 与 token。之后让同事打开脚本地址并填一次即可。

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
3. 打开 Tampermonkey 菜单 →「设置服务器地址与 token…」
   - **Server URL**：`http://<服务器IP>:1205`
   - **token**：`setup_new_server.ps1` 结尾打印的值（或 `server\config.json` 的 `api_token`）
4. 重配/查看：菜单「设置服务器地址与 token…」/「查看当前服务器」

> 公开脚本**不内嵌 token**，每位同事首次使用需填一次（只存浏览器本地）。
> 更新方式：能上外网时脚本按 `@updateURL` 自动更新；隔离内网用菜单「从服务器更新脚本（内网）」。

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
脚本本身不含 token（存在浏览器本地）。让同事在油猴菜单「设置服务器地址与 token…」重新填写服务端 token。
若轮换了服务端 token，重启服务并通知所有同事更新。

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

## 日常运维

| 操作 | 命令 |
|------|------|
| 首次部署（一行搞定） | `powershell -File tools\setup_new_server.ps1`（管理员） |
| 重启服务 | `powershell -File tools\restart_server.ps1` |
| 停止服务 | `Get-NetTCPConnection -LocalPort 1205 -State Listen \| ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }` |
| 检查健康 | 浏览器打开 `http://127.0.0.1:1205/health` |
| 查看日志 | `Get-Content server.err.log -Tail 20` |
| IP 变了 | 重跑 `tools\setup_new_server.ps1`，重发 `local-captcha-autofill.user.js` |

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
