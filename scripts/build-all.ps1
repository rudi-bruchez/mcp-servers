#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build tous les serveurs MCP
.PARAMETER Server
    Nom du serveur spécifique à build (optionnel)
#>

param(
    [string]$Server = ""
)

$ErrorActionPreference = "Stop"

$Servers = @("big-rewrite", "multi-api", "local-llm", "knowledge-base", "usage-tracker")

if ($Server) {
    $Servers = @($Server)
}

Write-Host "🔨 Building MCP servers..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path "bin" -Force | Out-Null

foreach ($srv in $Servers) {
    Write-Host "
Building $srv..." -ForegroundColor Yellow
    
    Push-Location "cmd/$srv"
    
    try {
        $outputName = if ($IsWindows) { "../../bin/$srv.exe" } else { "../../bin/$srv" }
        go build -ldflags="-s -w" -o $outputName
        Write-Host "✅ $srv built successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to build $srv : $_" -ForegroundColor Red
        exit 1
    }
    finally {
        Pop-Location
    }
}

Write-Host "
✅ All servers built!" -ForegroundColor Green
Get-ChildItem -Path "bin" | Format-Table Name, Length, LastWriteTime
