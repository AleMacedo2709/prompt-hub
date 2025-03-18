-- Stored Procedure: Monitoramento de CPU
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_MonitorarCPU')
    DROP PROCEDURE SP_MonitorarCPU
GO

CREATE PROCEDURE SP_MonitorarCPU
    @TipoMonitoramento VARCHAR(20) = 'ALL',    -- Tipo de monitoramento: ALL, QUERIES, SESSIONS, SCHEDULERS, WAIT_STATS
    @DuracaoMinutos INT = 5,                   -- Duração do monitoramento em minutos
    @IntervaloSegundos INT = 30,               -- Intervalo entre coletas em segundos
    @LimiarCPU INT = 80,                       -- Limiar de alerta para uso de CPU (%)
    @TopQuantidade INT = 20                    -- Quantidade de itens a retornar
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @EndTime DATETIME = DATEADD(MINUTE, @DuracaoMinutos, @StartTime)
    DECLARE @CurrentTime DATETIME
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT

    -- Tabela temporária para armazenar métricas de CPU
    CREATE TABLE #CPUMetrics
    (
        MetricId INT IDENTITY(1,1),
        CollectionTime DATETIME,
        MetricType VARCHAR(20),
        MetricName VARCHAR(50),
        ObjectName NVARCHAR(128),
        CPUTime BIGINT,
        CPUPercent DECIMAL(5,2),
        WorkerTime BIGINT,
        WaitTime BIGINT,
        Status VARCHAR(20),
        Details NVARCHAR(MAX)
    )

    -- Tabela temporária para comparação entre coletas
    CREATE TABLE #PreviousMetrics
    (
        MetricName VARCHAR(50),
        CPUTime BIGINT,
        WorkerTime BIGINT,
        WaitTime BIGINT,
        CollectionTime DATETIME
    )

    BEGIN TRY
        WHILE GETDATE() < @EndTime
        BEGIN
            SET @CurrentTime = GETDATE()

            -- Monitoramento de Queries Consumindo CPU
            IF @TipoMonitoramento IN ('ALL', 'QUERIES')
            BEGIN
                INSERT INTO #CPUMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    CPUTime, CPUPercent, WorkerTime, Status, Details
                )
                SELECT TOP (@TopQuantidade)
                    @CurrentTime AS CollectionTime,
                    'QUERIES' AS MetricType,
                    'Query CPU Usage' AS MetricName,
                    SUBSTRING(
                        CASE 
                            WHEN qt.text IS NULL THEN 'Unknown'
                            ELSE qt.text
                        END,
                        1, 100
                    ) AS ObjectName,
                    qs.total_worker_time AS CPUTime,
                    CAST(
                        100.0 * qs.total_worker_time / 
                        SUM(qs.total_worker_time) OVER() AS DECIMAL(5,2)
                    ) AS CPUPercent,
                    qs.total_elapsed_time AS WorkerTime,
                    CASE 
                        WHEN qs.total_worker_time > 1000000 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'CPU Time: ' + CAST(qs.total_worker_time/1000000.0 AS VARCHAR(20)) + 
                    ' seconds, Executions: ' + CAST(qs.execution_count AS VARCHAR(20)) +
                    ', Avg CPU: ' + CAST((qs.total_worker_time/qs.execution_count)/1000000.0 AS VARCHAR(20)) + 
                    ' seconds' AS Details
                FROM sys.dm_exec_query_stats qs
                CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
                ORDER BY qs.total_worker_time DESC
            END

            -- Monitoramento de Sessões Consumindo CPU
            IF @TipoMonitoramento IN ('ALL', 'SESSIONS')
            BEGIN
                INSERT INTO #CPUMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    CPUTime, CPUPercent, WorkerTime, Status, Details
                )
                SELECT TOP (@TopQuantidade)
                    @CurrentTime AS CollectionTime,
                    'SESSIONS' AS MetricType,
                    'Session CPU Usage' AS MetricName,
                    'Session ' + CAST(s.session_id AS VARCHAR(10)) + 
                    ' (' + s.login_name + ')' AS ObjectName,
                    s.cpu_time AS CPUTime,
                    CAST(
                        100.0 * s.cpu_time / 
                        NULLIF(SUM(s.cpu_time) OVER(), 0) AS DECIMAL(5,2)
                    ) AS CPUPercent,
                    s.total_scheduled_time AS WorkerTime,
                    CASE 
                        WHEN s.cpu_time > 1000000 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'Program: ' + ISNULL(s.program_name, 'Unknown') +
                    ', Reads: ' + CAST(s.reads AS VARCHAR(20)) +
                    ', Writes: ' + CAST(s.writes AS VARCHAR(20)) AS Details
                FROM sys.dm_exec_sessions s
                WHERE s.is_user_process = 1
                ORDER BY s.cpu_time DESC
            END

            -- Monitoramento de Schedulers
            IF @TipoMonitoramento IN ('ALL', 'SCHEDULERS')
            BEGIN
                INSERT INTO #CPUMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    CPUTime, CPUPercent, WorkerTime, Status, Details
                )
                SELECT 
                    @CurrentTime AS CollectionTime,
                    'SCHEDULERS' AS MetricType,
                    'Scheduler Usage' AS MetricName,
                    'CPU ' + CAST(cpu_id AS VARCHAR(10)) AS ObjectName,
                    active_workers_count AS CPUTime,
                    CAST(
                        100.0 * active_workers_count / 
                        SUM(active_workers_count) OVER() AS DECIMAL(5,2)
                    ) AS CPUPercent,
                    current_tasks_count AS WorkerTime,
                    CASE 
                        WHEN runnable_tasks_count > 0 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'Active workers: ' + CAST(active_workers_count AS VARCHAR(10)) +
                    ', Current tasks: ' + CAST(current_tasks_count AS VARCHAR(10)) +
                    ', Runnable tasks: ' + CAST(runnable_tasks_count AS VARCHAR(10)) +
                    ', Work queue: ' + CAST(work_queue_count AS VARCHAR(10)) AS Details
                FROM sys.dm_os_schedulers
                WHERE scheduler_id < 255
                ORDER BY active_workers_count DESC
            END

            -- Monitoramento de Wait Stats
            IF @TipoMonitoramento IN ('ALL', 'WAIT_STATS')
            BEGIN
                INSERT INTO #CPUMetrics
                (
                    CollectionTime, MetricType, MetricName, ObjectName,
                    CPUTime, CPUPercent, WaitTime, Status, Details
                )
                SELECT TOP (@TopQuantidade)
                    @CurrentTime AS CollectionTime,
                    'WAIT_STATS' AS MetricType,
                    'Wait Statistics' AS MetricName,
                    wait_type AS ObjectName,
                    waiting_tasks_count AS CPUTime,
                    CAST(
                        100.0 * wait_time_ms / 
                        SUM(wait_time_ms) OVER() AS DECIMAL(5,2)
                    ) AS CPUPercent,
                    wait_time_ms AS WaitTime,
                    CASE 
                        WHEN wait_time_ms > 1000000 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END AS Status,
                    'Waiting tasks: ' + CAST(waiting_tasks_count AS VARCHAR(20)) +
                    ', Max wait time: ' + CAST(max_wait_time_ms AS VARCHAR(20)) + ' ms' +
                    ', Avg wait time: ' + 
                    CAST(
                        CASE waiting_tasks_count 
                            WHEN 0 THEN 0 
                            ELSE wait_time_ms/waiting_tasks_count 
                        END AS VARCHAR(20)
                    ) + ' ms' AS Details
                FROM sys.dm_os_wait_stats
                WHERE wait_type NOT LIKE '%SLEEP%'
                AND wait_type NOT LIKE '%IDLE%'
                AND wait_time_ms > 0
                ORDER BY wait_time_ms DESC
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
            CPUTime,
            CPUPercent,
            WorkerTime,
            WaitTime,
            Status,
            Details
        FROM #CPUMetrics
        ORDER BY 
            CollectionTime,
            CASE MetricType
                WHEN 'QUERIES' THEN 1
                WHEN 'SESSIONS' THEN 2
                WHEN 'SCHEDULERS' THEN 3
                WHEN 'WAIT_STATS' THEN 4
                ELSE 5
            END,
            CPUTime DESC

        -- Limpa tabelas temporárias
        DROP TABLE #CPUMetrics
        DROP TABLE #PreviousMetrics

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Limpa tabelas temporárias em caso de erro
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#CPUMetrics%')
            DROP TABLE #CPUMetrics

        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#PreviousMetrics%')
            DROP TABLE #PreviousMetrics

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_MonitorarCPU TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_MonitorarCPU -- Monitora todos os tipos de uso de CPU com configurações padrão
-- 
-- EXEC SP_MonitorarCPU 
--      @TipoMonitoramento = 'QUERIES',
--      @DuracaoMinutos = 10,
--      @IntervaloSegundos = 60
-- 
-- EXEC SP_MonitorarCPU 
--      @TipoMonitoramento = 'SESSIONS',
--      @TopQuantidade = 50
-- 
-- EXEC SP_MonitorarCPU 
--      @TipoMonitoramento = 'SCHEDULERS'
-- 
-- EXEC SP_MonitorarCPU 
--      @TipoMonitoramento = 'WAIT_STATS',
--      @TopQuantidade = 100 