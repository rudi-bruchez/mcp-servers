#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run tous les tests
#>

Write-Host "🧪 Running all tests..." -ForegroundColor Cyan

# Tests unitaires
Write-Host "
Unit tests:" -ForegroundColor Yellow
go test -v -race ./...

# Tests d'intégration
Write-Host "
Integration tests:" -ForegroundColor Yellow
go test -v ./tests/...

Write-Host "
✅ All tests completed!" -ForegroundColor Green
