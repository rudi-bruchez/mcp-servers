#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configure Claude Desktop avec tous les serveurs MCP
#>

$ErrorActionPreference = "Stop"

Write-Host "🔧 Setup Claude Desktop configuration" -ForegroundColor Cyan

# Déterminer le chemin de config selon l'OS
$ConfigPath = if ($IsWindows) {
    "$env:APPDATA\Claude\claude_desktop_config.json"
}
elseif ($IsMacOS) {
    "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
}
else {
    "$HOME/.config/Claude/claude_desktop_config.json"
}

Write-Host "Config path: $ConfigPath" -ForegroundColor Gray

# Créer backup si existe
if (Test-Path $ConfigPath) {
    $BackupPath = "$ConfigPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $ConfigPath $BackupPath
    Write-Host "✓ Backup créé: $BackupPath" -ForegroundColor Green
}

# Créer le répertoire si nécessaire
$ConfigDir = Split-Path $ConfigPath
New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null

# Chemin absolu vers les binaires
$BinPath = Resolve-Path "bin"
$Extension = if ($IsWindows) { ".exe" } else { "" }

# Configuration
$Config = @{
    mcpServers = @{
        "big-rewrite" = @{
            command = Join-Path $BinPath "big-rewrite$Extension"
            env = @{
                ANTHROPIC_API_KEY = "$env:ANTHROPIC_API_KEY"
            }
        }
        "multi-api" = @{
            command = Join-Path $BinPath "multi-api$Extension"
            env = @{
                ANTHROPIC_API_KEY = "$env:ANTHROPIC_API_KEY"
                GOOGLE_API_KEY = "$env:GOOGLE_API_KEY"
                OPENAI_API_KEY = "$env:OPENAI_API_KEY"
            }
        }
        "local-llm" = @{
            command = Join-Path $BinPath "local-llm$Extension"
            env = @{
                LLAMA_MODEL_PATH = "$env:LLAMA_MODEL_PATH"
            }
        }
        "knowledge-base" = @{
            command = Join-Path $BinPath "knowledge-base$Extension"
        }
        "usage-tracker" = @{
            command = Join-Path $BinPath "usage-tracker$Extension"
        }
    }
}

# Sauvegarder
$Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8

Write-Host "✅ Configuration sauvegardée" -ForegroundColor Green
Write-Host "
⚠️  N'oubliez pas de:" -ForegroundColor Yellow
Write-Host "  1. Définir les variables d'environnement (API keys)" -ForegroundColor Yellow
Write-Host "  2. Redémarrer Claude Desktop" -ForegroundColor Yellow
Write-Host "
Variables requises:" -ForegroundColor Cyan
Write-Host "  - ANTHROPIC_API_KEY (pour big-rewrite, multi-api)" -ForegroundColor Gray
Write-Host "  - GOOGLE_API_KEY (pour multi-api)" -ForegroundColor Gray
Write-Host "  - OPENAI_API_KEY (pour multi-api)" -ForegroundColor Gray
Write-Host "  - LLAMA_MODEL_PATH (pour local-llm)" -ForegroundColor Gray
