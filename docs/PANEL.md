# 控制面板与启动方式

> 状态：**已实现（v0.10.0）**。实现细节以 `tools/panel.ps1` 为准，本文说明设计决策与使用方式。

## 0. 结论

| 问题 | 决策 |
|------|------|
| 用哪种面板 | PowerShell + WinForms 托盘式窗口（零额外依赖，便携版 embeddable Python 不带 tkinter） |
| 关闭面板是否停服务 | **不停**。停止服务用面板上的「停止服务」按钮 |
| 开机自启 | 面板上的复选框，**默认关闭**，勾选/取消即可 |
| 开发脚本改名 | **不改名**。日常都走面板，`start_server.*` 保留给开发者前台调试 |

## 1. 入口

双击根目录的 **`OCR 控制面板.lnk`**（带 Logo 图标）。找不到时双击 `OCR-Panel.bat`，效果相同。

**为什么用 `.lnk`**：Windows 里双击 `.bat` 只能显示 cmd/脚本的默认图标，批处理
无法自定义图标。快捷方式有自己的 `IconLocation`，所以日常入口做成快捷方式。

**快捷方式指向**：`C:\Windows\System32\wscript.exe //nologo "<安装目录>\tools\panel_launch.vbs"`，
工作目录为安装根目录，图标 `assets\ocr-panel.ico,0`。它**不经过** `cmd.exe`：

- 不会闪 cmd 窗口（`wscript.exe` 本身没有控制台）
- 保留原有的静默提权（VBS 里 `ShellExecute "runas"`），只弹一次 UAC
- 不受中文路径下 `cmd.exe` 解析引号的影响

`.bat` 启动链仍在，作为后备：`OCR-Panel.bat` → `launchers\OCR-Panel.bat` →
`wscript.exe tools\panel_launch.vbs`。两套入口最终都进入同一个面板，重复启动时
只保留一个实例。

**快捷方式里是绝对路径**，所以：

- 不打进便携包，而是在首次安装（`setup_new_server.ps1`）、更新后（`update_ocr.ps1`）、
  每次打开面板（`panel.ps1` 的 `Add_Shown`）时用 `tools\make_shortcut.ps1` 重建
- 手动重建 / 顺便在桌面也放一份：
  `powershell -ExecutionPolicy Bypass -File tools\make_shortcut.ps1 -Desktop`
  （`-Quiet` 静默，`-TargetRoot <目录>` 指定安装根目录）

> 想排查启动问题：在文件夹里打开 PowerShell，运行
> `$env:OCR_PANEL_DEBUG='1'; .\OCR-Panel.bat`，可以看到明文报错。

图标：`assets/ocr-panel.ico`（由 `assets/logo.png` 生成，16/24/32/48/64/128/256 多尺寸），
`tools/make_icon.ps1` 生成；缺失时启动会自动重建。窗口图标还会随状态变色
（运行中=绿，已停止=灰底红点），任务栏里也能一眼看出服务是否在跑。

> **ICO 格式坑**：每一个尺寸都必须写成真正的 **32bpp DIB**（含 256px）。
> GDI+（`System.Drawing.Icon` / Explorer / WinForms 都用它）不解码 PNG 压缩条目；
> 早期实现把 PNG 字节配上 DIB 头写进目录，结果 48px 以上全部渲染成噪点。

## 2. 面板功能

**状态区**（每 3 秒自动刷新，绿/黄/红三色圆点 + 大字状态）

| 状态 | 含义 |
|------|------|
| 🟢 运行中 | 端口在监听，且 `/health` 返回 200，局域网设备可正常识别 |
| 🟡 启动中 | 端口已监听但 `/health` 未响应（模型还在加载），稍等几秒 |
| 🔴 已停止 | 端口没有监听，局域网设备无法识别 |

旁边显示：版本号、开机自启是否开启、端口、进程 PID。

**连接信息区**（完整显示，不用点任何按钮去看）

| 行 | 内容 | 复制按钮 |
|----|------|----------|
| 安装地址 | `http://<IP>:<port>/userscript.user.js` | 「复制」 |
| 服务器地址 | `http://<IP>:<port>` | 「复制」 |
| API token | `server/config.json` 里的真实 token（完整显示） | 「复制」 |

底部「一键复制全部（含说明）」会把“地址 + token + 安装地址 + 使用步骤”整理成一段话放进剪贴板，
直接粘到局域网群即可（与 `launchers\Show-OCR-Info.bat` 的内容一致）。

**按钮**

| 按钮 | 行为 |
|------|------|
| 启动服务 | 调 `tools/start_service_bg.ps1`，服务已在跑则直接返回 |
| 停止服务 | 按端口找 PID（`Get-NetTCPConnection`）后 `Stop-Process` |
| 重启服务 | 停止 → 等 2 秒 → 启动 |
| 首次配置/修复 | 打开 `launchers\Start-OCR.bat`（建配置、开防火墙，会弹 UAC） |
| 更新服务端 | 另开窗口运行 `tools/update_ocr.ps1`，保留 `server/config.json` 与 `python/` |
| 打开安装地址 | 浏览器打开 `http://<IP>:<port>/userscript.user.js` |
| 打开日志文件 | 记事本打开 `server.err.log` |
| 刷新状态 | 立即刷新状态区与日志区 |

**开关**

- 开机自启（默认关闭）：`schtasks` 建/删名为 `OCR 服务自启` 的登录时任务，动作是隐藏窗口运行 `tools/start_service_bg.ps1`

**日志区**：`server.err.log` 末尾 120 行。

## 3. 新增的服务端脚本

`tools/start_service_bg.ps1`

