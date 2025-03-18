-- Migration Script: Add Audit Tables
-- Data: 2024-03-17
-- Versão: 1.0

BEGIN TRY
    BEGIN TRANSACTION

    -- Tabela de Auditoria de Usuários
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditoriaUsuario]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[AuditoriaUsuario](
            [AuditoriaUsuarioId] [bigint] IDENTITY(1,1) NOT NULL,
            [UsuarioId] [int] NOT NULL,
            [DataModificacao] [datetime2](7) NOT NULL,
            [TipoOperacao] [char](1) NOT NULL, -- I = Insert, U = Update, D = Delete
            [CampoModificado] [varchar](100) NOT NULL,
            [ValorAntigo] [nvarchar](max) NULL,
            [ValorNovo] [nvarchar](max) NULL,
            [UsuarioModificacao] [int] NOT NULL,
            CONSTRAINT [PK_AuditoriaUsuario] PRIMARY KEY CLUSTERED ([AuditoriaUsuarioId] ASC)
        )

        CREATE INDEX [IX_AuditoriaUsuario_UsuarioId] ON [dbo].[AuditoriaUsuario]([UsuarioId])
        CREATE INDEX [IX_AuditoriaUsuario_DataModificacao] ON [dbo].[AuditoriaUsuario]([DataModificacao])
    END

    -- Tabela de Auditoria de Prompts
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditoriaPrompt]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[AuditoriaPrompt](
            [AuditoriaPromptId] [bigint] IDENTITY(1,1) NOT NULL,
            [PromptId] [int] NOT NULL,
            [DataModificacao] [datetime2](7) NOT NULL,
            [TipoOperacao] [char](1) NOT NULL,
            [CampoModificado] [varchar](100) NOT NULL,
            [ValorAntigo] [nvarchar](max) NULL,
            [ValorNovo] [nvarchar](max) NULL,
            [UsuarioModificacao] [int] NOT NULL,
            CONSTRAINT [PK_AuditoriaPrompt] PRIMARY KEY CLUSTERED ([AuditoriaPromptId] ASC)
        )

        CREATE INDEX [IX_AuditoriaPrompt_PromptId] ON [dbo].[AuditoriaPrompt]([PromptId])
        CREATE INDEX [IX_AuditoriaPrompt_DataModificacao] ON [dbo].[AuditoriaPrompt]([DataModificacao])
    END

    -- Tabela de Auditoria de Categorias
    IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditoriaCategoria]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[AuditoriaCategoria](
            [AuditoriaCategoriaId] [bigint] IDENTITY(1,1) NOT NULL,
            [CategoriaId] [int] NOT NULL,
            [DataModificacao] [datetime2](7) NOT NULL,
            [TipoOperacao] [char](1) NOT NULL,
            [CampoModificado] [varchar](100) NOT NULL,
            [ValorAntigo] [nvarchar](max) NULL,
            [ValorNovo] [nvarchar](max) NULL,
            [UsuarioModificacao] [int] NOT NULL,
            CONSTRAINT [PK_AuditoriaCategoria] PRIMARY KEY CLUSTERED ([AuditoriaCategoriaId] ASC)
        )

        CREATE INDEX [IX_AuditoriaCategoria_CategoriaId] ON [dbo].[AuditoriaCategoria]([CategoriaId])
        CREATE INDEX [IX_AuditoriaCategoria_DataModificacao] ON [dbo].[AuditoriaCategoria]([DataModificacao])
    END

    -- Triggers para Auditoria

    -- Trigger de Usuário
    IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TR_Usuario_Audit]'))
    BEGIN
        EXEC('CREATE TRIGGER [dbo].[TR_Usuario_Audit]
        ON [dbo].[Usuario]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @UsuarioModificacao int
            SELECT @UsuarioModificacao = SYSTEM_USER

            -- Insert
            INSERT INTO [dbo].[AuditoriaUsuario]
            (UsuarioId, DataModificacao, TipoOperacao, CampoModificado, ValorNovo, UsuarioModificacao)
            SELECT 
                i.UsuarioId,
                GETDATE(),
                ''I'',
                ''ALL'',
                (SELECT i.* FOR JSON PATH),
                @UsuarioModificacao
            FROM inserted i
            WHERE NOT EXISTS (SELECT 1 FROM deleted)

            -- Delete
            INSERT INTO [dbo].[AuditoriaUsuario]
            (UsuarioId, DataModificacao, TipoOperacao, CampoModificado, ValorAntigo, UsuarioModificacao)
            SELECT 
                d.UsuarioId,
                GETDATE(),
                ''D'',
                ''ALL'',
                (SELECT d.* FOR JSON PATH),
                @UsuarioModificacao
            FROM deleted d
            WHERE NOT EXISTS (SELECT 1 FROM inserted)

            -- Update
            INSERT INTO [dbo].[AuditoriaUsuario]
            (UsuarioId, DataModificacao, TipoOperacao, CampoModificado, ValorAntigo, ValorNovo, UsuarioModificacao)
            SELECT 
                i.UsuarioId,
                GETDATE(),
                ''U'',
                ''ALL'',
                (SELECT d.* FOR JSON PATH),
                (SELECT i.* FOR JSON PATH),
                @UsuarioModificacao
            FROM deleted d
            INNER JOIN inserted i ON d.UsuarioId = i.UsuarioId
        END')
    END

    -- Trigger de Prompt
    IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TR_Prompt_Audit]'))
    BEGIN
        EXEC('CREATE TRIGGER [dbo].[TR_Prompt_Audit]
        ON [dbo].[Prompt]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @UsuarioModificacao int
            SELECT @UsuarioModificacao = SYSTEM_USER

            -- Insert
            INSERT INTO [dbo].[AuditoriaPrompt]
            (PromptId, DataModificacao, TipoOperacao, CampoModificado, ValorNovo, UsuarioModificacao)
            SELECT 
                i.PromptId,
                GETDATE(),
                ''I'',
                ''ALL'',
                (SELECT i.* FOR JSON PATH),
                @UsuarioModificacao
            FROM inserted i
            WHERE NOT EXISTS (SELECT 1 FROM deleted)

            -- Delete
            INSERT INTO [dbo].[AuditoriaPrompt]
            (PromptId, DataModificacao, TipoOperacao, CampoModificado, ValorAntigo, UsuarioModificacao)
            SELECT 
                d.PromptId,
                GETDATE(),
                ''D'',
                ''ALL'',
                (SELECT d.* FOR JSON PATH),
                @UsuarioModificacao
            FROM deleted d
            WHERE NOT EXISTS (SELECT 1 FROM inserted)

            -- Update
            INSERT INTO [dbo].[AuditoriaPrompt]
            (PromptId, DataModificacao, TipoOperacao, CampoModificado, ValorAntigo, ValorNovo, UsuarioModificacao)
            SELECT 
                i.PromptId,
                GETDATE(),
                ''U'',
                ''ALL'',
                (SELECT d.* FOR JSON PATH),
                (SELECT i.* FOR JSON PATH),
                @UsuarioModificacao
            FROM deleted d
            INNER JOIN inserted i ON d.PromptId = i.PromptId
        END')
    END

    -- Trigger de Categoria
    IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TR_Categoria_Audit]'))
    BEGIN
        EXEC('CREATE TRIGGER [dbo].[TR_Categoria_Audit]
        ON [dbo].[Categoria]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @UsuarioModificacao int
            SELECT @UsuarioModificacao = SYSTEM_USER

            -- Insert
            INSERT INTO [dbo].[AuditoriaCategoria]
            (CategoriaId, DataModificacao, TipoOperacao, CampoModificado, ValorNovo, UsuarioModificacao)
            SELECT 
                i.CategoriaId,
                GETDATE(),
                ''I'',
                ''ALL'',
                (SELECT i.* FOR JSON PATH),
                @UsuarioModificacao
            FROM inserted i
            WHERE NOT EXISTS (SELECT 1 FROM deleted)

            -- Delete
            INSERT INTO [dbo].[AuditoriaCategoria]
            (CategoriaId, DataModificacao, TipoOperacao, CampoModificado, ValorAntigo, UsuarioModificacao)
            SELECT 
                d.CategoriaId,
                GETDATE(),
                ''D'',
                ''ALL'',
                (SELECT d.* FOR JSON PATH),
                @UsuarioModificacao
            FROM deleted d
            WHERE NOT EXISTS (SELECT 1 FROM inserted)

            -- Update
            INSERT INTO [dbo].[AuditoriaCategoria]
            (CategoriaId, DataModificacao, TipoOperacao, CampoModificado, ValorAntigo, ValorNovo, UsuarioModificacao)
            SELECT 
                i.CategoriaId,
                GETDATE(),
                ''U'',
                ''ALL'',
                (SELECT d.* FOR JSON PATH),
                (SELECT i.* FOR JSON PATH),
                @UsuarioModificacao
            FROM deleted d
            INNER JOIN inserted i ON d.CategoriaId = i.CategoriaId
        END')
    END

    -- Registra versão da migração
    IF NOT EXISTS (SELECT 1 FROM [dbo].[DatabaseVersion] WHERE [Version] = '1.0.3')
    BEGIN
        INSERT INTO [dbo].[DatabaseVersion] ([Version], [AppliedOn], [Description])
        VALUES ('1.0.3', GETDATE(), 'Add Audit Tables and Triggers')
    END

    COMMIT TRANSACTION
    PRINT 'Migration 003 completed successfully'
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()

    PRINT 'Migration 003 failed:'
    PRINT @ErrorMessage

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH 