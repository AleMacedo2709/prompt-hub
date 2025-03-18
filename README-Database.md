# Guia de Estruturação do Banco de Dados

Este guia fornece instruções detalhadas para organizar e implementar os scripts SQL de forma estruturada.

## Índice

1. [Estrutura de Diretórios](#1-estrutura-de-diretórios)
2. [Padrão de Nomenclatura](#2-padrão-de-nomenclatura)
3. [Scripts Base](#3-scripts-base)
4. [Scripts de Negócio](#4-scripts-de-negócio)
5. [Scripts de Dados Iniciais](#5-scripts-de-dados-iniciais)
6. [Implementação no Código](#6-implementação-no-código)
7. [Boas Práticas](#7-boas-práticas)
8. [Scripts de Migração](#8-scripts-de-migração)

## 1. Estrutura de Diretórios

```
Database/
├── Dev/
│   ├── Scripts/
│   │   ├── Estrutura/          # Criação de tabelas e estruturas
│   │   ├── Dados/             # Scripts de dados iniciais
│   │   └── Procedures/        # Stored procedures e funções
│   └── Migrations/            # Scripts de migração numerados
├── Hom/                      # Scripts específicos de homologação
│   └── Scripts/
└── Prod/                     # Scripts específicos de produção
    └── Scripts/
```

## 2. Padrão de Nomenclatura

Nome do arquivo:
```
NomeDoBanco YYYY-MM-DD - Descrição da Alteração.sql
```

Exemplo:
```
AtendimentoCidadao 2024-03-17 - Criação Inicial das Tabelas.sql
```

## 3. Scripts Base

### 01_InitialStructure.sql
```sql
/*
Nome: Estrutura Inicial do Banco de Dados
Data: 2024-03-17
Versão: 1.0
Descrição: Script de criação inicial das tabelas do sistema
*/

-- Verificação de Banco
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SeuBanco')
BEGIN
    CREATE DATABASE SeuBanco;
END
GO

USE SeuBanco;
GO

-- Controle de Versão do Banco
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DatabaseVersion')
BEGIN
    CREATE TABLE dbo.DatabaseVersion
    (
        VersionId INT IDENTITY(1,1) PRIMARY KEY,
        VersionNumber VARCHAR(20) NOT NULL,
        ScriptName VARCHAR(255) NOT NULL,
        AppliedDate DATETIME NOT NULL DEFAULT GETDATE(),
        AppliedBy VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER
    );
END
GO

-- Tabelas Principais do Sistema
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Configuracoes')
BEGIN
    CREATE TABLE dbo.Configuracoes
    (
        ConfigId INT IDENTITY(1,1) PRIMARY KEY,
        Area VARCHAR(64) NOT NULL,
        Chave VARCHAR(128) NOT NULL,
        Valor VARCHAR(256) NOT NULL,
        Descricao VARCHAR(256),
        DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
        DataAtualizacao DATETIME,
        CONSTRAINT UK_Configuracoes_Area_Chave UNIQUE (Area, Chave)
    );
END
GO
```

## 4. Scripts de Negócio

### 02_BusinessTables.sql
```sql
/*
Nome: Tabelas de Negócio
Data: 2024-03-17
Versão: 1.0
Descrição: Criação das tabelas específicas do negócio
*/

USE SeuBanco;
GO

-- 1. Usuários
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Usuario')
BEGIN
    CREATE TABLE dbo.Usuario
    (
        UsuarioId INT IDENTITY(1,1) PRIMARY KEY,
        Nome NVARCHAR(100) NOT NULL,
        Email NVARCHAR(255) NOT NULL UNIQUE,
        Ativo BIT NOT NULL DEFAULT 1,
        DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
        DataAtualizacao DATETIME
    );
END
GO

-- 2. Perfis
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Perfil')
BEGIN
    CREATE TABLE dbo.Perfil
    (
        PerfilId INT IDENTITY(1,1) PRIMARY KEY,
        Nome NVARCHAR(50) NOT NULL UNIQUE,
        Descricao NVARCHAR(255),
        Ativo BIT NOT NULL DEFAULT 1
    );
END
GO
```

## 5. Scripts de Dados Iniciais

### 03_InitialData.sql
```sql
/*
Nome: Dados Iniciais
Data: 2024-03-17
Versão: 1.0
Descrição: Inserção de dados iniciais do sistema
*/

USE SeuBanco;
GO

-- 1. Inserção de Configurações Básicas
INSERT INTO dbo.Configuracoes (Area, Chave, Valor, Descricao)
VALUES 
    ('Sistema', 'VersaoAtual', '1.0.0', 'Versão atual do sistema'),
    ('Email', 'ServidorSMTP', 'smtp.seudominio.com', 'Servidor de email'),
    ('Email', 'PortaSMTP', '587', 'Porta do servidor de email');
GO

-- 2. Inserção de Perfis Padrão
INSERT INTO dbo.Perfil (Nome, Descricao)
VALUES 
    ('Administrador', 'Acesso total ao sistema'),
    ('Usuario', 'Acesso básico ao sistema'),
    ('Gestor', 'Acesso gerencial ao sistema');
GO
```

## 6. Implementação no Código

### DatabaseConfig.cs
```csharp
public static class DatabaseConfig
{
    public static string GetConnectionString(IConfiguration configuration, string name = "DefaultConnection")
    {
        return configuration.GetConnectionString(name);
    }

    public static async Task EnsureDatabaseCreated(string connectionString)
    {
        using (var connection = new SqlConnection(connectionString))
        {
            var scripts = new[]
            {
                "01_InitialStructure.sql",
                "02_BusinessTables.sql",
                "03_InitialData.sql"
            };

            foreach (var script in scripts)
            {
                var scriptPath = Path.Combine("Database", "Dev", "Scripts", "Estrutura", script);
                var scriptContent = await File.ReadAllTextAsync(scriptPath);
                
                await connection.ExecuteAsync(scriptContent);
            }
        }
    }
}
```

### Startup.cs
```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    using (var scope = app.ApplicationServices.CreateScope())
    {
        var services = scope.ServiceProvider;
        var configuration = services.GetRequiredService<IConfiguration>();
        
        var connectionString = DatabaseConfig.GetConnectionString(configuration);
        DatabaseConfig.EnsureDatabaseCreated(connectionString).Wait();
    }
}
```

## 7. Boas Práticas

### Versionamento
- Mantenha todos os scripts no controle de versão
- Use numeração sequencial nos scripts
- Nunca modifique scripts já aplicados em produção

### Nomenclatura
- Use nomes claros e descritivos
- Inclua a data no nome do arquivo
- Use prefixos numéricos para ordenação

### Segurança
- Sempre use `IF EXISTS` antes de criar/modificar objetos
- Implemente controle de transações
- Faça backup antes de aplicar scripts em produção

### Organização
- Separe scripts por ambiente (Dev/Hom/Prod)
- Mantenha scripts de estrutura separados dos dados
- Documente alterações importantes

### Manutenção
- Mantenha um log de execução dos scripts
- Implemente rollback quando possível
- Teste os scripts em ambiente de desenvolvimento

## 8. Scripts de Migração

### Migration_001_AddNewFields.sql
```sql
/*
Nome: Migration_001_AddNewFields
Data: 2024-03-17
Versão: 1.1
Descrição: Adiciona novos campos nas tabelas principais
*/

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Adicionar novo campo na tabela Usuario
    IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE object_id = OBJECT_ID('dbo.Usuario') AND name = 'UltimoAcesso')
    BEGIN
        ALTER TABLE dbo.Usuario
        ADD UltimoAcesso DATETIME NULL;
    END

    -- 2. Atualizar registros existentes
    UPDATE dbo.Usuario
    SET UltimoAcesso = DataCriacao
    WHERE UltimoAcesso IS NULL;

    -- 3. Registrar versão
    INSERT INTO dbo.DatabaseVersion (VersionNumber, ScriptName)
    VALUES ('1.1.0', 'Migration_001_AddNewFields.sql');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    INSERT INTO dbo.LogErro (Projeto, Tipo, Mensagem, Exception)
    VALUES (
        'Database Migration',
        'Error',
        'Erro ao executar Migration_001_AddNewFields',
        ERROR_MESSAGE()
    );

    THROW;
END CATCH
```

## Contribuição

Para contribuir com este projeto:

1. Faça um Fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes. 