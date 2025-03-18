-- Stored Procedure: Monitoramento de Memória
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_MonitorarMemoria')
    DROP PROCEDURE SP_MonitorarMemoria
GO

CREATE PROCEDURE SP_MonitorarMemoria
    @TipoMonitoramento VARCHAR(20) = 'ALL',    -- Tipo de monitoramento: ALL, BUFFER, CACHE, WORKSPACE, OBJECTS
    @DuracaoMinutos INT = 5,                   -- Duração do monitoramento em minutos
    @IntervaloSegundos INT = 30,               -- Intervalo entre coletas em segundos
    @LimiarMemoria INT = 80,                   -- Limiar de alerta para uso de memória (%)
    @TopQuantidade INT = 20                    -- Quantidade de objetos a retornar
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @EndTime DATETIME = DATEADD(MINUTE, @DuracaoMinutos, @StartTime)
    DECLARE @CurrentTime DATETIME
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT

    -- Tabela temporária para armazenar métricas de memória
    CREATE TABLE #MemoryMetrics
    (
        MetricId INT IDENTITY(1,1),
        CollectionTime DATETIME,
        MetricType VARCHAR(20),
        MetricName VARCHAR(50),
        ObjectName NVARCHAR(128),
        AllocatedMB DECIMAL(18,2),
        UsedMB DECIMAL(18,2),
        PercentUsed DECIMAL(5,2),
        Status VARCHAR(20),
        Details NVARCHAR(MAX)
    )

    BEGIN TRY
        WHILE GETDATE() < @EndTime
        BEGIN
            SET @CurrentTime = GETDATE()

            -- Monitoramento do Buffer Pool
            IF @TipoMonitoramento IN ('ALL', 'BUFFER')
            BEGIN
                INSERT INTO #MemoryMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    AllocatedMB, UsedMB, PercentUsed, Status, Details
                )
                SELECT TOP (@TopQuantidade)
                    @CurrentTime AS CollectionTime,
                    'BUFFER' AS MetricType,
                    'Buffer Pool Usage' AS MetricName,
                    DB_NAME(database_id) AS ObjectName,
                    COUNT(*) * 8 / 1024.0 AS AllocatedMB,
                    COUNT(*) * 8 / 1024.0 AS UsedMB,
                    100.0 AS PercentUsed,
                    CASE 
                        WHEN (COUNT(*) * 8 / 1024.0) > 1024 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'Pages in buffer: ' + CAST(COUNT(*) AS VARCHAR(20)) +
                    ', Size: ' + CAST(CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + ' MB' AS Details
                FROM sys.dm_os_buffer_descriptors
                WHERE database_id > 0
                GROUP BY database_id
                ORDER BY COUNT(*) DESC
            END

            -- Monitoramento do Plan Cache
            IF @TipoMonitoramento IN ('ALL', 'CACHE')
            BEGIN
                INSERT INTO #MemoryMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    AllocatedMB, UsedMB, PercentUsed, Status, Details
                )
                SELECT 
                    @CurrentTime AS CollectionTime,
                    'CACHE' AS MetricType,
                    'Plan Cache Usage' AS MetricName,
                    type AS ObjectName,
                    SUM(CAST(size_in_bytes AS DECIMAL(18,2))) / 1024 / 1024 AS AllocatedMB,
                    SUM(CAST(used_memory_kb AS DECIMAL(18,2))) / 1024 AS UsedMB,
                    CASE 
                        WHEN SUM(CAST(size_in_bytes AS DECIMAL(18,2))) > 0 
                        THEN (SUM(CAST(used_memory_kb AS DECIMAL(18,2))) * 1024 * 100.0) / 
                             SUM(CAST(size_in_bytes AS DECIMAL(18,2)))
                        ELSE 0
                    END AS PercentUsed,
                    CASE 
                        WHEN (SUM(CAST(used_memory_kb AS DECIMAL(18,2))) / 1024) > 1024 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'Entries: ' + CAST(COUNT(*) AS VARCHAR(20)) +
                    ', Used: ' + CAST(CAST(SUM(CAST(used_memory_kb AS DECIMAL(18,2))) / 1024 AS DECIMAL(10,2)) AS VARCHAR(20)) + 
                    ' MB' AS Details
                FROM sys.dm_exec_cached_plans
                CROSS APPLY sys.dm_exec_sql_text(plan_handle)
                GROUP BY type
                ORDER BY SUM(CAST(used_memory_kb AS DECIMAL(18,2))) DESC
            END

            -- Monitoramento do Workspace Memory
            IF @TipoMonitoramento IN ('ALL', 'WORKSPACE')
            BEGIN
                INSERT INTO #MemoryMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    AllocatedMB, UsedMB, PercentUsed, Status, Details
                )
                SELECT 
                    @CurrentTime AS CollectionTime,
                    'WORKSPACE' AS MetricType,
                    'Workspace Memory Usage' AS MetricName,
                    'Query Workspace' AS ObjectName,
                    granted_memory_kb / 1024.0 AS AllocatedMB,
                    used_memory_kb / 1024.0 AS UsedMB,
                    CASE 
                        WHEN granted_memory_kb > 0 
                        THEN (used_memory_kb * 100.0) / granted_memory_kb
                        ELSE 0
                    END AS PercentUsed,
                    CASE 
                        WHEN (used_memory_kb / 1024.0) > 1024 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'Max used: ' + CAST(CAST(max_used_memory_kb / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + 
                    ' MB, Granted: ' + CAST(CAST(granted_memory_kb / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + 
                    ' MB' AS Details
                FROM sys.dm_exec_query_memory_grants
                WHERE granted_memory_kb > 0
            END

            -- Monitoramento de Objetos em Memória
            IF @TipoMonitoramento IN ('ALL', 'OBJECTS')
            BEGIN
                INSERT INTO #MemoryMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    AllocatedMB, UsedMB, PercentUsed, Status, Details
                )
                SELECT TOP (@TopQuantidade)
                    @CurrentTime AS CollectionTime,
                    'OBJECTS' AS MetricType,
                    'Memory Objects Usage' AS MetricName,
                    OBJECT_NAME(object_id) AS ObjectName,
                    (COUNT_BIG(*) * 8) / 1024.0 AS AllocatedMB,
                    (COUNT_BIG(*) * 8) / 1024.0 AS UsedMB,
                    100.0 AS PercentUsed,
                    CASE 
                        WHEN ((COUNT_BIG(*) * 8) / 1024.0) > 100 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'Pages: ' + CAST(COUNT_BIG(*) AS VARCHAR(20)) +
                    ', Size: ' + CAST(CAST((COUNT_BIG(*) * 8) / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + 
                    ' MB' AS Details
                FROM sys.dm_os_buffer_descriptors
                WHERE database_id = DB_ID()
                AND object_id > 0
                GROUP BY object_id
                ORDER BY COUNT_BIG(*) DESC
            END

            -- Aguarda o intervalo especificado
            WAITFOR DELAY @IntervaloSegundos

        END

        -- Retorna resultados do monitoramento
        SELECT 
            CollectionTime,
            MetricType,
            MetricName,
            ObjectName,
            AllocatedMB,
            UsedMB,
            PercentUsed,
            Status,
            Details
        FROM #MemoryMetrics
        ORDER BY 
            CollectionTime,
            CASE MetricType
                WHEN 'BUFFER' THEN 1
                WHEN 'CACHE' THEN 2
                WHEN 'WORKSPACE' THEN 3
                WHEN 'OBJECTS' THEN 4
                ELSE 5
            END,
            AllocatedMB DESC

        -- Limpa tabela temporária
        DROP TABLE #MemoryMetrics

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Limpa tabela temporária em caso de erro
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#MemoryMetrics%')
            DROP TABLE #MemoryMetrics

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_MonitorarMemoria TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_MonitorarMemoria -- Monitora todos os tipos de uso de memória com configurações padrão
-- 
-- EXEC SP_MonitorarMemoria 
--      @TipoMonitoramento = 'BUFFER',
--      @DuracaoMinutos = 10,
--      @IntervaloSegundos = 60
-- 
-- EXEC SP_MonitorarMemoria 
--      @TipoMonitoramento = 'CACHE',
--      @TopQuantidade = 50
-- 
-- EXEC SP_MonitorarMemoria 
--      @TipoMonitoramento = 'WORKSPACE'
-- 
-- EXEC SP_MonitorarMemoria 
--      @TipoMonitoramento = 'OBJECTS',
--      @TopQuantidade = 100 