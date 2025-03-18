-- Stored Procedure: Verificar Saúde do Banco de Dados
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_VerificarSaudeBancoDados')
    DROP PROCEDURE SP_VerificarSaudeBancoDados
GO

CREATE PROCEDURE SP_VerificarSaudeBancoDados
    @DetailLevel INT = 1 -- 1 = Basic, 2 = Detailed, 3 = Full
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabela temporária para resultados
    CREATE TABLE #HealthCheckResults
    (
        CheckId INT IDENTITY(1,1),
        Category VARCHAR(50),
        CheckName VARCHAR(100),
        Status VARCHAR(20),
        Details NVARCHAR(MAX),
        Recommendation NVARCHAR(MAX)
    )

    -- 1. Verificação de Espaço em Disco
    INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
    SELECT 
        'Storage',
        'Database Space',
        CASE 
            WHEN CAST(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS DECIMAL(15,2)) < 1024 
            THEN 'Warning' 
            ELSE 'OK' 
        END,
        'Free space (MB): ' + CAST(CAST(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS DECIMAL(15,2)) AS VARCHAR),
        CASE 
            WHEN CAST(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS DECIMAL(15,2)) < 1024 
            THEN 'Consider adding more space to the database files'
            ELSE 'No action needed'
        END
    FROM sys.database_files
    WHERE type_desc = 'ROWS'

    -- 2. Verificação de Índices Fragmentados
    IF @DetailLevel >= 2
    BEGIN
        INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
        SELECT TOP 10
            'Performance',
            'Fragmented Indexes',
            CASE 
                WHEN avg_fragmentation_in_percent > 30 THEN 'Critical'
                WHEN avg_fragmentation_in_percent > 10 THEN 'Warning'
                ELSE 'OK'
            END,
            'Table: ' + OBJECT_NAME(ips.object_id) + 
            ', Index: ' + i.name + 
            ', Fragmentation: ' + CAST(avg_fragmentation_in_percent AS VARCHAR) + '%',
            CASE 
                WHEN avg_fragmentation_in_percent > 30 THEN 'Rebuild index'
                WHEN avg_fragmentation_in_percent > 10 THEN 'Reorganize index'
                ELSE 'No action needed'
            END
        FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
        JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
        WHERE avg_fragmentation_in_percent > 10
        ORDER BY avg_fragmentation_in_percent DESC
    END

    -- 3. Verificação de Estatísticas Desatualizadas
    IF @DetailLevel >= 2
    BEGIN
        INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
        SELECT TOP 10
            'Performance',
            'Statistics Status',
            CASE 
                WHEN DATEDIFF(DAY, stats_date, GETDATE()) > 7 THEN 'Warning'
                ELSE 'OK'
            END,
            'Table: ' + OBJECT_NAME(id) + 
            ', Statistics: ' + name + 
            ', Last Updated: ' + CONVERT(VARCHAR, stats_date, 120),
            CASE 
                WHEN DATEDIFF(DAY, stats_date, GETDATE()) > 7 
                THEN 'Update statistics'
                ELSE 'No action needed'
            END
        FROM sys.stats CROSS APPLY sys.dm_db_stats_properties(object_id, stats_id)
        WHERE DATEDIFF(DAY, stats_date, GETDATE()) > 7
        ORDER BY stats_date ASC
    END

    -- 4. Verificação de Deadlocks
    IF @DetailLevel >= 2
    BEGIN
        INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
        SELECT 
            'Performance',
            'Deadlocks',
            CASE 
                WHEN COUNT(*) > 0 THEN 'Warning'
                ELSE 'OK'
            END,
            'Number of deadlocks in last hour: ' + CAST(COUNT(*) AS VARCHAR),
            CASE 
                WHEN COUNT(*) > 0 THEN 'Investigate deadlock graphs in system_health session'
                ELSE 'No action needed'
            END
        FROM sys.dm_xe_session_targets st
        JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
        WHERE s.name = 'system_health'
        AND CAST(target_data AS XML).value('(RingBufferTarget/event[@name="xml_deadlock_report"][1]/@timestamp)[1]', 'datetime') > DATEADD(HOUR, -1, GETDATE())
    END

    -- 5. Verificação de Conexões
    INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
    SELECT 
        'Connections',
        'Active Connections',
        CASE 
            WHEN COUNT(*) > 100 THEN 'Warning'
            ELSE 'OK'
        END,
        'Number of active connections: ' + CAST(COUNT(*) AS VARCHAR),
        CASE 
            WHEN COUNT(*) > 100 THEN 'Investigate connection pooling settings'
            ELSE 'No action needed'
        END
    FROM sys.dm_exec_sessions
    WHERE is_user_process = 1

    -- 6. Verificação de Backup
    INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
    SELECT TOP 1
        'Backup',
        'Last Backup',
        CASE 
            WHEN DATEDIFF(HOUR, backup_finish_date, GETDATE()) > 24 THEN 'Critical'
            WHEN DATEDIFF(HOUR, backup_finish_date, GETDATE()) > 12 THEN 'Warning'
            ELSE 'OK'
        END,
        'Last backup: ' + CONVERT(VARCHAR, backup_finish_date, 120),
        CASE 
            WHEN DATEDIFF(HOUR, backup_finish_date, GETDATE()) > 24 THEN 'Perform full backup immediately'
            WHEN DATEDIFF(HOUR, backup_finish_date, GETDATE()) > 12 THEN 'Schedule backup soon'
            ELSE 'No action needed'
        END
    FROM msdb.dbo.backupset
    WHERE database_name = DB_NAME()
    ORDER BY backup_finish_date DESC

    -- 7. Verificação de Logs de Erro
    IF @DetailLevel >= 3
    BEGIN
        INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
        SELECT TOP 10
            'Errors',
            'Recent Errors',
            'Warning',
            'Error: ' + CAST(ERROR_NUMBER AS VARCHAR) + 
            ' at ' + CONVERT(VARCHAR, ERROR_TIME, 120) + 
            ': ' + ERROR_MESSAGE,
            'Investigate error patterns'
        FROM sys.dm_db_error_log
        WHERE ERROR_TIME > DATEADD(HOUR, -24, GETDATE())
        ORDER BY ERROR_TIME DESC
    END

    -- 8. Verificação de Jobs Falhos (se for SQL Server Agent)
    IF @DetailLevel >= 2
    BEGIN
        INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
        SELECT TOP 5
            'Jobs',
            'Failed Jobs',
            'Warning',
            'Job: ' + j.name + 
            ', Last Run: ' + CONVERT(VARCHAR, jh.run_date, 120) + 
            ', Status: ' + CAST(jh.run_status AS VARCHAR),
            'Review job history and fix issues'
        FROM msdb.dbo.sysjobs j
        JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id
        WHERE jh.run_status = 0 -- Failed
        AND jh.run_date > DATEADD(DAY, -1, GETDATE())
        ORDER BY jh.run_date DESC
    END

    -- 9. Verificação de Permissões
    IF @DetailLevel >= 3
    BEGIN
        INSERT INTO #HealthCheckResults (Category, CheckName, Status, Details, Recommendation)
        SELECT DISTINCT
            'Security',
            'Database Permissions',
            CASE 
                WHEN dp.type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP') 
                AND dp.authentication_type_desc = 'NONE' 
                THEN 'Warning'
                ELSE 'OK'
            END,
            'Principal: ' + dp.name + 
            ', Type: ' + dp.type_desc + 
            ', Authentication: ' + ISNULL(dp.authentication_type_desc, 'N/A'),
            CASE 
                WHEN dp.type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP') 
                AND dp.authentication_type_desc = 'NONE' 
                THEN 'Review orphaned users'
                ELSE 'No action needed'
            END
        FROM sys.database_principals dp
        WHERE dp.type_desc IN ('SQL_USER', 'WINDOWS_USER', 'WINDOWS_GROUP')
    END

    -- Retorna resultados
    SELECT 
        CheckId,
        Category,
        CheckName,
        Status,
        Details,
        Recommendation
    FROM #HealthCheckResults
    ORDER BY 
        CASE Status
            WHEN 'Critical' THEN 1
            WHEN 'Warning' THEN 2
            WHEN 'OK' THEN 3
            ELSE 4
        END,
        Category,
        CheckName

    -- Limpa tabela temporária
    DROP TABLE #HealthCheckResults
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_VerificarSaudeBancoDados TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_VerificarSaudeBancoDados @DetailLevel = 1 -- Basic
-- EXEC SP_VerificarSaudeBancoDados @DetailLevel = 2 -- Detailed
-- EXEC SP_VerificarSaudeBancoDados @DetailLevel = 3 -- Full 