- 只启动服务，**不改任何配置**（不动防火墙、不改电源策略），所以不需要管理员
- 依次找 `python\python.exe`（便携版）、`.venv\Scripts\python.exe`（源码版）、PATH 里的 `python`
- 端口/绑定地址从 `server/config.json` 读取，不硬编码
- 已经在该端口监听就直接退出 0（不会误重启）
- `-Force` 强制重启
- 输出重定向到 `server.log` / `server.err.log`

`tools/panel_launch.vbs` / `tools/panel_launch.ps1`

- VBS 是首选入口：无控制台 + 自提权（快捷方式和 `.bat` 都走它）
- PS1 是后备入口（VBS 缺失时 `.bat` 会用它），会把异常显示成消息框而不是静默失败
- `tools/make_icon.ps1` 由 `assets/logo.png` 生成 `assets/ocr-panel.ico`（全 DIB，7 尺寸）
- `tools/make_shortcut.ps1` 生成根目录 `OCR 控制面板.lnk`（`-Desktop` / `-Quiet` / `-TargetRoot`）

## 4. 现有脚本的职责

| 文件 | 适用场景 | 需要管理员 | 说明 |
|------|----------|------------|------|
| `OCR 控制面板.lnk` | **日常唯一入口（推荐）** | 是（自提权） | 带 Logo 图标的快捷方式，自动生成 |
| `OCR-Panel.bat` | 快捷方式不在时的后备入口 | 是（自提权） | 转发到 `launchers\OCR-Panel.bat`，图形面板 |
| `launchers\Start-OCR.bat` | 首次配置 / 修复 | 是 | 建配置、开防火墙、启动服务 |
| `launchers\Stop-OCR.bat` | 命令行停止 | 是 | 面板之外的后备手段 |
| `launchers\Update-OCR.bat` | 命令行更新 | 是 | 面板之外的后备手段 |
| `launchers\Show-OCR-Info.bat` | 显示/复制连接信息 | 否 | 面板之外的后备手段 |
| `tools\start_server.ps1` / `.bat` | **源码开发调试** | 否 | 前台运行 uvicorn，`Ctrl+C` 停止，日常不要用 |
| `tools/start_service_bg.ps1` | 被面板和自启任务调用 | 否 | 只启动服务 |

## 5. 实现要点与坑（后续维护必读）

1. 面板是 PowerShell 进程，服务是独立 python 进程；「停止服务」按端口找 PID，不保存 PID 文件。
2. `schtasks.exe` 失败时会往 stderr 写信息，在 `$ErrorActionPreference = "Stop"` 下会中断脚本 → 统一走 `Invoke-Schtasks` 包装函数，用退出码判断。
3. PowerShell 字符串里不要用中文全角引号 `“”`，会被解析器当成字符串结束（已改为 `「」`）。
4. `.ps1` 必须是 UTF-8 **BOM**；`OCR-Panel.bat` 用 ASCII + CRLF。
5. 面板需要管理员权限（停以管理员身份启动的服务进程、写计划任务）；提权由
   `tools/panel_launch.vbs` 的 `ShellExecute "runas"` 完成，`.bat` 里不再调用 PowerShell 提权，
   这样整个启动过程没有控制台窗口。
6. 面板不更新自己：更新完成后提示重启面板。
7. 端口、路径、地址全部从 `server/config.json` 与 `server/app.py` 读取，面板里不硬编码。
8. 自启任务启动的是**服务**，不是面板 —— 因为“关面板不停服务”，两者解耦。
9. **只读 `TextBox` 会忽略 `PasswordChar`/`UseSystemPasswordChar`**（实测始终显示字符），
   所以不要靠这两个属性做遮挡；连接信息一律完整显示。`Set-Clipboard` 在部分宿主里不可用，
   `Copy-Text` 已回退到 `[System.Windows.Forms.Clipboard]::SetText`。
10. **样式**：所有自绘控件（圆角卡片 / 药丸按钮 / 输入框底色 / 配色）在 `tools/ui_kit.ps1`，
    `panel.ps1` 用 `. (Join-Path $PSScriptRoot "ui_kit.ps1")` 点源引入。改配色只改 `$script:ui` 一处。
    - `Paint` 处理器里只读 `$s.Tag` 和 `$script:ui`，**不要用 `.GetNewClosure()`**：
      闭包会把 `$script:ui` 遮蔽成空值，卡片会变成红叉或空白。
    - 事件处理块（`Add_Click` / `Add_Paint`）与脚本共享作用域，`New-StyleButton` 的参数
      `$Text` / `$Variant` 会漏进这个作用域，所以**不要在里面读调用方的脚本级变量**（例如不要写
      `$ui =` 以外的同名变量）；需要外部值时在脚本级用 `*Ref` 变量或 `$script:` 前缀。
11. **状态刷新**：`Update-Status` 是函数，有独立作用域，看不到脚本级的 `$lbl*` / `$txt*`。
    需要刷新的控件统一挂在 `$form.Tag` 上（`StateSub` / `StateDetail` / `Status` / `Info` /
    `Install` / `Server` / `Token` / `Auto`），新增控件记得同步加进 `$form.Tag`。
12. `Add_Shown` / `Timer.Tick` 里的异常会被 WinForms 静默吞掉并中断后续语句，
    所以两处都包了 `try/catch`，出错写进面板日志。

## 6. 自测

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\panel.ps1 -SelfTest
```

输出 `root / port / lan_ip / version / listener_pid / autostart_task / python / *_script` 布尔与路径，用于无人值守检查，不弹窗口。

## 7. 后续可选

- 面板内生成连接信息二维码，方便局域网设备扫码安装
- 面板显示请求量/成功率统计（需服务端加 `/stats`）
- 托盘最小化 + 开机自动打开面板
