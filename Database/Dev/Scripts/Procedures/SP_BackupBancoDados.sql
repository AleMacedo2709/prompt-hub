-- Stored Procedure: Backup do Banco de Dados
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_BackupBancoDados')
    DROP PROCEDURE SP_BackupBancoDados
GO

CREATE PROCEDURE SP_BackupBancoDados
    @BackupType VARCHAR(10) = 'FULL',      -- FULL, DIFF, LOG
    @BackupPath VARCHAR(256) = NULL,       -- Caminho personalizado para backup
    @Compress BIT = 1,                     -- Usar compressão
    @Verify BIT = 1,                       -- Verificar backup após conclusão
    @CopyOnly BIT = 0,                     -- Backup copy-only
    @Init BIT = 0                          -- Sobrescrever mídia existente
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatabaseName NVARCHAR(128) = DB_NAME()
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @BackupFile NVARCHAR(512)
    DECLARE @BackupName NVARCHAR(256)
    DECLARE @Description NVARCHAR(512)
    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @SQL NVARCHAR(MAX)

    -- Tabela temporária para log de backup
    CREATE TABLE #BackupLog
    (
        LogId INT IDENTITY(1,1),
        BackupType VARCHAR(10),
        StartTime DATETIME,
        EndTime DATETIME,
        BackupFile NVARCHAR(512),
        BackupSize BIGINT,
        Status VARCHAR(20),
        Message NVARCHAR(MAX)
    )

    BEGIN TRY
        -- Verifica se o banco está online
        IF (SELECT state_desc FROM sys.databases WHERE name = @DatabaseName) != 'ONLINE'
        BEGIN
            RAISERROR ('Database is not online. Backup canceled.', 16, 1)
            RETURN
        END

        -- Define caminho padrão se não fornecido
        IF @BackupPath IS NULL
        BEGIN
            SET @BackupPath = 'C:\Backup\' + @DatabaseName + '\'
            -- Cria diretório se não existir
            EXEC master.dbo.xp_create_subdir @BackupPath
        END

        -- Define nome do arquivo de backup
        SET @BackupFile = @BackupPath + @DatabaseName + '_' + 
                         CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +
                         REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '') + '_' +
                         @BackupType + '.bak'

        -- Define nome e descrição do backup
        SET @BackupName = @DatabaseName + '-' + @BackupType + ' Backup-' + 
                         CONVERT(VARCHAR(20), GETDATE(), 120)
        SET @Description = 'Backup ' + @BackupType + ' do banco ' + @DatabaseName + 
                         ' criado em ' + CONVERT(VARCHAR(20), GETDATE(), 120)

        -- Constrói comando de backup base
        SET @SQL = 'BACKUP ' + 
                  CASE @BackupType 
                      WHEN 'FULL' THEN 'DATABASE'
                      WHEN 'DIFF' THEN 'DATABASE'
                      WHEN 'LOG' THEN 'LOG'
                  END + ' ' +
                  QUOTENAME(@DatabaseName) + ' TO DISK = ''' + @BackupFile + ''''

        -- Adiciona opções de backup
        SET @SQL = @SQL + ' WITH '
        
        -- Tipo de backup diferencial
        IF @BackupType = 'DIFF'
            SET @SQL = @SQL + 'DIFFERENTIAL, '

        -- Compressão
        IF @Compress = 1
            SET @SQL = @SQL + 'COMPRESSION, '

        -- Copy-only
        IF @CopyOnly = 1
            SET @SQL = @SQL + 'COPY_ONLY, '

        -- Init/NoInit
        IF @Init = 1
            SET @SQL = @SQL + 'INIT, '
        ELSE
            SET @SQL = @SQL + 'NOINIT, '

        -- Nome e descrição
        SET @SQL = @SQL + 'NAME = ''' + @BackupName + ''', ' +
                         'DESCRIPTION = ''' + @Description + ''', ' +
                         'STATS = 10'

        -- Registra início do backup
        INSERT INTO #BackupLog (BackupType, StartTime, BackupFile, Status, Message)
        VALUES (@BackupType, @StartTime, @BackupFile, 'IN_PROGRESS', 'Starting backup...')

        -- Executa backup
        EXEC sp_executesql @SQL

        -- Verifica backup se solicitado
        IF @Verify = 1
        BEGIN
            SET @SQL = 'RESTORE VERIFYONLY FROM DISK = ''' + @BackupFile + ''''
            EXEC sp_executesql @SQL
        END

        -- Obtém tamanho do arquivo de backup
        DECLARE @BackupSize BIGINT
        SELECT @BackupSize = backup_size
        FROM msdb.dbo.backupset
        WHERE database_name = @DatabaseName
        AND backup_start_date = (
            SELECT MAX(backup_start_date)
            FROM msdb.dbo.backupset
            WHERE database_name = @DatabaseName
        )

        -- Atualiza log com sucesso
        UPDATE #BackupLog
        SET EndTime = GETDATE(),
            BackupSize = @BackupSize,
            Status = 'SUCCESS',
            Message = 'Backup completed successfully. ' +
                     'Size: ' + CAST(@BackupSize/1024/1024 AS VARCHAR) + ' MB. ' +
                     CASE WHEN @Verify = 1 THEN 'Backup verified.' ELSE '' END
        WHERE LogId = SCOPE_IDENTITY()

        -- Retorna informações do backup
        SELECT 
            BackupType,
            StartTime,
            EndTime,
            DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
            BackupFile,
            BackupSize/1024/1024 AS BackupSizeMB,
            Status,
            Message
        FROM #BackupLog

        -- Limpa tabela temporária
        DROP TABLE #BackupLog

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Registra erro no log
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#BackupLog%')
        BEGIN
            UPDATE #BackupLog
            SET EndTime = GETDATE(),
                Status = 'FAILED',
                Message = @ErrorMessage
            WHERE LogId = SCOPE_IDENTITY()

            -- Retorna informações do backup com falha
            SELECT 
                BackupType,
                StartTime,
                EndTime,
                DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
                BackupFile,
                BackupSize/1024/1024 AS BackupSizeMB,
                Status,
                Message
            FROM #BackupLog

            DROP TABLE #BackupLog
        END

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_BackupBancoDados TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_BackupBancoDados -- Backup FULL com configurações padrão
-- EXEC SP_BackupBancoDados @BackupType = 'DIFF' -- Backup diferencial
-- EXEC SP_BackupBancoDados @BackupType = 'LOG' -- Backup de log
-- EXEC SP_BackupBancoDados @BackupPath = 'D:\Backup\Custom\' -- Caminho personalizado
-- EXEC SP_BackupBancoDados @Compress = 0, @Verify = 0 -- Sem compressão e sem verificação 