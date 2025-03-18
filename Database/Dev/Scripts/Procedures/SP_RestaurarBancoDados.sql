-- Stored Procedure: Restauração do Banco de Dados
-- Data: 2024-03-17
-- Versão: 1.0

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_RestaurarBancoDados')
    DROP PROCEDURE SP_RestaurarBancoDados
GO

CREATE PROCEDURE SP_RestaurarBancoDados
    @BackupFile NVARCHAR(512),           -- Arquivo de backup a ser restaurado
    @NewDatabaseName NVARCHAR(128) = NULL, -- Nome do novo banco (NULL para sobrescrever existente)
    @DataFilePath NVARCHAR(512) = NULL,  -- Caminho para arquivo de dados
    @LogFilePath NVARCHAR(512) = NULL,   -- Caminho para arquivo de log
    @StandBy NVARCHAR(512) = NULL,       -- Arquivo standby para restore with standby
    @StopAt DATETIME = NULL,             -- Ponto no tempo para restore
    @Verify BIT = 1,                     -- Verificar backup antes de restaurar
    @ReplaceExisting BIT = 0             -- Sobrescrever banco existente
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatabaseName NVARCHAR(128)
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @StartTime DATETIME = GETDATE()

    -- Tabela temporária para log de restauração
    CREATE TABLE #RestoreLog
    (
        LogId INT IDENTITY(1,1),
        StartTime DATETIME,
        EndTime DATETIME,
        SourceFile NVARCHAR(512),
        TargetDatabase NVARCHAR(128),
        Status VARCHAR(20),
        Message NVARCHAR(MAX)
    )

    BEGIN TRY
        -- Verifica se o arquivo de backup existe
        IF NOT EXISTS (SELECT 1 FROM sys.dm_os_file_exists(@BackupFile))
        BEGIN
            RAISERROR ('Backup file does not exist.', 16, 1)
            RETURN
        END

        -- Verifica backup se solicitado
        IF @Verify = 1
        BEGIN
            INSERT INTO #RestoreLog (StartTime, SourceFile, Status, Message)
            VALUES (GETDATE(), @BackupFile, 'VERIFYING', 'Verifying backup file...')

            SET @SQL = 'RESTORE VERIFYONLY FROM DISK = ''' + @BackupFile + ''''
            EXEC sp_executesql @SQL

            UPDATE #RestoreLog
            SET EndTime = GETDATE(),
                Status = 'VERIFIED',
                Message = 'Backup file verified successfully.'
            WHERE LogId = SCOPE_IDENTITY()
        END

        -- Obtém informações do backup
        DECLARE @BackupHeader TABLE
        (
            BackupName NVARCHAR(128),
            BackupDescription NVARCHAR(255),
            ServerName NVARCHAR(128),
            DatabaseName NVARCHAR(128),
            BackupStartDate DATETIME,
            BackupFinishDate DATETIME,
            BackupType CHAR(1),
            BackupSize NUMERIC(20,0),
            FirstLSN NUMERIC(25,0),
            LastLSN NUMERIC(25,0),
            CheckpointLSN NUMERIC(25,0),
            DatabaseBackupLSN NUMERIC(25,0),
            IsPasswordProtected BIT,
            RecoveryModel NVARCHAR(60),
            HasBulkLoggedData BIT,
            IsCopyOnly BIT
        )

        INSERT INTO @BackupHeader
        EXEC('RESTORE HEADERONLY FROM DISK = ''' + @BackupFile + '''')

        -- Define nome do banco de destino
        SELECT @DatabaseName = ISNULL(@NewDatabaseName, DatabaseName)
        FROM @BackupHeader

        -- Obtém informações dos arquivos do backup
        DECLARE @BackupFiles TABLE
        (
            LogicalName NVARCHAR(128),
            PhysicalName NVARCHAR(512),
            Type CHAR(1),
            FileGroupName NVARCHAR(128),
            Size NUMERIC(20,0),
            MaxSize NUMERIC(20,0),
            FileID BIGINT,
            CreateLSN NUMERIC(25,0),
            DropLSN NUMERIC(25,0),
            UniqueID UNIQUEIDENTIFIER,
            ReadOnlyLSN NUMERIC(25,0),
            ReadWriteLSN NUMERIC(25,0),
            BackupSizeInBytes BIGINT,
            SourceBlockSize INT,
            FileGroupID INT,
            LogGroupGUID UNIQUEIDENTIFIER,
            DifferentialBaseLSN NUMERIC(25,0),
            DifferentialBaseGUID UNIQUEIDENTIFIER,
            IsReadOnly BIT,
            IsPresent BIT
        )

        INSERT INTO @BackupFiles
        EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFile + '''')

        -- Constrói comando de restore
        SET @SQL = 'RESTORE DATABASE ' + QUOTENAME(@DatabaseName) + 
                  ' FROM DISK = ''' + @BackupFile + ''' WITH '

        -- Adiciona MOVE para cada arquivo se caminhos fornecidos
        IF @DataFilePath IS NOT NULL OR @LogFilePath IS NOT NULL
        BEGIN
            DECLARE @Moves NVARCHAR(MAX) = ''
            SELECT @Moves = @Moves + 
                          'MOVE ''' + LogicalName + ''' TO ''' + 
                          CASE Type 
                              WHEN 'D' THEN ISNULL(@DataFilePath, PhysicalName)
                              WHEN 'L' THEN ISNULL(@LogFilePath, PhysicalName)
                          END + ''', '
            FROM @BackupFiles
            SET @SQL = @SQL + @Moves
        END

        -- Adiciona opções adicionais
        IF @ReplaceExisting = 1
            SET @SQL = @SQL + 'REPLACE, '

        IF @StandBy IS NOT NULL
            SET @SQL = @SQL + 'STANDBY = ''' + @StandBy + ''', '

        IF @StopAt IS NOT NULL
            SET @SQL = @SQL + 'STOPAT = ''' + CONVERT(VARCHAR, @StopAt, 121) + ''', '

        SET @SQL = @SQL + 'STATS = 10'

        -- Registra início da restauração
        INSERT INTO #RestoreLog (StartTime, SourceFile, TargetDatabase, Status, Message)
        VALUES (GETDATE(), @BackupFile, @DatabaseName, 'IN_PROGRESS', 'Starting database restore...')

        -- Executa restauração
        EXEC sp_executesql @SQL

        -- Atualiza log com sucesso
        UPDATE #RestoreLog
        SET EndTime = GETDATE(),
            Status = 'SUCCESS',
            Message = 'Database restored successfully. ' +
                     'Source: ' + @BackupFile + ' ' +
                     'Target: ' + @DatabaseName
        WHERE LogId = SCOPE_IDENTITY()

        -- Retorna informações da restauração
        SELECT 
            StartTime,
            EndTime,
            DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
            SourceFile,
            TargetDatabase,
            Status,
            Message
        FROM #RestoreLog
        ORDER BY LogId

        -- Limpa tabela temporária
        DROP TABLE #RestoreLog

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        -- Registra erro no log
        IF EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE name LIKE '#RestoreLog%')
        BEGIN
            UPDATE #RestoreLog
            SET EndTime = GETDATE(),
                Status = 'FAILED',
                Message = @ErrorMessage
            WHERE LogId = SCOPE_IDENTITY()

            -- Retorna informações da restauração com falha
            SELECT 
                StartTime,
                EndTime,
                DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
                SourceFile,
                TargetDatabase,
                Status,
                Message
            FROM #RestoreLog
            ORDER BY LogId

            DROP TABLE #RestoreLog
        END

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

-- Adiciona permissão de execução para a role da aplicação
GRANT EXECUTE ON SP_RestaurarBancoDados TO [JuristPromptsHubRole]
GO

-- Exemplo de uso:
-- EXEC SP_RestaurarBancoDados 
--      @BackupFile = 'C:\Backup\JuristPromptsHub\JuristPromptsHub_20240317_235959_FULL.bak'
-- 
-- EXEC SP_RestaurarBancoDados 
--      @BackupFile = 'C:\Backup\JuristPromptsHub\JuristPromptsHub_20240317_235959_FULL.bak',
--      @NewDatabaseName = 'JuristPromptsHub_Dev',
--      @DataFilePath = 'D:\Data\',
--      @LogFilePath = 'E:\Log\'
-- 
-- EXEC SP_RestaurarBancoDados 
--      @BackupFile = 'C:\Backup\JuristPromptsHub\JuristPromptsHub_20240317_235959_FULL.bak',
--      @StandBy = 'C:\Temp\JuristPromptsHub_Standby.txt'
-- 
-- EXEC SP_RestaurarBancoDados 
--      @BackupFile = 'C:\Backup\JuristPromptsHub\JuristPromptsHub_20240317_235959_FULL.bak',
--      @ReplaceExisting = 1 