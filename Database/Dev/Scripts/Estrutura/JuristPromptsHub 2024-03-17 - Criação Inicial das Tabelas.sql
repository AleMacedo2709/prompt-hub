/*
Nome: Estrutura Inicial do Banco de Dados
Data: 2024-03-17
Versão: 1.0
Descrição: Script de criação inicial das tabelas do sistema
*/

-- Verificação de Banco
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'JuristPromptsHub')
BEGIN
    CREATE DATABASE JuristPromptsHub;
END
GO

USE JuristPromptsHub;
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

-- Configurações do Sistema
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Configuracoes')
BEGIN
    CREATE TABLE dbo.Configuracoes
    (
        ConfigId INT IDENTITY(1,1) PRIMARY KEY,
        Area VARCHAR(64) NOT NULL,
        Chave VARCHAR(128) NOT NULL,
        Valor VARCHAR(MAX) NOT NULL,
        Descricao VARCHAR(256),
        DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
        DataAtualizacao DATETIME,
        CONSTRAINT UK_Configuracoes_Area_Chave UNIQUE (Area, Chave)
    );
END
GO

-- Usuários
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Usuario')
BEGIN
    CREATE TABLE dbo.Usuario
    (
        UsuarioId INT IDENTITY(1,1) PRIMARY KEY,
        Nome NVARCHAR(100) NOT NULL,
        Email NVARCHAR(255) NOT NULL UNIQUE,
        Cargo NVARCHAR(100),
        Unidade NVARCHAR(100),
        Avatar NVARCHAR(MAX),
        Localizacao NVARCHAR(100),
        Ativo BIT NOT NULL DEFAULT 1,
        DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
        DataAtualizacao DATETIME,
        UltimoAcesso DATETIME,
        CONSTRAINT UK_Usuario_Email UNIQUE (Email)
    );
END
GO

-- Categorias
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categoria')
BEGIN
    CREATE TABLE dbo.Categoria
    (
        CategoriaId VARCHAR(50) PRIMARY KEY,
        Nome NVARCHAR(100) NOT NULL,
        Descricao NVARCHAR(255),
        Ativo BIT NOT NULL DEFAULT 1,
        DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
        DataAtualizacao DATETIME,
        CONSTRAINT UK_Categoria_Nome UNIQUE (Nome)
    );
END
GO

-- Prompts
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Prompt')
BEGIN
    CREATE TABLE dbo.Prompt
    (
        PromptId VARCHAR(36) PRIMARY KEY,
        Titulo NVARCHAR(200) NOT NULL,
        Descricao NVARCHAR(MAX),
        Conteudo NVARCHAR(MAX) NOT NULL,
        CategoriaId VARCHAR(50) NOT NULL,
        Publico BIT NOT NULL DEFAULT 1,
        Status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
        UsuarioCriadorId INT NOT NULL,
        DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
        DataAtualizacao DATETIME,
        DataAprovacao DATETIME,
        UsuarioAprovadorId INT,
        CONSTRAINT FK_Prompt_Categoria FOREIGN KEY (CategoriaId) REFERENCES dbo.Categoria(CategoriaId),
        CONSTRAINT FK_Prompt_UsuarioCriador FOREIGN KEY (UsuarioCriadorId) REFERENCES dbo.Usuario(UsuarioId),
        CONSTRAINT FK_Prompt_UsuarioAprovador FOREIGN KEY (UsuarioAprovadorId) REFERENCES dbo.Usuario(UsuarioId),
        CONSTRAINT CK_Prompt_Status CHECK (Status IN ('pending', 'approved', 'rejected'))
    );
END
GO

-- Palavras-chave dos Prompts
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PromptPalavraChave')
BEGIN
    CREATE TABLE dbo.PromptPalavraChave
    (
        PromptId VARCHAR(36),
        PalavraChave NVARCHAR(50),
        CONSTRAINT PK_PromptPalavraChave PRIMARY KEY (PromptId, PalavraChave),
        CONSTRAINT FK_PromptPalavraChave_Prompt FOREIGN KEY (PromptId) REFERENCES dbo.Prompt(PromptId)
    );
END
GO

-- Curtidas
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PromptCurtida')
BEGIN
    CREATE TABLE dbo.PromptCurtida
    (
        PromptId VARCHAR(36),
        UsuarioId INT,
        DataCurtida DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_PromptCurtida PRIMARY KEY (PromptId, UsuarioId),
        CONSTRAINT FK_PromptCurtida_Prompt FOREIGN KEY (PromptId) REFERENCES dbo.Prompt(PromptId),
        CONSTRAINT FK_PromptCurtida_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId)
    );
END
GO

-- Favoritos
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PromptFavorito')
BEGIN
    CREATE TABLE dbo.PromptFavorito
    (
        PromptId VARCHAR(36),
        UsuarioId INT,
        DataFavoritado DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_PromptFavorito PRIMARY KEY (PromptId, UsuarioId),
        CONSTRAINT FK_PromptFavorito_Prompt FOREIGN KEY (PromptId) REFERENCES dbo.Prompt(PromptId),
        CONSTRAINT FK_PromptFavorito_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId)
    );
END
GO

-- Interesses dos Usuários
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UsuarioInteresse')
BEGIN
    CREATE TABLE dbo.UsuarioInteresse
    (
        UsuarioId INT,
        CategoriaId VARCHAR(50),
        DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_UsuarioInteresse PRIMARY KEY (UsuarioId, CategoriaId),
        CONSTRAINT FK_UsuarioInteresse_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId),
        CONSTRAINT FK_UsuarioInteresse_Categoria FOREIGN KEY (CategoriaId) REFERENCES dbo.Categoria(CategoriaId)
    );
END
GO

-- Log de Erros
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LogErro')
BEGIN
    CREATE TABLE dbo.LogErro
    (
        LogId INT IDENTITY(1,1) PRIMARY KEY,
        Projeto VARCHAR(50) NOT NULL,
        Data DATETIME NOT NULL DEFAULT GETDATE(),
        Tipo VARCHAR(20) NOT NULL,
        Mensagem NVARCHAR(MAX) NOT NULL,
        Username VARCHAR(100),
        ServerName VARCHAR(100),
        Logger VARCHAR(100),
        CallSite NVARCHAR(MAX),
        Exception NVARCHAR(MAX),
        InformacaoAdicional NVARCHAR(MAX)
    );
END
GO 