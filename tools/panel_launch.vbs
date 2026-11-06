' panel_launch.vbs
' -----------------------------------------------------------------------------
' Console-free launcher for the OCR control panel.
'
' OCR-Panel.bat runs this file through wscript.exe, which has no console window,
' so the user never sees a black PowerShell/cmd box - not even for a frame.
'
' The panel needs administrator rights (it stops a service started elevated and
' creates the "OCR ????" scheduled task), so this asks for elevation with
' ShellExecute "runas". If the user declines the UAC prompt nothing happens.
' -----------------------------------------------------------------------------
Option Explicit

Dim fso, root, panel, icon, shell, args, cmd

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("Shell.Application")

root = fso.GetParentFolderName(fso.GetParentFolderName(WScript.ScriptFullName))
panel = fso.BuildPath(root, "tools\panel.ps1")
icon = fso.BuildPath(root, "assets\ocr-panel.ico")

If Not fso.FileExists(panel) Then
    MsgBox "??????????" & vbCrLf & panel, 16, "OCR ????"
    WScript.Quit 1
End If

' Generate the .ico once if the portable package lost it (hidden, no console).
If Not fso.FileExists(icon) Then
    shell.ShellExecute "powershell.exe", _
        "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & _
        fso.BuildPath(root, "tools\make_icon.ps1") & """", root, "open", 0
End If

args = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & panel & """"
cmd = "powershell.exe " & args

On Error Resume Next
' 1 = SW_SHOWNORMAL for the elevated process; powershell itself stays hidden
' because of -WindowStyle Hidden and because it only hosts a WinForms window.
shell.ShellExecute "powershell.exe", args, root, "runas", 1
If Err.Number <> 0 Then
    ' 5 = access denied, typically the user dismissed the UAC prompt.
    If Err.Number = 5 Or Err.Number = -2147024891 Then
        ' Silent: the user chose not to elevate.
    Else
        MsgBox "?????????" & vbCrLf & Err.Description, 16, "OCR ????"
    End If
End If
On Error Goto 0
