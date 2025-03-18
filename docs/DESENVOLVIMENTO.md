# Guia de Desenvolvimento - Jurist Prompts Hub

## Índice

1. [Arquitetura](#1-arquitetura)
2. [Ambiente de Desenvolvimento](#2-ambiente-de-desenvolvimento)
3. [Padrões de Código](#3-padrões-de-código)
4. [Fluxo de Trabalho](#4-fluxo-de-trabalho)
5. [Testes](#5-testes)
6. [Deployment](#6-deployment)
7. [Monitoramento](#7-monitoramento)

## 1. Arquitetura

### 1.1. Visão Geral

```
Frontend (React/TypeScript) <-> API (.NET) <-> Banco de Dados (SQL Server)
                               ^
                               |
                           Azure AD
```

### 1.2. Componentes Principais

- **Frontend**: React 18 + TypeScript
- **Backend**: .NET 8 Web API
- **Banco**: SQL Server 2019+
- **Autenticação**: Azure AD
- **Cache**: Redis
- **Logs**: NLog + SQL Server

### 1.3. Estrutura de Diretórios

```
/
├── src/                    # Código fonte frontend
├── NovoSistema.sln        # Solução backend
├── Database/              # Scripts e migrações
├── docs/                  # Documentação
└── scripts/               # Scripts de automação
```

## 2. Ambiente de Desenvolvimento

### 2.1. Requisitos

- Visual Studio 2022 ou VS Code
- SQL Server 2019+
- .NET 8.0 SDK
- Node.js 18.x LTS
- Git

### 2.2. Configuração Inicial

1. Clone o repositório:
```bash
git clone https://github.com/mp/jurist-prompts-hub.git
cd jurist-prompts-hub
```

2. Configure o banco:
```sql
-- Execute os scripts na ordem:
Database/Dev/Scripts/Estrutura/*.sql
Database/Dev/Scripts/Dados/*.sql
Database/Dev/Migrations/*.sql
```

3. Configure o backend:
```bash
dotnet restore
dotnet build
```

4. Configure o frontend:
```bash
npm install
npm run dev
```

### 2.3. Variáveis de Ambiente

1. Backend (appsettings.json):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "..."
  },
  "AzureAd": {
    "Instance": "...",
    "Domain": "...",
    "TenantId": "...",
    "ClientId": "..."
  }
}
```

2. Frontend (.env):
```env
VITE_API_URL=http://localhost:5000
VITE_AUTH_URL=...
VITE_CLIENT_ID=...
```

## 3. Padrões de Código

### 3.1. Convenções Gerais

- Use PascalCase para classes e interfaces
- Use camelCase para variáveis e métodos
- Prefixe interfaces com "I"
- Use async/await para operações assíncronas

### 3.2. Frontend

```typescript
// Componentes
const MyComponent: React.FC<Props> = ({ prop1, prop2 }) => {
  // ...
};

// Hooks
const useMyHook = () => {
  // ...
};

// Serviços
const MyService = {
  method: async () => {
    // ...
  }
};
```

### 3.3. Backend

```csharp
public class MyService : IMyService
{
    private readonly ILogger _logger;
    private readonly IRepository _repository;

    public MyService(ILogger logger, IRepository repository)
    {
        _logger = logger;
        _repository = repository;
    }

    public async Task<Result> DoSomethingAsync()
    {
        try
        {
            // ...
        }
        catch (Exception ex)
        {
            _logger.Error("Error message", ex);
            throw;
        }
    }
}
```

## 4. Fluxo de Trabalho

### 4.1. Branches

- `main`: Produção
- `develop`: Desenvolvimento
- `feature/*`: Novas funcionalidades
- `bugfix/*`: Correções
- `release/*`: Preparação para release

### 4.2. Commits

```bash
# Formato
<tipo>(<escopo>): <descrição>

# Exemplos
feat(prompt): adiciona sistema de tags
fix(auth): corrige validação de token
docs(api): atualiza documentação de endpoints
```

### 4.3. Pull Requests

1. Crie branch a partir de `develop`
2. Desenvolva e teste localmente
3. Faça push e crie PR
4. Aguarde review e CI/CD
5. Merge após aprovação

## 5. Testes

### 5.1. Frontend

```bash
# Testes unitários
npm test

# Cobertura
npm test -- --coverage

# E2E
npm run cypress
```

### 5.2. Backend

```bash
# Testes unitários
dotnet test

# Cobertura
dotnet test /p:CollectCoverage=true
```

### 5.3. Padrões de Teste

```typescript
// Frontend
describe('Component', () => {
  it('should render correctly', () => {
    // ...
  });
});

// Backend
[Fact]
public async Task Method_Scenario_ExpectedResult()
{
    // Arrange
    // Act
    // Assert
}
```

## 6. Deployment

### 6.1. Ambientes

- Desenvolvimento: dev.juristpromptshub.mp.gov.br
- Homologação: hom.juristpromptshub.mp.gov.br
- Produção: juristpromptshub.mp.gov.br

### 6.2. Pipeline

1. Build
2. Testes
3. Análise de código
4. Deploy
5. Smoke tests

### 6.3. Rollback

```bash
# Reverter deploy
./scripts/rollback.ps1 -version <version>

# Reverter banco
./Database/Rollback/rollback-<version>.sql
```

## 7. Monitoramento

### 7.1. Logs

- Aplicação: NLog
- IIS: W3C logs
- SQL Server: SQL Profiler
- Azure: Application Insights

### 7.2. Métricas

- Performance: New Relic
- Erros: Sentry
- Uptime: Pingdom

### 7.3. Alertas

- Erro 500: Imediato
- Performance: > 2s
- CPU: > 80%
- Memória: > 85%

## Contato

- **Líder Técnico**: tech.lead@mp.gov.br
- **Arquiteto**: architect@mp.gov.br
- **DevOps**: devops@mp.gov.br 