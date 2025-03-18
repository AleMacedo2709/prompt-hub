/*
Nome: Migration_002_CreateAllTables
Data: 2024-03-17
Versão: 1.2
Descrição: Garante que todas as tabelas necessárias estão criadas
*/

BEGIN TRANSACTION;

BEGIN TRY
    -- Tabela de Usuários
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
            UltimoAcesso DATETIME
        );
    END

    -- Tabela de Categorias
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categoria')
    BEGIN
        CREATE TABLE dbo.Categoria
        (
            CategoriaId NVARCHAR(50) PRIMARY KEY,
            Nome NVARCHAR(100) NOT NULL UNIQUE,
            Descricao NVARCHAR(500),
            Ativo BIT NOT NULL DEFAULT 1,
            DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
            DataAtualizacao DATETIME
        );
    END

    -- Tabela de Prompts
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Prompt')
    BEGIN
        CREATE TABLE dbo.Prompt
        (
            PromptId NVARCHAR(50) PRIMARY KEY,
            Titulo NVARCHAR(200) NOT NULL,
            Descricao NVARCHAR(500),
            Conteudo NVARCHAR(MAX) NOT NULL,
            CategoriaId NVARCHAR(50) NOT NULL,
            Publico BIT NOT NULL DEFAULT 1,
            Status NVARCHAR(20) NOT NULL DEFAULT 'pending',
            UsuarioCriadorId INT NOT NULL,
            DataCriacao DATETIME NOT NULL DEFAULT GETDATE(),
            DataAtualizacao DATETIME,
            DataAprovacao DATETIME,
            UsuarioAprovadorId INT,
            MotivoRejeicao NVARCHAR(MAX),
            FOREIGN KEY (CategoriaId) REFERENCES dbo.Categoria(CategoriaId),
            FOREIGN KEY (UsuarioCriadorId) REFERENCES dbo.Usuario(UsuarioId),
            FOREIGN KEY (UsuarioAprovadorId) REFERENCES dbo.Usuario(UsuarioId)
        );
    END

    -- Tabela de Palavras-chave dos Prompts
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PromptPalavraChave')
    BEGIN
        CREATE TABLE dbo.PromptPalavraChave
        (
            PromptId NVARCHAR(50),
            PalavraChave NVARCHAR(50),
            PRIMARY KEY (PromptId, PalavraChave),
            FOREIGN KEY (PromptId) REFERENCES dbo.Prompt(PromptId) ON DELETE CASCADE
        );
    END

    -- Tabela de Curtidas
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PromptCurtida')
    BEGIN
        CREATE TABLE dbo.PromptCurtida
        (
            PromptId NVARCHAR(50),
            UsuarioId INT,
            DataCurtida DATETIME NOT NULL DEFAULT GETDATE(),
            PRIMARY KEY (PromptId, UsuarioId),
            FOREIGN KEY (PromptId) REFERENCES dbo.Prompt(PromptId) ON DELETE CASCADE,
            FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId)
        );
    END

    -- Tabela de Favoritos
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PromptFavorito')
    BEGIN
        CREATE TABLE dbo.PromptFavorito
        (
            PromptId NVARCHAR(50),
            UsuarioId INT,
            DataFavoritado DATETIME NOT NULL DEFAULT GETDATE(),
            PRIMARY KEY (PromptId, UsuarioId),
            FOREIGN KEY (PromptId) REFERENCES dbo.Prompt(PromptId) ON DELETE CASCADE,
            FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId)
        );
    END

    -- Tabela de Log de Erros
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LogErro')
    BEGIN
        CREATE TABLE dbo.LogErro
        (
            LogId BIGINT IDENTITY(1,1) PRIMARY KEY,
            Projeto NVARCHAR(100) NOT NULL,
            Data DATETIME NOT NULL DEFAULT GETDATE(),
            Tipo NVARCHAR(50) NOT NULL,
            Mensagem NVARCHAR(MAX) NOT NULL,
            Username NVARCHAR(100),
            ServerName NVARCHAR(100),
            Logger NVARCHAR(100),
            CallSite NVARCHAR(MAX),
            Exception NVARCHAR(MAX),
            InformacaoAdicional NVARCHAR(MAX)
        );
    END

    -- Registrar versão
    INSERT INTO dbo.DatabaseVersion (VersionNumber, ScriptName)
    VALUES ('1.2.0', 'Migration_002_CreateAllTables.sql');

    COMMIT TRANSACTION;
    PRINT 'Migration executada com sucesso!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    INSERT INTO dbo.LogErro (Projeto, Tipo, Mensagem, Exception)
    VALUES (
        'Database Migration',
        'Error',
        'Erro ao executar Migration_002_CreateAllTables',
        ERROR_MESSAGE()
    );

    THROW;
END CATCH 