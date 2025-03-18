-- Stored Procedure: Manutenção do Banco de Dados
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_ManutencaoBancoDados')
    DROP PROCEDURE SP_ManutencaoBancoDados
GO

CREATE PROCEDURE SP_ManutencaoBancoDados
    @TipoManutencao VARCHAR(20) = 'ALL',    -- Tipo de manutenção: ALL, INDEX, STATISTICS, SHRINK
    @MaxDOP INT = NULL,                     -- Grau máximo de paralelismo
    @OnlineRebuild BIT = 1,                 -- Reconstruir índices online
    @FragmentationLimit INT = 30,           -- Limite de fragmentação para reconstrução
    @UpdateStatsSample INT = NULL,          -- Porcentagem de amostra para atualização de estatísticas
    @ShrinkLogSize INT = NULL,              -- Tamanho alvo do log em MB
    @ShrinkDataSize INT = NULL              -- Tamanho alvo do arquivo de dados em MB
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatabaseName NVARCHAR(128) = DB_NAME()
    DECLARE @TableName NVARCHAR(128)
    DECLARE @SchemaName NVARCHAR(128)
    DECLARE @IndexName NVARCHAR(128)
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @Fragmentation FLOAT
    DECLARE @PageCount INT

    -- Tabela temporária para log de manutenção
    CREATE TABLE #MaintenanceLog
    (
        LogId INT IDENTITY(1,1),
        StartTime DATETIME,
        EndTime DATETIME,
        ObjectName NVARCHAR(256),
        MaintenanceType VARCHAR(20),
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

        -- Registra início da manutenção geral
        INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
        VALUES (GETDATE(), @DatabaseName, @TipoManutencao, 'IN_PROGRESS', 'Starting maintenance...')

        -- Manutenção de índices
        IF @TipoManutencao IN ('ALL', 'INDEX')
        BEGIN
            INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
            VALUES (GETDATE(), @DatabaseName, 'INDEX', 'IN_PROGRESS', 'Starting index maintenance...')

            -- Cursor para índices
            DECLARE IndexCursor CURSOR FOR
            SELECT 
                s.name AS SchemaName,
                t.name AS TableName,
                i.name AS IndexName,
                CAST(ps.avg_fragmentation_in_percent AS FLOAT) AS Fragmentation,
                ps.page_count
            FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
            INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
            INNER JOIN sys.tables t ON i.object_id = t.object_id
            INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE ps.database_id = DB_ID()
            AND ps.index_id > 0  -- Exclui heaps
            AND ps.page_count > 1000  -- Apenas índices com mais de 1000 páginas

            OPEN IndexCursor
            FETCH NEXT FROM IndexCursor 
            INTO @SchemaName, @TableName, @IndexName, @Fragmentation, @PageCount

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Decide entre reorganizar ou reconstruir baseado na fragmentação
                IF @Fragmentation >= @FragmentationLimit
                BEGIN
                    SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
                              ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)

                    IF @OnlineRebuild = 1
                        SET @SQL = @SQL + ' REBUILD WITH (ONLINE = ON'
                    ELSE
                        SET @SQL = @SQL + ' REBUILD WITH (ONLINE = OFF'

                    IF @MaxDOP IS NOT NULL
                        SET @SQL = @SQL + ', MAXDOP = ' + CAST(@MaxDOP AS VARCHAR(2))

                    SET @SQL = @SQL + ')'
                END
                ELSE IF @Fragmentation >= 5  -- Reorganiza se fragmentação > 5%
                BEGIN
                    SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
                              ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) +
                              ' REORGANIZE'
                END

                -- Executa manutenção do índice
                IF @SQL IS NOT NULL
                BEGIN
                    INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
                    VALUES (GETDATE(), 
                           @SchemaName + '.' + @TableName + '.' + @IndexName,
                           'INDEX',
                           'IN_PROGRESS',
                           'Maintaining index. Fragmentation: ' + CAST(@Fragmentation AS VARCHAR(10)) + '%')

                    EXEC sp_executesql @SQL

                    UPDATE #MaintenanceLog
                    SET EndTime = GETDATE(),
                        Status = 'SUCCESS',
                        Message = 'Index maintenance completed. Action: ' + 
                                 CASE 
                                     WHEN @Fragmentation >= @FragmentationLimit THEN 'REBUILD'
                                     ELSE 'REORGANIZE'
                                 END
                    WHERE ObjectName = @SchemaName + '.' + @TableName + '.' + @IndexName
                      AND MaintenanceType = 'INDEX'
                      AND EndTime IS NULL
                END

                SET @SQL = NULL
                FETCH NEXT FROM IndexCursor 
                INTO @SchemaName, @TableName, @IndexName, @Fragmentation, @PageCount
            END

            CLOSE IndexCursor
            DEALLOCATE IndexCursor

            UPDATE #MaintenanceLog
            SET EndTime = GETDATE(),
                Status = 'SUCCESS',
                Message = 'Index maintenance completed successfully.'
            WHERE MaintenanceType = 'INDEX' AND ObjectName = @DatabaseName
        END

        -- Atualização de estatísticas
        IF @TipoManutencao IN ('ALL', 'STATISTICS')
        BEGIN
            INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
            VALUES (GETDATE(), @DatabaseName, 'STATISTICS', 'IN_PROGRESS', 'Starting statistics update...')

            -- Cursor para tabelas
            DECLARE TableCursor CURSOR FOR
            SELECT s.name AS SchemaName, t.name AS TableName
            FROM sys.tables t
            INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE t.is_ms_shipped = 0

            OPEN TableCursor
            FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @SQL = 'UPDATE STATISTICS ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)
                
                IF @UpdateStatsSample IS NOT NULL
                    SET @SQL = @SQL + ' WITH SAMPLE ' + CAST(@UpdateStatsSample AS VARCHAR(3)) + ' PERCENT'

                INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
                VALUES (GETDATE(), @SchemaName + '.' + @TableName, 'STATISTICS', 'IN_PROGRESS', 
                       'Updating statistics...')

                EXEC sp_executesql @SQL

                UPDATE #MaintenanceLog
                SET EndTime = GETDATE(),
                    Status = 'SUCCESS',
                    Message = 'Statistics updated successfully.'
                WHERE ObjectName = @SchemaName + '.' + @TableName
                  AND MaintenanceType = 'STATISTICS'
                  AND EndTime IS NULL

                FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName
            END

            CLOSE TableCursor
            DEALLOCATE TableCursor

            UPDATE #MaintenanceLog
            SET EndTime = GETDATE(),
                Status = 'SUCCESS',
                Message = 'Statistics update completed successfully.'
            WHERE MaintenanceType = 'STATISTICS' AND ObjectName = @DatabaseName
        END

        -- Redução de arquivos (Shrink)
        IF @TipoManutencao IN ('ALL', 'SHRINK')
        BEGIN
            INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
            VALUES (GETDATE(), @DatabaseName, 'SHRINK', 'IN_PROGRESS', 'Starting database shrink...')

            -- Reduz arquivo de log se especificado
            IF @ShrinkLogSize IS NOT NULL
            BEGIN
                SET @SQL = 'DBCC SHRINKFILE (''' + 
                          (SELECT name FROM sys.database_files WHERE type_desc = 'LOG') +
                          ''', ' + CAST(@ShrinkLogSize AS VARCHAR(20)) + ')'

                INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
                VALUES (GETDATE(), 'Log File', 'SHRINK', 'IN_PROGRESS', 'Shrinking log file...')

                EXEC sp_executesql @SQL

                UPDATE #MaintenanceLog
                SET EndTime = GETDATE(),
                    Status = 'SUCCESS',
                    Message = 'Log file shrink completed successfully.'
                WHERE ObjectName = 'Log File'
                  AND MaintenanceType = 'SHRINK'
                  AND EndTime IS NULL
            END

            -- Reduz arquivo de dados se especificado
            IF @ShrinkDataSize IS NOT NULL
            BEGIN
                SET @SQL = 'DBCC SHRINKFILE (''' + 
                          (SELECT name FROM sys.database_files WHERE type_desc = 'ROWS') +
                          ''', ' + CAST(@ShrinkDataSize AS VARCHAR(20)) + ')'

                INSERT INTO #MaintenanceLog (StartTime, ObjectName, MaintenanceType, Status, Message)
                VALUES (GETDATE(), 'Data File', 'SHRINK', 'IN_PROGRESS', 'Shrinking data file...')

                EXEC sp_executesql @SQL

                UPDATE #MaintenanceLog
                SET EndTime = GETDATE(),
                    Status = 'SUCCESS',
                    Message = 'Data file shrink completed successfully.'
                WHERE ObjectName = 'Data File'
                  AND MaintenanceType = 'SHRINK'
                  AND EndTime IS NULL
            END

            UPDATE #MaintenanceLog
            SET EndTime = GETDATE(),
                Status = 'SUCCESS',
                Message = 'Database shrink completed successfully.'
            WHERE MaintenanceType = 'SHRINK' AND ObjectName = @DatabaseName
        END

        -- Atualiza log com sucesso geral
        UPDATE #MaintenanceLog
        SET EndTime = GETDATE(),
            Status = 'SUCCESS',
            Message = 'All maintenance tasks completed successfully.'
        WHERE ObjectName = @DatabaseName AND MaintenanceType = @TipoManutencao

        -- Retorna resultados da manutenção
        SELECT 
            StartTime,
            EndTime,
            DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
            ObjectName,
            MaintenanceType,
            Status,
            Message
        FROM #MaintenanceLog
        ORDER BY LogId

        -- Limpa tabela temporária
        DROP TABLE #MaintenanceLog

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Registra erro no log
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#MaintenanceLog%')
        BEGIN
            UPDATE #MaintenanceLog
            SET EndTime = GETDATE(),
                Status = 'FAILED',
                Message = @ErrorMessage
            WHERE EndTime IS NULL

            -- Retorna informações da manutenção com falha
            SELECT 
                StartTime,
                EndTime,
                DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
                ObjectName,
                MaintenanceType,
                Status,
                Message
            FROM #MaintenanceLog
            ORDER BY LogId

            DROP TABLE #MaintenanceLog
        END

        -- Limpa cursores se ainda estiverem abertos
        IF CURSOR_STATUS('global', 'IndexCursor') >= 0
        BEGIN
            CLOSE IndexCursor
            DEALLOCATE IndexCursor
        END

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
GRANT EXECUTE ON SP_ManutencaoBancoDados TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_ManutencaoBancoDados -- Executa todas as manutenções com configurações padrão
-- 
-- EXEC SP_ManutencaoBancoDados 
--      @TipoManutencao = 'INDEX',
--      @MaxDOP = 4,
--      @OnlineRebuild = 1,
--      @FragmentationLimit = 20
-- 
-- EXEC SP_ManutencaoBancoDados 
--      @TipoManutencao = 'STATISTICS',
--      @UpdateStatsSample = 50
-- 
-- EXEC SP_ManutencaoBancoDados 
--      @TipoManutencao = 'SHRINK',
--      @ShrinkLogSize = 1024,
--      @ShrinkDataSize = 8192 