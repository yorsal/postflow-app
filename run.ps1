# run-standalone.ps1 - Start standalone Next.js server
# Usage: .\scripts\run-standalone.ps1 [-Port <number>]
# Supports: Windows

param(
    [int]$Port = 3789
)

$ErrorActionPreference = "Stop"

# Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR
$STANDALONE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Green
}

function Write-Warn($message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}

function Write-Err($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

function Test-PortInUse($port) {
    netstat -ano | Select-String -Pattern ":$port\s+LISTENING" -Quiet
}

function Test-NodeInstalled {
    try {
        $null = Get-Command node -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-NodeVersion {
    if (Test-NodeInstalled) {
        $version = node --version
        if ($version -match 'v(\d+)') {
            return [int]$matches[1]
        }
    }
    return 0
}

function Install-Nodejs {
    Write-Info "Installing Node.js 24.14.0..."

    $nodeInstallerUrl = "https://nodejs.org/dist/v24.14.0/node-v24.14.0-x64.msi"
    $installerPath = "$env:TEMP\node-v24.14.0-x64.msi"

    try {
        Write-Info "Downloading Node.js installer..."
        Invoke-WebRequest -Uri $nodeInstallerUrl -OutFile $installerPath

        Write-Info "Running installer..."
        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait

        Remove-Item $installerPath -Force

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        Write-Info "Node.js installed successfully"
    } catch {
        Write-Err "Failed to install Node.js. Please install manually from https://nodejs.org"
        exit 1
    }
}

function Start-Server {
    if (-not (Test-Path $STANDALONE_DIR)) {
        Write-Err "Standalone directory not found: $STANDALONE_DIR"
        Write-Err "Please run 'npm run build' first"
        exit 1
    }

    # Find available port
    $originalPort = $Port
    while (Test-PortInUse $Port) {
        Write-Info "Port $Port is in use, trying next..."
        $Port++
    }

    if ($Port -ne $originalPort) {
        Write-Info "Using port $Port instead"
    }

    Write-Host ""
    Write-Info "Starting server at http://localhost:$Port"
    Write-Info "Press Ctrl+C to stop"
    Write-Host ""

    # Open browser after a short delay
    Start-Sleep -Seconds 1
    Start-Process "http://localhost:$Port"

    Push-Location $STANDALONE_DIR
    try {
        $env:PORT = $Port
        node server.js
    } finally {
        Pop-Location
    }
}

function Check-Node {
    if (-not (Test-NodeInstalled)) {
        Write-Err "Node.js is not installed"
        Write-Info "Installing Node.js 24.14.0 from https://nodejs.org..."
        Install-Nodejs
    }

    $nodeVersion = Get-NodeVersion
    if ($nodeVersion -lt 20) {
        Write-Warn "Node.js version ($nodeVersion) is below 20, this may cause issues"
        Write-Info "Please upgrade to Node.js 20+ from https://nodejs.org"
    } else {
        Write-Info "Using Node.js v$nodeVersion"
    }
}

# Main
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next.js Standalone Server Starter" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host ""

Check-Node

Start-Server
