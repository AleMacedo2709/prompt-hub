-- Script de Configuração do Ambiente de Produção
-- Data: 2024-03-17
-- Versão: 1.0

USE master
GO

-- Verifica se o banco já existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'JuristPromptsHub_Prod')
BEGIN
    CREATE DATABASE JuristPromptsHub_Prod
    COLLATE Latin1_General_CI_AI
END
GO

USE JuristPromptsHub_Prod
GO

-- Configurações de Alta Disponibilidade
ALTER DATABASE JuristPromptsHub_Prod SET RECOVERY FULL
GO

-- Configurações de Segurança
ALTER DATABASE JuristPromptsHub_Prod SET ENCRYPTION ON
GO

-- Usuário da Aplicação
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'JuristPromptsHub_Prod')
BEGIN
    CREATE LOGIN [JuristPromptsHub_Prod] WITH PASSWORD = N'complex-password-prod'
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'JuristPromptsHub_Prod')
BEGIN
    CREATE USER [JuristPromptsHub_Prod] FOR LOGIN [JuristPromptsHub_Prod]
END
GO

-- Role da Aplicação
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'JuristPromptsHubRole_Prod')
BEGIN
    CREATE ROLE [JuristPromptsHubRole_Prod]
END
GO

-- Permissões
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [JuristPromptsHubRole_Prod]
GO

ALTER ROLE [JuristPromptsHubRole_Prod] ADD MEMBER [JuristPromptsHub_Prod]
GO

-- Configurações de Backup
BACKUP DATABASE JuristPromptsHub_Prod
TO DISK = N'C:\Backup\JuristPromptsHub_Prod.bak'
WITH COMPRESSION, STATS = 10
GO

-- Configurações de Log
BACKUP LOG JuristPromptsHub_Prod
TO DISK = N'C:\Backup\JuristPromptsHub_Prod_Log.bak'
WITH COMPRESSION, STATS = 10
GO

-- Configurações de Auditoria
IF NOT EXISTS (SELECT name FROM sys.server_audits WHERE name = N'JuristPromptsHubAudit_Prod')
BEGIN
    CREATE SERVER AUDIT [JuristPromptsHubAudit_Prod]
    TO FILE
    (
        FILEPATH = N'C:\Audit\Prod\'
        ,MAXSIZE = 500MB
        ,MAX_ROLLOVER_FILES = 50
    )
    WITH
    (
        QUEUE_DELAY = 1000
        ,ON_FAILURE = SHUTDOWN
    )
END
GO

-- Habilita Auditoria
ALTER SERVER AUDIT [JuristPromptsHubAudit_Prod] WITH (STATE = ON)
GO

-- Configurações de Performance
ALTER DATABASE JuristPromptsHub_Prod SET READ_COMMITTED_SNAPSHOT ON
GO

ALTER DATABASE JuristPromptsHub_Prod SET ALLOW_SNAPSHOT_ISOLATION ON
GO

-- Configurações de Manutenção
ALTER DATABASE JuristPromptsHub_Prod SET AUTO_UPDATE_STATISTICS ON
GO

ALTER DATABASE JuristPromptsHub_Prod SET AUTO_UPDATE_STATISTICS_ASYNC ON
GO

-- Configurações de Segurança Adicional
ALTER DATABASE JuristPromptsHub_Prod SET TRUSTWORTHY OFF
GO

ALTER DATABASE JuristPromptsHub_Prod SET DB_CHAINING OFF
GO

-- Configurações de Replicação
EXEC sp_addrolemember N'db_owner', N'JuristPromptsHub_Prod'
GO

-- Configurações de Backup Diferencial
BACKUP DATABASE JuristPromptsHub_Prod
TO DISK = N'C:\Backup\JuristPromptsHub_Prod_Diff.bak'
WITH DIFFERENTIAL, COMPRESSION, STATS = 10
GO

-- Configurações de Always On
ALTER DATABASE JuristPromptsHub_Prod SET HADR AVAILABILITY GROUP = [AG_JuristPromptsHub]
GO

-- Verificação Final
PRINT 'Configuração do ambiente de produção concluída com sucesso!'
GO

-- Verificações de Segurança
SELECT name, is_encrypted FROM sys.databases WHERE name = N'JuristPromptsHub_Prod'
GO

SELECT name, type_desc FROM sys.server_principals WHERE name LIKE N'JuristPromptsHub%'
GO

-- Verificações de Performance
SELECT * FROM sys.dm_db_index_usage_stats WHERE database_id = DB_ID('JuristPromptsHub_Prod')
GO

-- Verificações de Backup
SELECT TOP 10 
    database_name,
    backup_start_date,
    backup_finish_date,
    type
FROM msdb.dbo.backupset
WHERE database_name = N'JuristPromptsHub_Prod'
ORDER BY backup_start_date DESC
GO 