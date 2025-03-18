-- Script de Configuração do Ambiente de Homologação
-- Data: 2024-03-17
-- Versão: 1.0

USE master
GO

-- Verifica se o banco já existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'JuristPromptsHub_Hom')
BEGIN
    CREATE DATABASE JuristPromptsHub_Hom
    COLLATE Latin1_General_CI_AI
END
GO

USE JuristPromptsHub_Hom
GO

-- Configurações de Segurança
ALTER DATABASE JuristPromptsHub_Hom SET ENCRYPTION ON
GO

-- Usuário da Aplicação
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'JuristPromptsHub_Hom')
BEGIN
    CREATE LOGIN [JuristPromptsHub_Hom] WITH PASSWORD = N'complex-password-hom'
END
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'JuristPromptsHub_Hom')
BEGIN
    CREATE USER [JuristPromptsHub_Hom] FOR LOGIN [JuristPromptsHub_Hom]
END
GO

-- Role da Aplicação
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'JuristPromptsHubRole_Hom')
BEGIN
    CREATE ROLE [JuristPromptsHubRole_Hom]
END
GO

-- Permissões
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [JuristPromptsHubRole_Hom]
GO

ALTER ROLE [JuristPromptsHubRole_Hom] ADD MEMBER [JuristPromptsHub_Hom]
GO

-- Configurações de Backup
BACKUP DATABASE JuristPromptsHub_Hom
TO DISK = N'C:\Backup\JuristPromptsHub_Hom.bak'
WITH COMPRESSION, STATS = 10
GO

-- Configurações de Auditoria
IF NOT EXISTS (SELECT name FROM sys.server_audits WHERE name = N'JuristPromptsHubAudit_Hom')
BEGIN
    CREATE SERVER AUDIT [JuristPromptsHubAudit_Hom]
    TO FILE
    (
        FILEPATH = N'C:\Audit\Hom\'
        ,MAXSIZE = 100MB
        ,MAX_ROLLOVER_FILES = 10
    )
    WITH
    (
        QUEUE_DELAY = 1000
        ,ON_FAILURE = CONTINUE
    )
END
GO

-- Habilita Auditoria
ALTER SERVER AUDIT [JuristPromptsHubAudit_Hom] WITH (STATE = ON)
GO

-- Configurações de Performance
ALTER DATABASE JuristPromptsHub_Hom SET READ_COMMITTED_SNAPSHOT ON
GO

ALTER DATABASE JuristPromptsHub_Hom SET ALLOW_SNAPSHOT_ISOLATION ON
GO

-- Configurações de Manutenção
ALTER DATABASE JuristPromptsHub_Hom SET AUTO_UPDATE_STATISTICS ON
GO

ALTER DATABASE JuristPromptsHub_Hom SET AUTO_UPDATE_STATISTICS_ASYNC ON
GO

-- Verificação Final
PRINT 'Configuração do ambiente de homologação concluída com sucesso!'
GO 