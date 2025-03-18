-- Stored Procedure: Monitoramento de Índices
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_MonitorarIndices')
    DROP PROCEDURE SP_MonitorarIndices
GO

CREATE PROCEDURE SP_MonitorarIndices
    @TipoMonitoramento VARCHAR(20) = 'ALL',    -- Tipo de monitoramento: ALL, UNUSED, FRAGMENTED, DUPLICATE, MISSING
    @DiasInatividade INT = 30,                 -- Dias sem uso para considerar índice não utilizado
    @FragmentacaoMinima INT = 5,               -- Porcentagem mínima de fragmentação para reportar
    @IncluirEstatisticas BIT = 1,             -- Incluir estatísticas de uso
    @TopQuantidade INT = 50                    -- Quantidade de índices a retornar
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT

    -- Tabela temporária para armazenar métricas de índices
    CREATE TABLE #IndexMetrics
    (
        IndexId INT IDENTITY(1,1),
        CollectionTime DATETIME,
        IndexType VARCHAR(20),
        DatabaseName NVARCHAR(128),
        SchemaName NVARCHAR(128),
        TableName NVARCHAR(128),
        IndexName NVARCHAR(128),
        IndexColumns NVARCHAR(MAX),
        IncludedColumns NVARCHAR(MAX),
        IndexSizeKB BIGINT,
        Fragmentation DECIMAL(5,2),
        PageCount INT,
        UserSeeks BIGINT,
        UserScans BIGINT,
        UserLookups BIGINT,
        UserUpdates BIGINT,
        LastUserSeek DATETIME,
        LastUserScan DATETIME,
        LastUserLookup DATETIME,
        LastUserUpdate DATETIME,
        Status VARCHAR(20),
        Details NVARCHAR(MAX)
    )

    BEGIN TRY
        -- Índices não utilizados
        IF @TipoMonitoramento IN ('ALL', 'UNUSED')
        BEGIN
            INSERT INTO #IndexMetrics
            (
                CollectionTime, IndexType, DatabaseName, SchemaName, TableName,
                IndexName, IndexColumns, IncludedColumns, IndexSizeKB,
                UserSeeks, UserScans, UserLookups, UserUpdates,
                LastUserSeek, LastUserScan, LastUserLookup, LastUserUpdate,
                Status, Details
            )
            SELECT 
                @StartTime AS CollectionTime,
                'UNUSED' AS IndexType,
                DB_NAME() AS DatabaseName,
                s.name AS SchemaName,
                t.name AS TableName,
                i.name AS IndexName,
                STUFF((
                    SELECT ', ' + c.name
                    FROM sys.index_columns ic
                    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                    WHERE ic.object_id = i.object_id 
                    AND ic.index_id = i.index_id
                    AND ic.is_included_column = 0
                    ORDER BY ic.key_ordinal
                    FOR XML PATH('')
                ), 1, 2, '') AS IndexColumns,
                STUFF((
                    SELECT ', ' + c.name
                    FROM sys.index_columns ic
                    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                    WHERE ic.object_id = i.object_id 
                    AND ic.index_id = i.index_id
                    AND ic.is_included_column = 1
                    ORDER BY ic.key_ordinal
                    FOR XML PATH('')
                ), 1, 2, '') AS IncludedColumns,
                (ps.reserved_page_count * 8) AS IndexSizeKB,
                ius.user_seeks AS UserSeeks,
                ius.user_scans AS UserScans,
                ius.user_lookups AS UserLookups,
                ius.user_updates AS UserUpdates,
                ius.last_user_seek AS LastUserSeek,
                ius.last_user_scan AS LastUserScan,
                ius.last_user_lookup AS LastUserLookup,
                ius.last_user_update AS LastUserUpdate,
                'WARNING' AS Status,
                'Index not used in the last ' + CAST(@DiasInatividade AS VARCHAR(10)) + ' days' +
                CASE 
                    WHEN ius.user_updates > 0 
                    THEN ', but has ' + CAST(ius.user_updates AS VARCHAR(20)) + ' updates'
                    ELSE ''
                END AS Details
            FROM sys.indexes i
            JOIN sys.tables t ON i.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
            LEFT JOIN sys.dm_db_index_usage_stats ius ON 
                i.object_id = ius.object_id AND 
                i.index_id = ius.index_id AND
                ius.database_id = DB_ID()
            WHERE i.type > 0  -- Não inclui heaps
            AND (
                ius.last_user_seek IS NULL OR
                ius.last_user_seek < DATEADD(DAY, -@DiasInatividade, @StartTime)
            )
            AND (
                ius.last_user_scan IS NULL OR
                ius.last_user_scan < DATEADD(DAY, -@DiasInatividade, @StartTime)
            )
            AND (
                ius.last_user_lookup IS NULL OR
                ius.last_user_lookup < DATEADD(DAY, -@DiasInatividade, @StartTime)
            )
        END

        -- Índices fragmentados
        IF @TipoMonitoramento IN ('ALL', 'FRAGMENTED')
        BEGIN
            INSERT INTO #IndexMetrics
            (
                CollectionTime, IndexType, DatabaseName, SchemaName, TableName,
                IndexName, IndexColumns, IndexSizeKB, Fragmentation, PageCount,
                Status, Details
            )
            SELECT TOP (@TopQuantidade)
                @StartTime AS CollectionTime,
                'FRAGMENTED' AS IndexType,
                DB_NAME() AS DatabaseName,
                s.name AS SchemaName,
                t.name AS TableName,
                i.name AS IndexName,
                STUFF((
                    SELECT ', ' + c.name
                    FROM sys.index_columns ic
                    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                    WHERE ic.object_id = i.object_id 
                    AND ic.index_id = i.index_id
                    AND ic.is_included_column = 0
                    ORDER BY ic.key_ordinal
                    FOR XML PATH('')
                ), 1, 2, '') AS IndexColumns,
                (ps.reserved_page_count * 8) AS IndexSizeKB,
                ips.avg_fragmentation_in_percent AS Fragmentation,
                ips.page_count AS PageCount,
                CASE 
                    WHEN ips.avg_fragmentation_in_percent >= 30 THEN 'ALERT'
                    ELSE 'WARNING'
                END AS Status,
                'Fragmentation: ' + CAST(CAST(ips.avg_fragmentation_in_percent AS DECIMAL(5,2)) AS VARCHAR(10)) + '%' +
                ', Pages: ' + CAST(ips.page_count AS VARCHAR(20)) AS Details
            FROM sys.indexes i
            JOIN sys.tables t ON i.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
            CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), i.object_id, i.index_id, NULL, 'LIMITED') ips
            WHERE ips.avg_fragmentation_in_percent >= @FragmentacaoMinima
            AND ips.page_count > 1000  -- Apenas índices com mais de 1000 páginas
            ORDER BY ips.avg_fragmentation_in_percent DESC
        END

        -- Índices duplicados
        IF @TipoMonitoramento IN ('ALL', 'DUPLICATE')
        BEGIN
            ;WITH IndexColumns AS (
                SELECT 
                    i.object_id,
                    i.index_id,
                    i.name AS index_name,
                    (
                        SELECT QUOTENAME(c.name) + CASE ic.is_descending_key WHEN 1 THEN ' DESC' ELSE ' ASC' END
                        FROM sys.index_columns ic
                        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                        WHERE ic.object_id = i.object_id 
                        AND ic.index_id = i.index_id
                        AND ic.is_included_column = 0
                        ORDER BY ic.key_ordinal
                        FOR XML PATH('')
                    ) AS key_columns,
                    (
                        SELECT QUOTENAME(c.name)
                        FROM sys.index_columns ic
                        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                        WHERE ic.object_id = i.object_id 
                        AND ic.index_id = i.index_id
                        AND ic.is_included_column = 1
                        ORDER BY ic.key_ordinal
                        FOR XML PATH('')
                    ) AS included_columns
                FROM sys.indexes i
            )
            INSERT INTO #IndexMetrics
            (
                CollectionTime, IndexType, DatabaseName, SchemaName, TableName,
                IndexName, IndexColumns, IncludedColumns, IndexSizeKB,
                Status, Details
            )
            SELECT 
                @StartTime AS CollectionTime,
                'DUPLICATE' AS IndexType,
                DB_NAME() AS DatabaseName,
                s.name AS SchemaName,
                t.name AS TableName,
                ic1.index_name AS IndexName,
                ic1.key_columns AS IndexColumns,
                ic1.included_columns AS IncludedColumns,
                (ps.reserved_page_count * 8) AS IndexSizeKB,
                'WARNING' AS Status,
                'Duplicate of index: ' + ic2.index_name AS Details
            FROM IndexColumns ic1
            JOIN IndexColumns ic2 ON 
                ic1.object_id = ic2.object_id AND
                ic1.index_id > ic2.index_id AND
                ic1.key_columns = ic2.key_columns AND
                ISNULL(ic1.included_columns, '') = ISNULL(ic2.included_columns, '')
            JOIN sys.tables t ON ic1.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            JOIN sys.dm_db_partition_stats ps ON ic1.object_id = ps.object_id AND ic1.index_id = ps.index_id
        END

        -- Índices ausentes (missing)
        IF @TipoMonitoramento IN ('ALL', 'MISSING')
        BEGIN
            INSERT INTO #IndexMetrics
            (
                CollectionTime, IndexType, DatabaseName, SchemaName, TableName,
                IndexColumns, UserSeeks, UserScans,
                Status, Details
            )
            SELECT TOP (@TopQuantidade)
                @StartTime AS CollectionTime,
                'MISSING' AS IndexType,
                DB_NAME() AS DatabaseName,
                s.name AS SchemaName,
                t.name AS TableName,
                mid.equality_columns + CASE 
                    WHEN mid.inequality_columns IS NOT NULL 
                    THEN ', ' + mid.inequality_columns 
                    ELSE '' 
                END AS IndexColumns,
                migs.user_seeks + migs.user_scans AS TotalUsage,
                migs.avg_user_impact AS AvgImpact,
                'ALERT' AS Status,
                'Estimated improvement: ' + CAST(migs.avg_user_impact AS VARCHAR(10)) + 
                '%, Usage: ' + CAST(migs.user_seeks + migs.user_scans AS VARCHAR(20)) +
                ', Estimated cost: ' + CAST(CAST(migs.avg_total_user_cost AS DECIMAL(10,2)) AS VARCHAR(20)) AS Details
            FROM sys.dm_db_missing_index_details mid
            JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
            JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
            JOIN sys.tables t ON mid.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE mid.database_id = DB_ID()
            ORDER BY (migs.user_seeks + migs.user_scans) * migs.avg_user_impact DESC
        END

        -- Retorna resultados do monitoramento
        SELECT 
            CollectionTime,
            IndexType,
            DatabaseName,
            SchemaName,
            TableName,
            IndexName,
            IndexColumns,
            IncludedColumns,
            IndexSizeKB,
            Fragmentation,
            PageCount,
            CASE WHEN @IncluirEstatisticas = 1 THEN UserSeeks ELSE NULL END AS UserSeeks,
            CASE WHEN @IncluirEstatisticas = 1 THEN UserScans ELSE NULL END AS UserScans,
            CASE WHEN @IncluirEstatisticas = 1 THEN UserLookups ELSE NULL END AS UserLookups,
            CASE WHEN @IncluirEstatisticas = 1 THEN UserUpdates ELSE NULL END AS UserUpdates,
            CASE WHEN @IncluirEstatisticas = 1 THEN LastUserSeek ELSE NULL END AS LastUserSeek,
            CASE WHEN @IncluirEstatisticas = 1 THEN LastUserScan ELSE NULL END AS LastUserScan,
            CASE WHEN @IncluirEstatisticas = 1 THEN LastUserLookup ELSE NULL END AS LastUserLookup,
            CASE WHEN @IncluirEstatisticas = 1 THEN LastUserUpdate ELSE NULL END AS LastUserUpdate,
            Status,
            Details
        FROM #IndexMetrics
        ORDER BY 
            CASE IndexType
                WHEN 'MISSING' THEN 1
                WHEN 'FRAGMENTED' THEN 2
                WHEN 'DUPLICATE' THEN 3
                WHEN 'UNUSED' THEN 4
                ELSE 5
            END,
            CASE IndexType
                WHEN 'FRAGMENTED' THEN Fragmentation
                WHEN 'MISSING' THEN UserSeeks
                ELSE NULL
            END DESC

        -- Limpa tabela temporária
        DROP TABLE #IndexMetrics

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Limpa tabela temporária em caso de erro
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#IndexMetrics%')
            DROP TABLE #IndexMetrics

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_MonitorarIndices TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_MonitorarIndices -- Monitora todos os tipos de índices com configurações padrão
-- 
-- EXEC SP_MonitorarIndices 
--      @TipoMonitoramento = 'UNUSED',
--      @DiasInatividade = 60
-- 
-- EXEC SP_MonitorarIndices 
--      @TipoMonitoramento = 'FRAGMENTED',
--      @FragmentacaoMinima = 30,
--      @TopQuantidade = 10
-- 
-- EXEC SP_MonitorarIndices 
--      @TipoMonitoramento = 'DUPLICATE'
-- 
-- EXEC SP_MonitorarIndices 
--      @TipoMonitoramento = 'MISSING',
--      @TopQuantidade = 20 