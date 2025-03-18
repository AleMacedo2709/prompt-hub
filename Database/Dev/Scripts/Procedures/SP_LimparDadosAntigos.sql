-- Stored Procedure: Limpeza de Dados Antigos
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_LimparDadosAntigos')
    DROP PROCEDURE SP_LimparDadosAntigos
GO

CREATE PROCEDURE SP_LimparDadosAntigos
    @RetentionDays INT = 90,           -- Dias de retenção padrão
    @BatchSize INT = 1000,             -- Tamanho do lote para exclusão
    @WaitForDelay VARCHAR(8) = '00:00:05', -- Delay entre lotes (5 segundos)
    @TableName VARCHAR(128) = NULL     -- Nome da tabela específica (NULL para todas)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @DeletedCount INT = 0
    DECLARE @TotalDeletedCount INT = 0

    -- Tabela temporária para log de operações
    CREATE TABLE #CleanupLog
    (
        LogId INT IDENTITY(1,1),
        TableName VARCHAR(128),
        StartTime DATETIME,
        EndTime DATETIME,
        RecordsDeleted INT,
        Status VARCHAR(20),
        Message NVARCHAR(MAX)
    )

    BEGIN TRY
        -- 1. Limpeza de Logs de Erro
        IF @TableName IS NULL OR @TableName = 'LogErro'
        BEGIN
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@BatchSize)
                FROM LogErro
                WHERE DataLog < DATEADD(DAY, -@RetentionDays, GETDATE())

                SET @DeletedCount = @@ROWCOUNT
                SET @TotalDeletedCount = @TotalDeletedCount + @DeletedCount

                INSERT INTO #CleanupLog (TableName, StartTime, EndTime, RecordsDeleted, Status, Message)
                VALUES ('LogErro', @StartTime, GETDATE(), @DeletedCount, 'SUCCESS', 
                       'Deleted records older than ' + CAST(@RetentionDays AS VARCHAR) + ' days')

                IF @DeletedCount < @BatchSize BREAK
                WAITFOR DELAY @WaitForDelay
            END
        END

        -- 2. Limpeza de Logs de Auditoria
        IF @TableName IS NULL OR @TableName LIKE 'Auditoria%'
        BEGIN
            -- 2.1 Auditoria de Usuário
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@BatchSize)
                FROM AuditoriaUsuario
                WHERE DataModificacao < DATEADD(DAY, -@RetentionDays, GETDATE())

                SET @DeletedCount = @@ROWCOUNT
                SET @TotalDeletedCount = @TotalDeletedCount + @DeletedCount

                INSERT INTO #CleanupLog (TableName, StartTime, EndTime, RecordsDeleted, Status, Message)
                VALUES ('AuditoriaUsuario', @StartTime, GETDATE(), @DeletedCount, 'SUCCESS',
                       'Deleted audit records older than ' + CAST(@RetentionDays AS VARCHAR) + ' days')

                IF @DeletedCount < @BatchSize BREAK
                WAITFOR DELAY @WaitForDelay
            END

            -- 2.2 Auditoria de Prompt
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@BatchSize)
                FROM AuditoriaPrompt
                WHERE DataModificacao < DATEADD(DAY, -@RetentionDays, GETDATE())

                SET @DeletedCount = @@ROWCOUNT
                SET @TotalDeletedCount = @TotalDeletedCount + @DeletedCount

                INSERT INTO #CleanupLog (TableName, StartTime, EndTime, RecordsDeleted, Status, Message)
                VALUES ('AuditoriaPrompt', @StartTime, GETDATE(), @DeletedCount, 'SUCCESS',
                       'Deleted audit records older than ' + CAST(@RetentionDays AS VARCHAR) + ' days')

                IF @DeletedCount < @BatchSize BREAK
                WAITFOR DELAY @WaitForDelay
            END

            -- 2.3 Auditoria de Categoria
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@BatchSize)
                FROM AuditoriaCategoria
                WHERE DataModificacao < DATEADD(DAY, -@RetentionDays, GETDATE())

                SET @DeletedCount = @@ROWCOUNT
                SET @TotalDeletedCount = @TotalDeletedCount + @DeletedCount

                INSERT INTO #CleanupLog (TableName, StartTime, EndTime, RecordsDeleted, Status, Message)
                VALUES ('AuditoriaCategoria', @StartTime, GETDATE(), @DeletedCount, 'SUCCESS',
                       'Deleted audit records older than ' + CAST(@RetentionDays AS VARCHAR) + ' days')

                IF @DeletedCount < @BatchSize BREAK
                WAITFOR DELAY @WaitForDelay
            END
        END

        -- 3. Limpeza de Prompts Excluídos
        IF @TableName IS NULL OR @TableName = 'Prompt'
        BEGIN
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@BatchSize)
                FROM Prompt
                WHERE Excluido = 1
                AND DataExclusao < DATEADD(DAY, -@RetentionDays, GETDATE())

                SET @DeletedCount = @@ROWCOUNT
                SET @TotalDeletedCount = @TotalDeletedCount + @DeletedCount

                INSERT INTO #CleanupLog (TableName, StartTime, EndTime, RecordsDeleted, Status, Message)
                VALUES ('Prompt', @StartTime, GETDATE(), @DeletedCount, 'SUCCESS',
                       'Deleted soft-deleted prompts older than ' + CAST(@RetentionDays AS VARCHAR) + ' days')

                IF @DeletedCount < @BatchSize BREAK
                WAITFOR DELAY @WaitForDelay
            END
        END

        -- 4. Limpeza de Curtidas Antigas
        IF @TableName IS NULL OR @TableName = 'PromptCurtida'
        BEGIN
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@BatchSize) pc
                FROM PromptCurtida pc
                INNER JOIN Prompt p ON pc.PromptId = p.PromptId
                WHERE p.Excluido = 1
                OR p.DataCriacao < DATEADD(DAY, -@RetentionDays, GETDATE())

                SET @DeletedCount = @@ROWCOUNT
                SET @TotalDeletedCount = @TotalDeletedCount + @DeletedCount

                INSERT INTO #CleanupLog (TableName, StartTime, EndTime, RecordsDeleted, Status, Message)
                VALUES ('PromptCurtida', @StartTime, GETDATE(), @DeletedCount, 'SUCCESS',
                       'Deleted likes from deleted or old prompts')

                IF @DeletedCount < @BatchSize BREAK
                WAITFOR DELAY @WaitForDelay
            END
        END

        -- 5. Limpeza de Favoritos Antigos
        IF @TableName IS NULL OR @TableName = 'PromptFavorito'
        BEGIN
            WHILE 1 = 1
            BEGIN
                DELETE TOP (@BatchSize) pf
                FROM PromptFavorito pf
                INNER JOIN Prompt p ON pf.PromptId = p.PromptId
                WHERE p.Excluido = 1
                OR p.DataCriacao < DATEADD(DAY, -@RetentionDays, GETDATE())

                SET @DeletedCount = @@ROWCOUNT
                SET @TotalDeletedCount = @TotalDeletedCount + @DeletedCount

                INSERT INTO #CleanupLog (TableName, StartTime, EndTime, RecordsDeleted, Status, Message)
                VALUES ('PromptFavorito', @StartTime, GETDATE(), @DeletedCount, 'SUCCESS',
                       'Deleted favorites from deleted or old prompts')

                IF @DeletedCount < @BatchSize BREAK
                WAITFOR DELAY @WaitForDelay
            END
        END

        -- Retorna resumo da operação
        SELECT 
            TableName,
            StartTime,
            EndTime,
            DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
            RecordsDeleted,
            Status,
            Message
        FROM #CleanupLog
        ORDER BY LogId

        -- Retorna total de registros excluídos
        SELECT @TotalDeletedCount AS TotalRecordsDeleted

        -- Limpa tabela temporária
        DROP TABLE #CleanupLog

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#CleanupLog%')
            DROP TABLE #CleanupLog

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_LimparDadosAntigos TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_LimparDadosAntigos -- Limpa todas as tabelas com configurações padrão
-- EXEC SP_LimparDadosAntigos @RetentionDays = 30 -- Limpa registros mais antigos que 30 dias
-- EXEC SP_LimparDadosAntigos @TableName = 'LogErro' -- Limpa apenas a tabela de logs
-- EXEC SP_LimparDadosAntigos @BatchSize = 500, @WaitForDelay = '00:00:10' -- Configuração de lotes 