-- Stored Procedure: Monitoramento de Desempenho de Consultas
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_MonitorarDesempenhoConsultas')
    DROP PROCEDURE SP_MonitorarDesempenhoConsultas
GO

CREATE PROCEDURE SP_MonitorarDesempenhoConsultas
    @TipoMonitoramento VARCHAR(20) = 'ALL',    -- Tipo de monitoramento: ALL, EXPENSIVE, BLOCKED, LONG_RUNNING, FREQUENT
    @DuracaoMinima INT = 1000,                 -- Duração mínima em milissegundos
    @TopQuantidade INT = 20,                   -- Quantidade de consultas a retornar
    @IncluirPlanoExecucao BIT = 0,            -- Incluir plano de execução
    @IncluirTextoConsulta BIT = 1,            -- Incluir texto da consulta
    @LimparCache BIT = 0                       -- Limpar cache de planos após análise
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT

    -- Tabela temporária para armazenar métricas de consultas
    CREATE TABLE #QueryMetrics
    (
        QueryId INT IDENTITY(1,1),
        CollectionTime DATETIME,
        QueryType VARCHAR(20),
        DatabaseName NVARCHAR(128),
        ExecutionCount BIGINT,
        TotalWorkerTime BIGINT,
        AvgWorkerTime AS CAST(TotalWorkerTime / ExecutionCount AS BIGINT),
        TotalElapsedTime BIGINT,
        AvgElapsedTime AS CAST(TotalElapsedTime / ExecutionCount AS BIGINT),
        TotalLogicalReads BIGINT,
        AvgLogicalReads AS CAST(TotalLogicalReads / ExecutionCount AS BIGINT),
        TotalPhysicalReads BIGINT,
        AvgPhysicalReads AS CAST(TotalPhysicalReads / ExecutionCount AS BIGINT),
        TotalWrites BIGINT,
        AvgWrites AS CAST(TotalWrites / ExecutionCount AS BIGINT),
        LastExecutionTime DATETIME,
        QueryText NVARCHAR(MAX),
        QueryPlan XML,
        Status VARCHAR(20),
        Details NVARCHAR(MAX)
    )

    BEGIN TRY
        -- Consultas mais custosas (CPU, IO, etc)
        IF @TipoMonitoramento IN ('ALL', 'EXPENSIVE')
        BEGIN
            INSERT INTO #QueryMetrics
            (
                CollectionTime, QueryType, DatabaseName, ExecutionCount,
                TotalWorkerTime, TotalElapsedTime, TotalLogicalReads,
                TotalPhysicalReads, TotalWrites, LastExecutionTime,
                QueryText, QueryPlan, Status, Details
            )
            SELECT TOP (@TopQuantidade)
                @StartTime AS CollectionTime,
                'EXPENSIVE' AS QueryType,
                DB_NAME(qt.dbid) AS DatabaseName,
                qs.execution_count AS ExecutionCount,
                qs.total_worker_time AS TotalWorkerTime,
                qs.total_elapsed_time AS TotalElapsedTime,
                qs.total_logical_reads AS TotalLogicalReads,
                qs.total_physical_reads AS TotalPhysicalReads,
                qs.total_writes AS TotalWrites,
                qs.last_execution_time AS LastExecutionTime,
                CASE @IncluirTextoConsulta 
                    WHEN 1 THEN SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
                        ((CASE qs.statement_end_offset
                            WHEN -1 THEN DATALENGTH(qt.text)
                            ELSE qs.statement_end_offset
                        END - qs.statement_start_offset)/2) + 1)
                    ELSE NULL
                END AS QueryText,
                CASE @IncluirPlanoExecucao
                    WHEN 1 THEN qp.query_plan
                    ELSE NULL
                END AS QueryPlan,
                'INFO' AS Status,
                'CPU Time: ' + CAST(qs.total_worker_time/1000000.0 AS VARCHAR(20)) + ' seconds, ' +
                'Elapsed Time: ' + CAST(qs.total_elapsed_time/1000000.0 AS VARCHAR(20)) + ' seconds, ' +
                'Logical Reads: ' + CAST(qs.total_logical_reads AS VARCHAR(20)) + ', ' +
                'Physical Reads: ' + CAST(qs.total_physical_reads AS VARCHAR(20)) + ', ' +
                'Writes: ' + CAST(qs.total_writes AS VARCHAR(20)) AS Details
            FROM sys.dm_exec_query_stats qs
            CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
            OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
            WHERE qs.total_elapsed_time > @DuracaoMinima * 1000
            ORDER BY qs.total_worker_time DESC
        END

        -- Consultas bloqueadas
        IF @TipoMonitoramento IN ('ALL', 'BLOCKED')
        BEGIN
            INSERT INTO #QueryMetrics
            (
                CollectionTime, QueryType, DatabaseName, ExecutionCount,
                TotalElapsedTime, LastExecutionTime, QueryText,
                Status, Details
            )
            SELECT 
                @StartTime AS CollectionTime,
                'BLOCKED' AS QueryType,
                DB_NAME(r.database_id) AS DatabaseName,
                1 AS ExecutionCount,
                r.total_elapsed_time AS TotalElapsedTime,
                r.start_time AS LastExecutionTime,
                CASE @IncluirTextoConsulta
                    WHEN 1 THEN t.text
                    ELSE NULL
                END AS QueryText,
                'ALERT' AS Status,
                'Blocked by Session: ' + CAST(r.blocking_session_id AS VARCHAR(10)) + 
                ', Wait Type: ' + r.wait_type + 
                ', Wait Time: ' + CAST(r.wait_time/1000.0 AS VARCHAR(20)) + ' seconds' AS Details
            FROM sys.dm_exec_requests r
            CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
            WHERE r.blocking_session_id > 0
        END

        -- Consultas de longa duração
        IF @TipoMonitoramento IN ('ALL', 'LONG_RUNNING')
        BEGIN
            INSERT INTO #QueryMetrics
            (
                CollectionTime, QueryType, DatabaseName, ExecutionCount,
                TotalElapsedTime, LastExecutionTime, QueryText,
                QueryPlan, Status, Details
            )
            SELECT TOP (@TopQuantidade)
                @StartTime AS CollectionTime,
                'LONG_RUNNING' AS QueryType,
                DB_NAME(r.database_id) AS DatabaseName,
                1 AS ExecutionCount,
                r.total_elapsed_time AS TotalElapsedTime,
                r.start_time AS LastExecutionTime,
                CASE @IncluirTextoConsulta
                    WHEN 1 THEN t.text
                    ELSE NULL
                END AS QueryText,
                CASE @IncluirPlanoExecucao
                    WHEN 1 THEN p.query_plan
                    ELSE NULL
                END AS QueryPlan,
                'WARNING' AS Status,
                'Running for ' + CAST(DATEDIFF(SECOND, r.start_time, GETDATE()) AS VARCHAR(10)) + 
                ' seconds, Status: ' + r.status +
                ', Wait Type: ' + ISNULL(r.wait_type, 'None') AS Details
            FROM sys.dm_exec_requests r
            CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
            OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) p
            WHERE r.total_elapsed_time > @DuracaoMinima * 1000
            ORDER BY r.total_elapsed_time DESC
        END

        -- Consultas mais frequentes
        IF @TipoMonitoramento IN ('ALL', 'FREQUENT')
        BEGIN
            INSERT INTO #QueryMetrics
            (
                CollectionTime, QueryType, DatabaseName, ExecutionCount,
                TotalWorkerTime, TotalElapsedTime, TotalLogicalReads,
                LastExecutionTime, QueryText, QueryPlan,
                Status, Details
            )
            SELECT TOP (@TopQuantidade)
                @StartTime AS CollectionTime,
                'FREQUENT' AS QueryType,
                DB_NAME(qt.dbid) AS DatabaseName,
                qs.execution_count AS ExecutionCount,
                qs.total_worker_time AS TotalWorkerTime,
                qs.total_elapsed_time AS TotalElapsedTime,
                qs.total_logical_reads AS TotalLogicalReads,
                qs.last_execution_time AS LastExecutionTime,
                CASE @IncluirTextoConsulta
                    WHEN 1 THEN SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
                        ((CASE qs.statement_end_offset
                            WHEN -1 THEN DATALENGTH(qt.text)
                            ELSE qs.statement_end_offset
                        END - qs.statement_start_offset)/2) + 1)
                    ELSE NULL
                END AS QueryText,
                CASE @IncluirPlanoExecucao
                    WHEN 1 THEN qp.query_plan
                    ELSE NULL
                END AS QueryPlan,
                'INFO' AS Status,
                'Executions: ' + CAST(qs.execution_count AS VARCHAR(20)) + 
                ', Avg CPU Time: ' + CAST((qs.total_worker_time/qs.execution_count)/1000000.0 AS VARCHAR(20)) + ' seconds, ' +
                'Avg Elapsed Time: ' + CAST((qs.total_elapsed_time/qs.execution_count)/1000000.0 AS VARCHAR(20)) + ' seconds' AS Details
            FROM sys.dm_exec_query_stats qs
            CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
            OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
            ORDER BY qs.execution_count DESC
        END

        -- Retorna resultados do monitoramento
        SELECT 
            CollectionTime,
            QueryType,
            DatabaseName,
            ExecutionCount,
            TotalWorkerTime,
            AvgWorkerTime,
            TotalElapsedTime,
            AvgElapsedTime,
            TotalLogicalReads,
            AvgLogicalReads,
            TotalPhysicalReads,
            AvgPhysicalReads,
            TotalWrites,
            AvgWrites,
            LastExecutionTime,
            QueryText,
            QueryPlan,
            Status,
            Details
        FROM #QueryMetrics
        ORDER BY 
            CASE QueryType
                WHEN 'BLOCKED' THEN 1
                WHEN 'LONG_RUNNING' THEN 2
                WHEN 'EXPENSIVE' THEN 3
                WHEN 'FREQUENT' THEN 4
                ELSE 5
            END,
            TotalElapsedTime DESC

        -- Limpa cache de planos se solicitado
        IF @LimparCache = 1
        BEGIN
            DBCC FREEPROCCACHE
        END

        -- Limpa tabela temporária
        DROP TABLE #QueryMetrics

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Limpa tabela temporária em caso de erro
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#QueryMetrics%')
            DROP TABLE #QueryMetrics

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_MonitorarDesempenhoConsultas TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_MonitorarDesempenhoConsultas -- Monitora todos os tipos de consultas com configurações padrão
-- 
-- EXEC SP_MonitorarDesempenhoConsultas 
--      @TipoMonitoramento = 'EXPENSIVE',
--      @DuracaoMinima = 5000,
--      @TopQuantidade = 10,
--      @IncluirPlanoExecucao = 1
-- 
-- EXEC SP_MonitorarDesempenhoConsultas 
--      @TipoMonitoramento = 'BLOCKED',
--      @IncluirTextoConsulta = 1
-- 
-- EXEC SP_MonitorarDesempenhoConsultas 
--      @TipoMonitoramento = 'LONG_RUNNING',
--      @DuracaoMinima = 30000
-- 
-- EXEC SP_MonitorarDesempenhoConsultas 
--      @TipoMonitoramento = 'FREQUENT',
--      @TopQuantidade = 50 