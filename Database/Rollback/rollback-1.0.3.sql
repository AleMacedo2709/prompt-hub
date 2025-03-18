-- Rollback Script for Migration 003 (Add Audit Tables)
-- Data: 2024-03-17
-- Versão: 1.0.3

BEGIN TRY
    BEGIN TRANSACTION

    -- Remove triggers
    IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TR_Categoria_Audit]'))
    BEGIN
        DROP TRIGGER [dbo].[TR_Categoria_Audit]
    END

    IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TR_Prompt_Audit]'))
    BEGIN
        DROP TRIGGER [dbo].[TR_Prompt_Audit]
    END

    IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TR_Usuario_Audit]'))
    BEGIN
        DROP TRIGGER [dbo].[TR_Usuario_Audit]
    END

    -- Remove tabelas de auditoria
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditoriaCategoria]') AND type in (N'U'))
    BEGIN
        DROP TABLE [dbo].[AuditoriaCategoria]
    END

    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditoriaPrompt]') AND type in (N'U'))
    BEGIN
        DROP TABLE [dbo].[AuditoriaPrompt]
    END

    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditoriaUsuario]') AND type in (N'U'))
    BEGIN
        DROP TABLE [dbo].[AuditoriaUsuario]
    END

    -- Remove registro da versão
    DELETE FROM [dbo].[DatabaseVersion]
    WHERE [Version] = '1.0.3'

    COMMIT TRANSACTION
    PRINT 'Rollback of Migration 003 completed successfully'
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()

    PRINT 'Rollback of Migration 003 failed:'
    PRINT @ErrorMessage

    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH 