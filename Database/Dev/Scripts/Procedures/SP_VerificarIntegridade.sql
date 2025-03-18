-- Stored Procedure: Verificação de Integridade do Banco de Dados
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_VerificarIntegridade')
    DROP PROCEDURE SP_VerificarIntegridade
GO

CREATE PROCEDURE SP_VerificarIntegridade
    @CheckType VARCHAR(20) = 'ALL',       -- Tipo de verificação: ALL, PHYSICAL, LOGICAL, DATA
    @FixErrors BIT = 0,                   -- Tentar corrigir erros encontrados
    @MaxDOP INT = NULL,                   -- Grau máximo de paralelismo
    @TablesOnly BIT = 0,                  -- Verificar apenas tabelas
    @WithExtendedLogicalChecks BIT = 0    -- Realizar verificações lógicas estendidas
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatabaseName NVARCHAR(128) = DB_NAME()
    DECLARE @TableName NVARCHAR(128)
    DECLARE @SchemaName NVARCHAR(128)
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @StartTime DATETIME = GETDATE()

    -- Tabela temporária para log de verificação
    CREATE TABLE #IntegrityLog
    (
        LogId INT IDENTITY(1,1),
        StartTime DATETIME,
        EndTime DATETIME,
        ObjectName NVARCHAR(256),
        CheckType VARCHAR(20),
        Status VARCHAR(20),
        Message NVARCHAR(MAX)
    )

    BEGIN TRY
        -- Verifica se o banco está online
        IF (SELECT state_desc FROM sys.databases WHERE name = @DatabaseName) != 'ONLINE'
        BEGIN
            RAISERROR ('Database is not online.', 16, 1)
            RETURN
        END

        -- Registra início da verificação geral
        INSERT INTO #IntegrityLog (StartTime, ObjectName, CheckType, Status, Message)
        VALUES (GETDATE(), @DatabaseName, @CheckType, 'IN_PROGRESS', 'Starting integrity check...')

        -- Verifica integridade física do banco
        IF @CheckType IN ('ALL', 'PHYSICAL')
        BEGIN
            INSERT INTO #IntegrityLog (StartTime, ObjectName, CheckType, Status, Message)
            VALUES (GETDATE(), @DatabaseName, 'PHYSICAL', 'IN_PROGRESS', 'Checking physical integrity...')

            SET @SQL = 'DBCC CHECKDB (' + QUOTENAME(@DatabaseName) + ') WITH PHYSICAL_ONLY'
            IF @FixErrors = 1 SET @SQL = @SQL + ', REPAIR_ALLOW_DATA_LOSS'
            IF @MaxDOP IS NOT NULL SET @SQL = @SQL + ', MAXDOP = ' + CAST(@MaxDOP AS VARCHAR(2))
            
            EXEC sp_executesql @SQL

            UPDATE #IntegrityLog
            SET EndTime = GETDATE(),
                Status = 'SUCCESS',
                Message = 'Physical integrity check completed successfully.'
            WHERE CheckType = 'PHYSICAL' AND EndTime IS NULL
        END

        -- Verifica integridade lógica do banco
        IF @CheckType IN ('ALL', 'LOGICAL')
        BEGIN
            INSERT INTO #IntegrityLog (StartTime, ObjectName, CheckType, Status, Message)
            VALUES (GETDATE(), @DatabaseName, 'LOGICAL', 'IN_PROGRESS', 'Checking logical integrity...')

            SET @SQL = 'DBCC CHECKDB (' + QUOTENAME(@DatabaseName) + ')'
            IF @WithExtendedLogicalChecks = 1 SET @SQL = @SQL + ' WITH EXTENDED_LOGICAL_CHECKS'
            IF @FixErrors = 1 SET @SQL = @SQL + ', REPAIR_ALLOW_DATA_LOSS'
            IF @MaxDOP IS NOT NULL SET @SQL = @SQL + ', MAXDOP = ' + CAST(@MaxDOP AS VARCHAR(2))

            EXEC sp_executesql @SQL

            UPDATE #IntegrityLog
            SET EndTime = GETDATE(),
                Status = 'SUCCESS',
                Message = 'Logical integrity check completed successfully.'
            WHERE CheckType = 'LOGICAL' AND EndTime IS NULL
        END

        -- Verifica integridade dos dados das tabelas
        IF @CheckType IN ('ALL', 'DATA') OR @TablesOnly = 1
        BEGIN
            DECLARE TableCursor CURSOR FOR
            SELECT s.name AS SchemaName, t.name AS TableName
            FROM sys.tables t
            INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE t.is_ms_shipped = 0

            OPEN TableCursor
            FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName

            WHILE @@FETCH_STATUS = 0
            BEGIN
                INSERT INTO #IntegrityLog (StartTime, ObjectName, CheckType, Status, Message)
                VALUES (GETDATE(), @SchemaName + '.' + @TableName, 'DATA', 'IN_PROGRESS', 
                       'Checking table data integrity...')

                SET @SQL = 'DBCC CHECKTABLE (' + QUOTENAME(@SchemaName) + '.' + 
                          QUOTENAME(@TableName) + ')'
                IF @FixErrors = 1 SET @SQL = @SQL + ' WITH REPAIR_ALLOW_DATA_LOSS'
                IF @MaxDOP IS NOT NULL SET @SQL = @SQL + ', MAXDOP = ' + CAST(@MaxDOP AS VARCHAR(2))

                EXEC sp_executesql @SQL

                UPDATE #IntegrityLog
                SET EndTime = GETDATE(),
                    Status = 'SUCCESS',
                    Message = 'Table data integrity check completed successfully.'
                WHERE ObjectName = @SchemaName + '.' + @TableName 
                  AND CheckType = 'DATA' 
                  AND EndTime IS NULL

                FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName
            END

            CLOSE TableCursor
            DEALLOCATE TableCursor
        END

        -- Atualiza log com sucesso geral
        UPDATE #IntegrityLog
        SET EndTime = GETDATE(),
            Status = 'SUCCESS',
            Message = 'All integrity checks completed successfully.'
        WHERE ObjectName = @DatabaseName AND CheckType = @CheckType

        -- Retorna resultados da verificação
        SELECT 
            StartTime,
            EndTime,
            DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
            ObjectName,
            CheckType,
            Status,
            Message
        FROM #IntegrityLog
        ORDER BY LogId

        -- Limpa tabela temporária
        DROP TABLE #IntegrityLog

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Registra erro no log
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#IntegrityLog%')
        BEGIN
            UPDATE #IntegrityLog
            SET EndTime = GETDATE(),
                Status = 'FAILED',
                Message = @ErrorMessage
            WHERE EndTime IS NULL

            -- Retorna informações da verificação com falha
            SELECT 
                StartTime,
                EndTime,
                DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
                ObjectName,
                CheckType,
                Status,
                Message
            FROM #IntegrityLog
            ORDER BY LogId

            DROP TABLE #IntegrityLog
        END

        -- Limpa cursor se ainda estiver aberto
        IF CURSOR_STATUS('global', 'TableCursor') >= 0
        BEGIN
            CLOSE TableCursor
            DEALLOCATE TableCursor
        END

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_VerificarIntegridade TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_VerificarIntegridade -- Verifica tudo com configurações padrão
-- 
-- EXEC SP_VerificarIntegridade 
--      @CheckType = 'PHYSICAL',
--      @MaxDOP = 4
-- 
-- EXEC SP_VerificarIntegridade 
--      @CheckType = 'LOGICAL',
--      @WithExtendedLogicalChecks = 1
-- 
-- EXEC SP_VerificarIntegridade 
--      @TablesOnly = 1,
--      @FixErrors = 1 