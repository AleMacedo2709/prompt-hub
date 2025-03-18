-- Stored Procedure: Monitoramento de Performance
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_MonitorarPerformance')
    DROP PROCEDURE SP_MonitorarPerformance
GO

CREATE PROCEDURE SP_MonitorarPerformance
    @MonitoringType VARCHAR(50) = 'ALL',     -- ALL, CPU, MEMORY, IO, QUERIES, LOCKS
    @TopQueries INT = 10,                    -- Número de queries a retornar
    @MinimumExecutions INT = 100,            -- Mínimo de execuções para análise
    @MinimumDuration INT = 1000,             -- Duração mínima em ms
    @CollectionDuration INT = 60             -- Duração da coleta em segundos
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabelas temporárias para coleta de dados
    CREATE TABLE #PerformanceMetrics
    (
        CollectionTime DATETIME,
        MetricType VARCHAR(50),
        MetricName VARCHAR(100),
        MetricValue DECIMAL(18,2),
        Details NVARCHAR(MAX)
    )

    CREATE TABLE #QueryPerformance
    (
        QueryHash BINARY(8),
        SqlHandle VARBINARY(64),
        StatementStart INT,
        StatementEnd INT,
        ExecutionCount BIGINT,
        TotalWorkerTime BIGINT,
        TotalElapsedTime BIGINT,
        TotalLogicalReads BIGINT,
        TotalPhysicalReads BIGINT,
        TotalWrites BIGINT,
        LastExecutionTime DATETIME
    )

    BEGIN TRY
        -- 1. CPU Metrics
        IF @MonitoringType IN ('ALL', 'CPU')
        BEGIN
            -- CPU Usage
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'CPU',
                'SQL Server CPU Usage %',
                cpu_percent,
                'Current CPU usage by SQL Server'
            FROM sys.dm_os_ring_buffers 
            WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
            AND DATEADD(ms, -1 * (ms_ticks - [timestamp]), GETDATE()) > DATEADD(SECOND, -60, GETDATE())

            -- CPU Queue Length
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'CPU',
                'Processor Queue Length',
                COUNT(*),
                'Number of threads waiting for CPU'
            FROM sys.dm_os_schedulers
            WHERE status = 'RUNNING'
        END

        -- 2. Memory Metrics
        IF @MonitoringType IN ('ALL', 'MEMORY')
        BEGIN
            -- Buffer Cache Hit Ratio
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'Memory',
                'Buffer Cache Hit Ratio',
                (a.cntr_value * 1.0 / b.cntr_value) * 100,
                'Percentage of pages found in memory'
            FROM sys.dm_os_performance_counters a
            JOIN sys.dm_os_performance_counters b ON 
                a.object_name = b.object_name
            WHERE a.counter_name = 'Buffer cache hit ratio'
            AND b.counter_name = 'Buffer cache hit ratio base'

            -- Page Life Expectancy
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'Memory',
                'Page Life Expectancy',
                cntr_value,
                'Expected lifetime of a page in seconds'
            FROM sys.dm_os_performance_counters
            WHERE counter_name = 'Page life expectancy'
            AND object_name LIKE '%Buffer Manager%'

            -- Memory Grants Pending
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'Memory',
                'Memory Grants Pending',
                cntr_value,
                'Number of processes waiting for memory grants'
            FROM sys.dm_os_performance_counters
            WHERE counter_name = 'Memory Grants Pending'
        END

        -- 3. IO Metrics
        IF @MonitoringType IN ('ALL', 'IO')
        BEGIN
            -- IO Stall Times
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'IO',
                'Average IO Stall (ms)',
                CASE WHEN SUM(num_of_reads + num_of_writes) = 0 
                     THEN 0 
                     ELSE SUM(io_stall) / SUM(num_of_reads + num_of_writes) 
                END,
                'Average IO stall time per operation'
            FROM sys.dm_io_virtual_file_stats(NULL, NULL)

            -- Pending IO Requests
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'IO',
                'Pending IO Requests',
                pending_disk_io_count,
                'Number of I/O requests waiting to be completed'
            FROM sys.dm_os_schedulers
            WHERE scheduler_id < 255
        END

        -- 4. Query Performance
        IF @MonitoringType IN ('ALL', 'QUERIES')
        BEGIN
            -- Coleta inicial
            INSERT INTO #QueryPerformance
            SELECT 
                qs.query_hash,
                qs.sql_handle,
                qs.statement_start_offset,
                qs.statement_end_offset,
                qs.execution_count,
                qs.total_worker_time,
                qs.total_elapsed_time,
                qs.total_logical_reads,
                qs.total_physical_reads,
                qs.total_writes,
                qs.last_execution_time
            FROM sys.dm_exec_query_stats qs
            WHERE qs.execution_count >= @MinimumExecutions
            AND qs.total_elapsed_time >= @MinimumDuration * 1000 -- Convertendo para microsegundos

            -- Top Queries by CPU
            INSERT INTO #PerformanceMetrics
            SELECT TOP (@TopQueries)
                GETDATE(),
                'Queries',
                'CPU Intensive Query',
                total_worker_time / 1000000.0, -- Convertendo para segundos
                'Query: ' + 
                SUBSTRING(
                    (SELECT text FROM sys.dm_exec_sql_text(sql_handle)),
                    statement_start/2 + 1,
                    (CASE WHEN statement_end = -1 
                          THEN LEN(CONVERT(NVARCHAR(MAX), 
                               (SELECT text FROM sys.dm_exec_sql_text(sql_handle))))
                          ELSE statement_end/2 - statement_start/2 + 1
                     END)
                )
            FROM #QueryPerformance
            ORDER BY total_worker_time DESC

            -- Top Queries by IO
            INSERT INTO #PerformanceMetrics
            SELECT TOP (@TopQueries)
                GETDATE(),
                'Queries',
                'IO Intensive Query',
                total_logical_reads + total_physical_reads,
                'Query: ' + 
                SUBSTRING(
                    (SELECT text FROM sys.dm_exec_sql_text(sql_handle)),
                    statement_start/2 + 1,
                    (CASE WHEN statement_end = -1 
                          THEN LEN(CONVERT(NVARCHAR(MAX), 
                               (SELECT text FROM sys.dm_exec_sql_text(sql_handle))))
                          ELSE statement_end/2 - statement_start/2 + 1
                     END)
                )
            FROM #QueryPerformance
            ORDER BY (total_logical_reads + total_physical_reads) DESC
        END

        -- 5. Lock Information
        IF @MonitoringType IN ('ALL', 'LOCKS')
        BEGIN
            -- Blocked Processes
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'Locks',
                'Blocked Process Count',
                COUNT(*),
                'Number of processes being blocked'
            FROM sys.dm_exec_requests
            WHERE blocking_session_id != 0

            -- Lock Waits
            INSERT INTO #PerformanceMetrics
            SELECT 
                GETDATE(),
                'Locks',
                'Lock Wait Time (ms)',
                wait_time_ms,
                'Resource: ' + resource_description
            FROM sys.dm_os_waiting_tasks
            WHERE wait_type LIKE 'LCK%'
        END

        -- Aguarda o período de coleta
        WAITFOR DELAY @CollectionDuration

        -- Retorna os resultados
        SELECT 
            CollectionTime,
            MetricType,
            MetricName,
            MetricValue,
            Details
        FROM #PerformanceMetrics
        ORDER BY 
            MetricType,
            MetricName,
            CollectionTime

        -- Limpa tabelas temporárias
        DROP TABLE #PerformanceMetrics
        DROP TABLE #QueryPerformance

    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#PerformanceMetrics%')
            DROP TABLE #PerformanceMetrics
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#QueryPerformance%')
            DROP TABLE #QueryPerformance

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
        DECLARE @ErrorState INT = ERROR_STATE()

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_MonitorarPerformance TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_MonitorarPerformance @MonitoringType = 'ALL'
-- EXEC SP_MonitorarPerformance @MonitoringType = 'CPU', @CollectionDuration = 300
-- EXEC SP_MonitorarPerformance @MonitoringType = 'QUERIES', @TopQueries = 20, @MinimumExecutions = 50
-- EXEC SP_MonitorarPerformance @MonitoringType = 'LOCKS'