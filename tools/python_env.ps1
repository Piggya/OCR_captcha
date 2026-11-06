# python_env.ps1
# -----------------------------------------------------------------------------
# Single place that decides WHICH Python runs the OCR service, and whether that
# Python can actually import the service's dependencies.
#
# History: start_service_bg.ps1 used to fall through to whatever "python" sat
# on PATH. On a fresh copy from the GitHub source zip there is no python\ and no
# .venv, so it picked an unrelated system Python that happened to have uvicorn
# but not ddddocr. The service died inside uvicorn with a 40-line traceback and
# the panel only showed "stopped", which told the user nothing.
#
# Now the order is: bundled python\ > .venv\ > system Python, and the chosen
# interpreter is probed BEFORE we launch anything. The probe result carries a
# human-readable reason so the panel can explain what to do.
#
# Dot-source this file; it deliberately has no side effects at load time.
# -----------------------------------------------------------------------------

# Modules the app imports at start-up. ddddocr pulls in onnxruntime + Pillow,
# so importing ddddocr is enough to prove the OCR stack is complete.
$script:OcrRequiredModules = @("fastapi", "uvicorn", "pydantic", "ddddocr")

function Get-PythonCandidates {
    <#
        Returns the interpreter candidates in priority order. Each entry has
        Path / Source so callers can explain the choice.
    #>
    param([Parameter(Mandatory = $true)][string]$Root)

    $list = New-Object System.Collections.ArrayList

    $bundled = Join-Path $Root "python\python.exe"
    if (Test-Path -LiteralPath $bundled) {
        [void]$list.Add([pscustomobject]@{ Path = $bundled; Source = "bundled" })
    }

    $venv = Join-Path $Root ".venv\Scripts\python.exe"
    if (Test-Path -LiteralPath $venv) {
        [void]$list.Add([pscustomobject]@{ Path = $venv; Source = "venv" })
    }

    $onPath = Get-Command python -ErrorAction SilentlyContinue
    if ($onPath -and $onPath.Source) {
        # Skip a duplicate of something we already listed.
        $already = $false
        foreach ($c in $list) {
            if ($c.Path -ieq $onPath.Source) { $already = $true }
        }
        if (-not $already) {
            [void]$list.Add([pscustomobject]@{ Path = $onPath.Source; Source = "system" })
        }
    }

    return $list
}

function Test-PythonDependencies {
    <#
        Runs a one-liner that tries to import every required module and prints
        the first missing one. Returns an object:
            Ok       - $true when every module imports
            Missing  - the first module that failed (empty when Ok)
            Detail   - short explanation suitable for a dialog
    #>
    param([Parameter(Mandatory = $true)][string]$PythonPath)

    $probe = @'
import importlib, sys
missing = []
for name in ("fastapi", "uvicorn", "pydantic", "ddddocr"):
    try:
        importlib.import_module(name)
    except Exception as exc:
        missing.append(name + " (" + type(exc).__name__ + ")")
if missing:
    print("MISSING:" + ",".join(missing))
    sys.exit(1)
print("OK:" + sys.version.split()[0])
'@

    $tmp = Join-Path $env:TEMP ("ocr_probe_" + [guid]::NewGuid().ToString("N") + ".py")
    try {
        [IO.File]::WriteAllText($tmp, $probe, (New-Object Text.UTF8Encoding($false)))
        $out = & $PythonPath $tmp 2>&1 | Out-String
        $code = $LASTEXITCODE
    } catch {
        return [pscustomobject]@{
            Ok      = $false
            Missing = "interpreter"
            Detail  = ("Cannot run Python at " + $PythonPath + ": " + $_.Exception.Message)
        }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }

    $text = ($out -as [string]).Trim()
    if ($code -eq 0 -and $text -like "OK:*") {
        return [pscustomobject]@{
            Ok      = $true
            Missing = ""
            Detail  = ("Python " + $text.Substring(3).Trim())
        }
    }

    $missingList = ""
    foreach ($line in $text -split "`r?`n") {
        if ($line -like "MISSING:*") { $missingList = $line.Substring(8).Trim() }
    }
    if (-not $missingList) { $missingList = "unknown (probe output: " + $text + ")" }
    return [pscustomobject]@{
        Ok      = $false
        Missing = $missingList
        Detail  = ("Missing modules: " + $missingList)
    }
}

function Resolve-OcrPython {
    <#
        Picks the first candidate whose dependencies probe clean.

        Returns an object:
            Path      - interpreter to use (empty when none works)
            Source    - bundled / venv / system
            Ok        - $true when a working interpreter was found
            Reason    - why it failed, phrased for the end user
            Attempts  - every candidate with its probe result (for logs)
    #>
    param([Parameter(Mandatory = $true)][string]$Root)

    $candidates = Get-PythonCandidates -Root $Root
    if (-not $candidates -or $candidates.Count -eq 0) {
        return [pscustomobject]@{
            Path     = ""
            Source   = ""
            Ok       = $false
            Reason   = "No Python found. Install Python 3.10+ and run: pip install -r requirements.txt"
            Attempts = @()
        }
    }

    $attempts = New-Object System.Collections.ArrayList
    foreach ($cand in $candidates) {
        $probe = Test-PythonDependencies -PythonPath $cand.Path
        [void]$attempts.Add([pscustomobject]@{
            Path   = $cand.Path
            Source = $cand.Source
            Ok     = $probe.Ok
            Detail = $probe.Detail
        })
        if ($probe.Ok) {
            return [pscustomobject]@{
                Path     = $cand.Path
                Source   = $cand.Source
                Ok       = $true
                Reason   = ""
                Attempts = $attempts
            }
        }
    }

    $tried = ($attempts | ForEach-Object { "  - [" + $_.Source + "] " + $_.Path + " -> " + $_.Detail }) -join "`r`n"
    return [pscustomobject]@{
        Path     = ""
        Source   = ""
        Ok       = $false
        Reason   = ("No usable Python found. Dependencies missing.`r`n`r`n" + $tried +
                    "`r`n`r`nFix (pick one):`r`n" +
                    "  1) Run launchers\Start-OCR.bat once - it installs the dependencies.`r`n" +
                    "  2) Or run manually in this folder:`r`n" +
                    "     python -m pip install -r requirements.txt`r`n`r`n" +
                    "If this copy came from the GitHub source zip, you can also use the`r`n" +
                    "OCR-portable.zip release asset instead - it already contains python\.")
        Attempts = $attempts
    }
}
