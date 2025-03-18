# Guia de Integração - Jurist Prompts Hub

Este guia fornece instruções detalhadas para integrar o Jurist Prompts Hub com o banco de dados institucional.

## Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Estrutura do Projeto](#2-estrutura-do-projeto)
3. [Banco de Dados](#3-banco-de-dados)
4. [Backend](#4-backend)
5. [Frontend](#5-frontend)
6. [Autenticação](#6-autenticação)
7. [Testes e Qualidade](#7-testes-e-qualidade)
8. [Implantação](#8-implantação)

## 1. Pré-requisitos

### Software Necessário
- SQL Server 2019 ou superior
- .NET 8.0 SDK
- Node.js 18.x LTS
- PowerShell 7.x
- Visual Studio 2022 ou VS Code
- Git

### Pacotes NuGet Obrigatórios
```xml
<PackageReference Include="Dapper" Version="2.0.123" />
<PackageReference Include="System.Data.SqlClient" Version="4.8.5" />
<PackageReference Include="Microsoft.AspNetCore.Authentication.AzureAD.UI" Version="6.0.0" />
<PackageReference Include="NLog.Web.AspNetCore" Version="5.3.8" />
```

### Pacotes NPM Obrigatórios
```json
{
  "dependencies": {
    "@azure/msal-browser": "^3.0.0",
    "@tanstack/react-query": "^5.0.0",
    "axios": "^1.6.0",
    "react": "^18.3.0",
    "react-router-dom": "^6.20.0"
  }
}
```

## 2. Estrutura do Projeto

### Estrutura de Diretórios Backend
```
NovoSistema.sln
├── NovoSistema.Domain
├── NovoSistema.DataAccess
├── NovoSistema.Business
├── NovoSistema.Services.WebApi
└── NovoSistema.Tests
```

### Estrutura de Diretórios Frontend
```
src/
├── assets/
├── components/
├── interfaces/
│   ├── models/
│   └── responses/
├── services/
│   ├── api/
│   └── endpoints/
├── utils/
├── pages/
└── config/
```

### Estrutura do Banco de Dados
```
Database/
├── Dev/
│   ├── Scripts/
│   │   ├── Estrutura/
│   │   ├── Dados/
│   │   └── Procedures/
│   └── Migrations/
├── Hom/
└── Prod/
```

## 3. Banco de Dados

### 3.1. Preparação

1. Crie o banco de dados:
```sql
CREATE DATABASE JuristPromptsHub;
GO
```

2. Execute os scripts na ordem:
```sql
-- 1. Estrutura inicial
Database/Dev/Scripts/Estrutura/JuristPromptsHub 2024-03-17 - Criação Inicial das Tabelas.sql

-- 2. Permissões
Database/Dev/Scripts/Estrutura/JuristPromptsHub 2024-03-17 - Configuração de Permissões.sql

-- 3. Migrações
Database/Dev/Migrations/Migration_001_AddMotivoRejeicao.sql
Database/Dev/Migrations/Migration_002_CreateAllTables.sql

-- 4. Dados iniciais
Database/Dev/Scripts/Dados/JuristPromptsHub 2024-03-17 - Dados Iniciais.sql
```

### 3.2. Configuração de Usuários

1. Crie o login SQL Server:
```sql
CREATE LOGIN [JuristPromptsHubUser] 
WITH PASSWORD = 'sua-senha-segura';
GO
```

2. Configure as permissões:
```sql
USE [JuristPromptsHub];
GO

CREATE USER [JuristPromptsHubUser] FOR LOGIN [JuristPromptsHubUser];
GO

ALTER ROLE [JuristPromptsHubRole] ADD MEMBER [JuristPromptsHubUser];
GO
```

## 4. Backend

### 4.1. Configuração (appsettings.json)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=seu-servidor;Database=JuristPromptsHub;User Id=JuristPromptsHubUser;Password=sua-senha-segura;TrustServerCertificate=True;",
    "ArmazenamentoArquivos": "Server=seu-servidor;Database=ArmazenamentoArquivos;User Id=JuristPromptsHubUser;Password=sua-senha-segura;TrustServerCertificate=True;"
  },
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "Domain": "seudominio.mp.gov.br",
    "TenantId": "seu-tenant-id",
    "ClientId": "seu-client-id",
    "CallbackPath": "/signin-oidc"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "AllowedHosts": "*",
  "CorsOrigins": [
    "https://juristpromptshub.mp.gov.br"
  ]
}
```

### 4.2. Configuração do NLog (nlog.config)

```xml
<?xml version="1.0" encoding="utf-8" ?>
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      autoReload="true"
      throwExceptions="true">

  <extensions>
    <add assembly="NLog.Web.AspNetCore"/>
  </extensions>

  <targets>
    <target xsi:type="Database" name="database"
            dbProvider="Microsoft.Data.SqlClient.SqlConnection, Microsoft.Data.SqlClient"
            connectionString="${configsetting:name=ConnectionStrings.DefaultConnection}">
      <commandText>
        INSERT INTO dbo.LogErro (
          Projeto, Data, Tipo, Mensagem, Username, ServerName,
          Logger, CallSite, Exception, InformacaoAdicional
        ) VALUES (
          @Projeto, @Data, @Tipo, @Mensagem, @Username, @ServerName,
          @Logger, @Callsite, @Exception, @InformacaoAdicional
        );
      </commandText>
      <parameter name="@Projeto" layout="${event-properties:item=Projeto}" />
      <parameter name="@Data" layout="${date}" />
      <parameter name="@Tipo" layout="${level}" />
      <parameter name="@Mensagem" layout="${message}" />
      <parameter name="@Username" layout="${aspnet-user-identity}" />
      <parameter name="@ServerName" layout="${machinename}" />
      <parameter name="@Logger" layout="${logger}" />
      <parameter name="@Callsite" layout="${callsite}" />
      <parameter name="@Exception" layout="${exception:format=tostring}" />
      <parameter name="@InformacaoAdicional" layout="${event-properties:item=InformacaoAdicional}" />
    </target>
  </targets>

  <rules>
    <logger name="*" minlevel="Error" writeTo="database" />
  </rules>
</nlog>
```

## 5. Frontend

### 5.1. Variáveis de Ambiente (.env)

```env
# API Configuration
VITE_API_URL=https://api.juristpromptshub.mp.gov.br
VITE_API_TIMEOUT=30000

# Azure AD Configuration
VITE_AUTH_URL=https://login.microsoftonline.com/seu-tenant-id
VITE_CLIENT_ID=seu-client-id
VITE_REDIRECT_URI=https://juristpromptshub.mp.gov.br/auth
VITE_POST_LOGOUT_REDIRECT_URI=https://juristpromptshub.mp.gov.br/

# Feature Flags
VITE_ENABLE_ANALYTICS=true
VITE_ENABLE_ERROR_REPORTING=true

# Other Configuration
VITE_APP_NAME=Jurist Prompts Hub
VITE_APP_DESCRIPTION=Plataforma de compartilhamento de prompts jurídicos do Ministério Público
```

### 5.2. Configuração do Vite (vite.config.ts)

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  server: {
    proxy: {
      '/api': {
        target: process.env.VITE_API_URL,
        changeOrigin: true,
        secure: true
      }
    }
  },
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          auth: ['@azure/msal-browser'],
          charts: ['recharts']
        }
      }
    }
  }
})
```

## 6. Autenticação

### 6.1. Configuração do Azure AD

1. No Portal Azure:
   - Registre o aplicativo
   - Tipo de conta: Contas apenas neste diretório organizacional
   - URI de redirecionamento: 
     - https://juristpromptshub.mp.gov.br/auth
     - https://juristpromptshub.mp.gov.br/signin-oidc
   - Permissões de API:
     - Microsoft Graph: User.Read
     - Microsoft Graph: User.ReadBasic.All

2. Configuração do Manifest:
```json
{
  "accessTokenAcceptedVersion": 2,
  "signInAudience": "AzureADMyOrg",
  "replyUrlsWithType": [
    {
      "url": "https://juristpromptshub.mp.gov.br/auth",
      "type": "Spa"
    },
    {
      "url": "https://juristpromptshub.mp.gov.br/signin-oidc",
      "type": "Web"
    }
  ]
}
```

## 7. Testes e Qualidade

### 7.1. Backend

```bash
# Testes unitários
dotnet test NovoSistema.Tests/NovoSistema.Tests.csproj

# Testes de integração
dotnet test --filter "Category=Integration"

# Cobertura de código
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

### 7.2. Frontend

```bash
# Testes unitários
npm test

# Cobertura de código
npm test -- --coverage --watchAll=false

# Análise estática
npm run lint
npm run type-check
```

## 8. Implantação

### 8.1. Backend

1. Publicação:
```bash
dotnet publish NovoSistema.Services.WebApi -c Release -o ./publish
```

2. Configuração IIS:
```xml
<configuration>
  <system.webServer>
    <handlers>
      <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
    </handlers>
    <aspNetCore processPath="dotnet" arguments="NovoSistema.Services.WebApi.dll" stdoutLogEnabled="true" stdoutLogFile=".\logs\stdout" hostingModel="inprocess" />
  </system.webServer>
</configuration>
```

### 8.2. Frontend

1. Build:
```bash
npm run build
```

2. Configuração Nginx:
```nginx
server {
    listen 443 ssl http2;
    server_name juristpromptshub.mp.gov.br;

    ssl_certificate /etc/ssl/certs/mp.gov.br.crt;
    ssl_certificate_key /etc/ssl/private/mp.gov.br.key;

    root /var/www/juristpromptshub;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass https://api.juristpromptshub.mp.gov.br;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 8.3. Verificação Pós-Implantação

```powershell
# Executar verificação completa
./scripts/verify-deployment.ps1
```

## Suporte e Manutenção

### Contatos
- Suporte Técnico: suporte.ti@mp.gov.br
- Administração do Sistema: admin.juristprompts@mp.gov.br
- Equipe de Desenvolvimento: dev.juristprompts@mp.gov.br

### Documentação Adicional
- [Manual do Usuário](./docs/MANUAL.md)
- [Guia de Desenvolvimento](./docs/DESENVOLVIMENTO.md)
- [Política de Segurança](./docs/SEGURANCA.md)

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes. 