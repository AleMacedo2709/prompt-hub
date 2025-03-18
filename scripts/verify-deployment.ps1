#!/usr/bin/env pwsh

Write-Host "Verificando implantação do Jurist Prompts Hub..." -ForegroundColor Cyan

# Função para verificar serviços
function Test-Service {
    param (
        [string]$url,
        [string]$name
    )
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $name está online" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ $name está offline" -ForegroundColor Red
        Write-Host "  Erro: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Verificar conexão com banco de dados
function Test-Database {
    param (
        [string]$connectionString
    )
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()
        Write-Host "✅ Conexão com banco de dados estabelecida" -ForegroundColor Green
        $connection.Close()
        return $true
    }
    catch {
        Write-Host "❌ Falha na conexão com banco de dados" -ForegroundColor Red
        Write-Host "  Erro: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Verificar configurações de segurança
function Test-SecurityConfig {
    # Verificar certificados SSL
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -match "juristpromptshub.mp.gov.br"}
    if ($cert) {
        Write-Host "✅ Certificado SSL encontrado" -ForegroundColor Green
        if ($cert.NotAfter -lt (Get-Date).AddDays(30)) {
            Write-Host "⚠️ Certificado SSL expira em menos de 30 dias" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Certificado SSL não encontrado" -ForegroundColor Red
    }

    # Verificar configurações do IIS
    Import-Module WebAdministration
    $site = Get-Website | Where-Object {$_.Name -eq "JuristPromptsHub"}
    if ($site) {
        Write-Host "✅ Site configurado no IIS" -ForegroundColor Green
        
        # Verificar bindings HTTPS
        $httpsBinding = Get-WebBinding -Name "JuristPromptsHub" -Protocol "https"
        if ($httpsBinding) {
            Write-Host "✅ HTTPS configurado" -ForegroundColor Green
        } else {
            Write-Host "❌ HTTPS não configurado" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Site não encontrado no IIS" -ForegroundColor Red
    }
}

# Verificar logs
function Test-Logs {
    $logPaths = @(
        ".\logs",
        "C:\inetpub\logs\LogFiles\W3SVC1",
        ".\Database\Logs"
    )

    foreach ($path in $logPaths) {
        if (Test-Path $path) {
            Write-Host "✅ Diretório de logs encontrado: $path" -ForegroundColor Green
            
            # Verificar permissões
            $acl = Get-Acl $path
            if ($acl.Access | Where-Object {$_.IdentityReference -match "IIS_IUSRS" -or $_.IdentityReference -match "NETWORK SERVICE"}) {
                Write-Host "✅ Permissões de log configuradas corretamente" -ForegroundColor Green
            } else {
                Write-Host "❌ Permissões de log incorretas" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Diretório de logs não encontrado: $path" -ForegroundColor Red
        }
    }
}

# Verificar dependências
function Test-Dependencies {
    # Verificar .NET SDK
    try {
        $dotnetVersion = dotnet --version
        Write-Host "✅ .NET SDK $dotnetVersion instalado" -ForegroundColor Green
    } catch {
        Write-Host "❌ .NET SDK não encontrado" -ForegroundColor Red
    }

    # Verificar Node.js
    try {
        $nodeVersion = node --version
        Write-Host "✅ Node.js $nodeVersion instalado" -ForegroundColor Green
    } catch {
        Write-Host "❌ Node.js não encontrado" -ForegroundColor Red
    }

    # Verificar pacotes NPM
    if (Test-Path "package.json") {
        Write-Host "✅ package.json encontrado" -ForegroundColor Green
        npm list --depth=0 2>$null
    } else {
        Write-Host "❌ package.json não encontrado" -ForegroundColor Red
    }
}

# Verificar arquivos de configuração
function Test-ConfigFiles {
    $configFiles = @(
        ".\appsettings.json",
        ".\nlog.config",
        ".\.env",
        ".\web.config"
    )

    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            Write-Host "✅ Arquivo de configuração encontrado: $file" -ForegroundColor Green
            
            # Verificar conteúdo básico
            $content = Get-Content $file -Raw
            if ($content -match "ConnectionStrings" -or $content -match "AzureAd" -or $content -match "VITE_") {
                Write-Host "✅ Configurações básicas presentes em $file" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Possíveis configurações faltantes em $file" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ Arquivo de configuração não encontrado: $file" -ForegroundColor Red
        }
    }
}

# Executar todas as verificações
Write-Host "`nVerificando serviços..." -ForegroundColor Yellow
Test-Service -url "https://api.juristpromptshub.mp.gov.br/health" -name "API"
Test-Service -url "https://juristpromptshub.mp.gov.br" -name "Frontend"

Write-Host "`nVerificando banco de dados..." -ForegroundColor Yellow
$connectionString = "Server=seu-servidor;Database=JuristPromptsHub;Integrated Security=True;"
Test-Database -connectionString $connectionString

Write-Host "`nVerificando configurações de segurança..." -ForegroundColor Yellow
Test-SecurityConfig

Write-Host "`nVerificando logs..." -ForegroundColor Yellow
Test-Logs

Write-Host "`nVerificando dependências..." -ForegroundColor Yellow
Test-Dependencies

Write-Host "`nVerificando arquivos de configuração..." -ForegroundColor Yellow
Test-ConfigFiles

Write-Host "`nVerificação de implantação concluída!" -ForegroundColor Cyan 