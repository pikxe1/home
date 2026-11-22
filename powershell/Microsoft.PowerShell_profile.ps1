Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

Invoke-Expression -Command clear

# Linux: ls -la
function ll {
    gci -Force @args
}

function codex {
    codex-x86_64-pc-windows-msvc.exe --no-daemon
}

# --- MSVC x64 environment setup ---
if ($env:VSCMD_ARG_TGT_ARCH -ne "x64") {

    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

    if (-not (Test-Path $vswhere)) {
        Write-Error "vswhere.exe was not found. Visual Studio or Visual Studio Build Tools may not be installed."
        return
    }

    $vsPath = & $vswhere `
        -latest `
        -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath

    if (-not $vsPath) {
        Write-Error "No Visual Studio installation with MSVC x64 tools was found."
        return
    }

    $vcvarsall = Join-Path $vsPath "VC\Auxiliary\Build\vcvarsall.bat"

    if (-not (Test-Path $vcvarsall)) {
        Write-Error "vcvarsall.bat was not found at: $vcvarsall"
        return
    }

    $envOutput = cmd.exe /s /c "`"$vcvarsall`" x64 >nul && set"

    if ($LASTEXITCODE -ne 0) {
        Write-Error "vcvarsall.bat failed to initialize the MSVC x64 environment."
        return
    }

    foreach ($line in $envOutput) {
        if ($line -match '^([^=]+)=(.*)$') {
            Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
        }
    }

    if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
        Write-Error "MSVC environment was initialized, but cl.exe was not found in PATH."
        return
    }

    Write-Host "MSVC x64 environment activated."
}
