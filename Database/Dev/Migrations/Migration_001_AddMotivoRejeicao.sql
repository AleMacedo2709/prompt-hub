/*
Nome: Migration_001_AddMotivoRejeicao
Data: 2024-03-17
Versão: 1.1
Descrição: Adiciona campo MotivoRejeicao na tabela Prompt
*/

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Adicionar novo campo na tabela Prompt
    IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE object_id = OBJECT_ID('dbo.Prompt') AND name = 'MotivoRejeicao')
    BEGIN
        ALTER TABLE dbo.Prompt
        ADD MotivoRejeicao NVARCHAR(MAX) NULL;
    END

    -- 2. Registrar versão
    INSERT INTO dbo.DatabaseVersion (VersionNumber, ScriptName)
    VALUES ('1.1.0', 'Migration_001_AddMotivoRejeicao.sql');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    INSERT INTO dbo.LogErro (Projeto, Tipo, Mensagem, Exception)
    VALUES (
        'Database Migration',
        'Error',
        'Erro ao executar Migration_001_AddMotivoRejeicao',
        ERROR_MESSAGE()
    );

    THROW;
END CATCH 