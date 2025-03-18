#!/usr/bin/env pwsh

Write-Host "Verificando pré-requisitos para integração com banco institucional..." -ForegroundColor Cyan

# Verificar estrutura de diretórios
$requiredDirs = @(
    "Database/Dev/Scripts/Estrutura",
    "Database/Dev/Scripts/Dados",
    "Database/Dev/Scripts/Procedures",
    "Database/Dev/Migrations",
    "Database/Hom/Scripts",
    "Database/Prod/Scripts"
)

Write-Host "`nVerificando estrutura de diretórios..." -ForegroundColor Yellow
$missingDirs = @()
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        $missingDirs += $dir
        Write-Host "❌ Diretório não encontrado: $dir" -ForegroundColor Red
    } else {
        Write-Host "✅ Diretório encontrado: $dir" -ForegroundColor Green
    }
}

# Verificar arquivos essenciais
$requiredFiles = @(
    "Database/Dev/Scripts/Estrutura/JuristPromptsHub 2024-03-17 - Criação Inicial das Tabelas.sql",
    "Database/Dev/Scripts/Dados/JuristPromptsHub 2024-03-17 - Dados Iniciais.sql",
    "appsettings.json",
    "nlog.config",
    ".env"
)

Write-Host "`nVerificando arquivos essenciais..." -ForegroundColor Yellow
$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
        Write-Host "❌ Arquivo não encontrado: $file" -ForegroundColor Red
    } else {
        Write-Host "✅ Arquivo encontrado: $file" -ForegroundColor Green
    }
}

# Verificar configurações do banco
Write-Host "`nVerificando configurações do banco de dados..." -ForegroundColor Yellow
$appsettings = Get-Content "appsettings.json" | ConvertFrom-Json
$dbConfig = $appsettings.ConnectionStrings

if (-not $dbConfig.DefaultConnection) {
    Write-Host "❌ Connection string padrão não configurada" -ForegroundColor Red
} else {
    Write-Host "✅ Connection string padrão configurada" -ForegroundColor Green
}

# Verificar pacotes NuGet
Write-Host "`nVerificando pacotes NuGet..." -ForegroundColor Yellow
$csproj = Get-ChildItem -Recurse -Filter "*.csproj"
$requiredPackages = @(
    "Dapper",
    "System.Data.SqlClient",
    "Microsoft.AspNetCore.Authentication.AzureAD.UI",
    "NLog.Web.AspNetCore"
)

foreach ($proj in $csproj) {
    $content = [xml](Get-Content $proj.FullName)
    $packages = $content.Project.ItemGroup.PackageReference
    
    foreach ($package in $requiredPackages) {
        if (-not ($packages | Where-Object { $_.Include -eq $package })) {
            Write-Host "❌ Pacote não encontrado em $($proj.Name): $package" -ForegroundColor Red
        } else {
            Write-Host "✅ Pacote encontrado em $($proj.Name): $package" -ForegroundColor Green
        }
    }
}

# Verificar configurações do frontend
Write-Host "`nVerificando configurações do frontend..." -ForegroundColor Yellow
$envFile = Get-Content ".env"
$requiredEnvVars = @(
    "VITE_API_URL",
    "VITE_AUTH_URL",
    "VITE_CLIENT_ID"
)

foreach ($var in $requiredEnvVars) {
    if (-not ($envFile | Where-Object { $_ -match "^$var=" })) {
        Write-Host "❌ Variável de ambiente não configurada: $var" -ForegroundColor Red
    } else {
        Write-Host "✅ Variável de ambiente configurada: $var" -ForegroundColor Green
    }
}

# Resumo
Write-Host "`nResumo da verificação:" -ForegroundColor Cyan
if ($missingDirs.Count -gt 0 -or $missingFiles.Count -gt 0) {
    Write-Host "`nItens faltantes que precisam ser corrigidos:" -ForegroundColor Red
    if ($missingDirs.Count -gt 0) {
        Write-Host "`nDiretórios:" -ForegroundColor Yellow
        $missingDirs | ForEach-Object { Write-Host "- $_" }
    }
    if ($missingFiles.Count -gt 0) {
        Write-Host "`nArquivos:" -ForegroundColor Yellow
        $missingFiles | ForEach-Object { Write-Host "- $_" }
    }
} else {
    Write-Host "`n✅ Todos os pré-requisitos foram atendidos!" -ForegroundColor Green
}

Write-Host "`nPróximos passos:" -ForegroundColor Cyan
Write-Host "1. Execute os scripts de migração em ordem"
Write-Host "2. Verifique as permissões do usuário do banco"
Write-Host "3. Faça backup do banco antes da integração"
Write-Host "4. Execute os testes de integração"
Write-Host "5. Monitore os logs durante a primeira execução" 