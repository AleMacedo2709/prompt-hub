-- Stored Procedure: Monitoramento de Recursos do Banco de Dados
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_MonitorarRecursos')
    DROP PROCEDURE SP_MonitorarRecursos
GO

CREATE PROCEDURE SP_MonitorarRecursos
    @TipoMonitoramento VARCHAR(20) = 'ALL',    -- Tipo de monitoramento: ALL, CPU, MEMORY, IO, SESSIONS, LOCKS
    @DuracaoMinutos INT = 5,                   -- Duração do monitoramento em minutos
    @IntervaloSegundos INT = 30,               -- Intervalo entre coletas em segundos
    @LimiarCPU INT = 80,                       -- Limiar de alerta para uso de CPU (%)
    @LimiarMemoria INT = 80,                   -- Limiar de alerta para uso de memória (%)
    @LimiarIO INT = 1000                       -- Limiar de alerta para operações de IO por segundo
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @EndTime DATETIME = DATEADD(MINUTE, @DuracaoMinutos, @StartTime)
    DECLARE @CurrentTime DATETIME
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT

    -- Tabela temporária para armazenar métricas
    CREATE TABLE #ResourceMetrics
    (
        MetricId INT IDENTITY(1,1),
        CollectionTime DATETIME,
        MetricType VARCHAR(20),
        MetricName VARCHAR(50),
        MetricValue DECIMAL(18,2),
        ThresholdValue INT,
        Status VARCHAR(20),
        Details NVARCHAR(MAX)
    )

    -- Tabela temporária para comparação entre coletas
    CREATE TABLE #PreviousMetrics
    (
        MetricName VARCHAR(50),
        MetricValue DECIMAL(18,2),
        CollectionTime DATETIME
    )

    BEGIN TRY
        WHILE GETDATE() < @EndTime
        BEGIN
            SET @CurrentTime = GETDATE()

            -- Monitoramento de CPU
            IF @TipoMonitoramento IN ('ALL', 'CPU')
            BEGIN
                DECLARE @CPUUsage DECIMAL(18,2)
                
                SELECT @CPUUsage = AVG(100 - SystemIdle)
                FROM (
                    SELECT TOP(30) 
                        record.value('(./Record/@id)[1]', 'int') AS record_id,
                        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle
                    FROM (
                        SELECT TOP(30) CONVERT(XML, record) AS record 
                        FROM sys.dm_os_ring_buffers 
                        WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                        AND record LIKE '%<SystemHealth>%'
                        ORDER BY timestamp DESC
                    ) AS RingBuffers
                ) AS CPU

                INSERT INTO #ResourceMetrics 
                (CollectionTime, MetricType, MetricName, MetricValue, ThresholdValue, Status, Details)
                VALUES 
                (
                    @CurrentTime,
                    'CPU',
                    'CPU Usage',
                    @CPUUsage,
                    @LimiarCPU,
                    CASE 
                        WHEN @CPUUsage >= @LimiarCPU THEN 'ALERT'
                        ELSE 'NORMAL'
                    END,
                    'CPU usage is at ' + CAST(@CPUUsage AS VARCHAR(10)) + '%'
                )
            END

            -- Monitoramento de Memória
            IF @TipoMonitoramento IN ('ALL', 'MEMORY')
            BEGIN
                DECLARE @TotalMemory DECIMAL(18,2)
                DECLARE @UsedMemory DECIMAL(18,2)
                DECLARE @MemoryUsagePercent DECIMAL(18,2)

                SELECT 
                    @TotalMemory = total_physical_memory_kb / 1024.0,
                    @UsedMemory = (total_physical_memory_kb - available_physical_memory_kb) / 1024.0,
                    @MemoryUsagePercent = 100 * (total_physical_memory_kb - available_physical_memory_kb) / 
                                        CAST(total_physical_memory_kb AS DECIMAL(18,2))
                FROM sys.dm_os_sys_memory

                INSERT INTO #ResourceMetrics 
                (CollectionTime, MetricType, MetricName, MetricValue, ThresholdValue, Status, Details)
                VALUES 
                (
                    @CurrentTime,
                    'MEMORY',
                    'Memory Usage',
                    @MemoryUsagePercent,
                    @LimiarMemoria,
                    CASE 
                        WHEN @MemoryUsagePercent >= @LimiarMemoria THEN 'ALERT'
                        ELSE 'NORMAL'
                    END,
                    'Memory usage is at ' + CAST(@MemoryUsagePercent AS VARCHAR(10)) + 
                    '% (' + CAST(@UsedMemory AS VARCHAR(10)) + ' MB of ' + 
                    CAST(@TotalMemory AS VARCHAR(10)) + ' MB)'
                )
            END

            -- Monitoramento de IO
            IF @TipoMonitoramento IN ('ALL', 'IO')
            BEGIN
                DECLARE @IOPSRead INT
                DECLARE @IOPSWrite INT
                DECLARE @TotalIOPS INT

                SELECT 
                    @IOPSRead = SUM(num_of_reads),
                    @IOPSWrite = SUM(num_of_writes)
                FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL)

                -- Compara com a coleta anterior para calcular IOPS
                IF EXISTS (SELECT 1 FROM #PreviousMetrics WHERE MetricName = 'IO_Operations')
                BEGIN
                    DECLARE @PreviousIO DECIMAL(18,2)
                    DECLARE @PreviousTime DATETIME
                    DECLARE @IODuration DECIMAL(18,2)

                    SELECT 
                        @PreviousIO = MetricValue,
                        @PreviousTime = CollectionTime
                    FROM #PreviousMetrics 
                    WHERE MetricName = 'IO_Operations'

                    SET @IODuration = DATEDIFF(SECOND, @PreviousTime, @CurrentTime)
                    SET @TotalIOPS = CASE 
                        WHEN @IODuration > 0 
                        THEN ((@IOPSRead + @IOPSWrite) - @PreviousIO) / @IODuration
                        ELSE 0
                    END

                    INSERT INTO #ResourceMetrics 
                    (CollectionTime, MetricType, MetricName, MetricValue, ThresholdValue, Status, Details)
                    VALUES 
                    (
                        @CurrentTime,
                        'IO',
                        'IOPS',
                        @TotalIOPS,
                        @LimiarIO,
                        CASE 
                            WHEN @TotalIOPS >= @LimiarIO THEN 'ALERT'
                            ELSE 'NORMAL'
                        END,
                        'Total IOPS: ' + CAST(@TotalIOPS AS VARCHAR(10)) + 
                        ' (Read: ' + CAST(@IOPSRead AS VARCHAR(10)) + 
                        ', Write: ' + CAST(@IOPSWrite AS VARCHAR(10)) + ')'
                    )
                END

                -- Atualiza métricas anteriores
                DELETE FROM #PreviousMetrics WHERE MetricName = 'IO_Operations'
                INSERT INTO #PreviousMetrics (MetricName, MetricValue, CollectionTime)
                VALUES ('IO_Operations', @IOPSRead + @IOPSWrite, @CurrentTime)
            END

            -- Monitoramento de Sessões
            IF @TipoMonitoramento IN ('ALL', 'SESSIONS')
            BEGIN
                DECLARE @ActiveSessions INT
                DECLARE @BlockedSessions INT

                SELECT 
                    @ActiveSessions = COUNT(*),
                    @BlockedSessions = SUM(CASE WHEN blocking_session_id > 0 THEN 1 ELSE 0 END)
                FROM sys.dm_exec_requests r
                JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
                WHERE s.is_user_process = 1

                INSERT INTO #ResourceMetrics 
                (CollectionTime, MetricType, MetricName, MetricValue, ThresholdValue, Status, Details)
                VALUES 
                (
                    @CurrentTime,
                    'SESSIONS',
                    'Active Sessions',
                    @ActiveSessions,
                    NULL,
                    'INFO',
                    'Active sessions: ' + CAST(@ActiveSessions AS VARCHAR(10)) + 
                    ', Blocked sessions: ' + CAST(@BlockedSessions AS VARCHAR(10))
                )
            END

            -- Monitoramento de Locks
            IF @TipoMonitoramento IN ('ALL', 'LOCKS')
            BEGIN
                DECLARE @LockCount INT
                DECLARE @DeadlockCount INT

                SELECT @LockCount = COUNT(*)
                FROM sys.dm_tran_locks
                WHERE resource_type <> 'DATABASE'

                SELECT @DeadlockCount = COUNT(*)
                FROM sys.event_log
                WHERE event_type = 'deadlock'
                AND DATEDIFF(MINUTE, timestamp, GETDATE()) <= 5

                INSERT INTO #ResourceMetrics 
                (CollectionTime, MetricType, MetricName, MetricValue, ThresholdValue, Status, Details)
                VALUES 
                (
                    @CurrentTime,
                    'LOCKS',
                    'Lock Count',
                    @LockCount,
                    NULL,
                    CASE 
                        WHEN @DeadlockCount > 0 THEN 'ALERT'
                        WHEN @LockCount > 100 THEN 'WARNING'
                        ELSE 'NORMAL'
                    END,
                    'Active locks: ' + CAST(@LockCount AS VARCHAR(10)) + 
                    ', Recent deadlocks: ' + CAST(@DeadlockCount AS VARCHAR(10))
                )
            END

            -- Aguarda o intervalo especificado
            WAITFOR DELAY @IntervaloSegundos

        END

        -- Retorna resultados do monitoramento
        SELECT 
            CollectionTime,
            MetricType,
            MetricName,
            MetricValue,
            ThresholdValue,
            Status,
            Details
        FROM #ResourceMetrics
        ORDER BY CollectionTime, MetricType

        -- Limpa tabelas temporárias
        DROP TABLE #ResourceMetrics
        DROP TABLE #PreviousMetrics

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Limpa tabelas temporárias em caso de erro
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#ResourceMetrics%')
            DROP TABLE #ResourceMetrics

        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#PreviousMetrics%')
            DROP TABLE #PreviousMetrics

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_MonitorarRecursos TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_MonitorarRecursos -- Monitora todos os recursos com configurações padrão
-- 
-- EXEC SP_MonitorarRecursos 
--      @TipoMonitoramento = 'CPU',
--      @DuracaoMinutos = 10,
--      @IntervaloSegundos = 15,
--      @LimiarCPU = 90
-- 
-- EXEC SP_MonitorarRecursos 
--      @TipoMonitoramento = 'MEMORY',
--      @LimiarMemoria = 90
-- 
-- EXEC SP_MonitorarRecursos 
--      @TipoMonitoramento = 'IO',
--      @LimiarIO = 5000 