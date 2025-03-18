/*
Nome: Configuração de Permissões do Banco de Dados
Data: 2024-03-17
Versão: 1.0
Descrição: Script para configurar permissões necessárias para o JuristPromptsHub
*/

USE [master]
GO

-- Verificar se o banco existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'JuristPromptsHub')
BEGIN
    RAISERROR ('Banco de dados JuristPromptsHub não encontrado!', 16, 1)
    RETURN
END
GO

USE [JuristPromptsHub]
GO

-- Criar role para aplicação
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'JuristPromptsHubRole')
BEGIN
    CREATE ROLE [JuristPromptsHubRole]
END
GO

-- Conceder permissões para a role
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [JuristPromptsHubRole]
GO

-- Permissões específicas para tabelas do sistema
GRANT EXECUTE ON SCHEMA::dbo TO [JuristPromptsHubRole]
GO

-- Criar usuário da aplicação (se não existir)
-- IMPORTANTE: Substituir 'your_username' e 'your_password' por valores seguros
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'JuristPromptsHubUser')
BEGIN
    CREATE USER [JuristPromptsHubUser] FOR LOGIN [JuristPromptsHubUser]
    ALTER ROLE [JuristPromptsHubRole] ADD MEMBER [JuristPromptsHubUser]
END
GO

-- Verificar permissões
SELECT 
    dp.name AS [Usuario],
    dp2.name AS [Role],
    o.name AS [Objeto],
    p.permission_name AS [Permissao]
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.database_principals dp2 ON dp.owning_principal_id = dp2.principal_id
LEFT JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.name IN ('JuristPromptsHubRole', 'JuristPromptsHubUser')
ORDER BY dp.name, o.name, p.permission_name
GO

-- Verificar membros das roles
SELECT 
    DP1.name AS [DatabaseRoleName],
    ISNULL(DP2.name, 'No members') AS [DatabaseUserName]   
FROM sys.database_role_members AS DRM  
RIGHT OUTER JOIN sys.database_principals AS DP1  
    ON DRM.role_principal_id = DP1.principal_id  
LEFT OUTER JOIN sys.database_principals AS DP2  
    ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R'
    AND DP1.name = 'JuristPromptsHubRole'
ORDER BY DP1.name;  
GO

-- Verificar conexão e permissões
BEGIN TRY
    EXECUTE AS USER = 'JuristPromptsHubUser'
    
    -- Tentar operações básicas
    SELECT TOP 1 * FROM dbo.Prompt
    
    -- Voltar para o contexto original
    REVERT
    
    PRINT 'Teste de permissões concluído com sucesso!'
END TRY
BEGIN CATCH
    PRINT 'Erro ao testar permissões: ' + ERROR_MESSAGE()
    
    -- Garantir que voltamos ao contexto original
    IF EXISTS (SELECT * FROM sys.user_token)
        REVERT
END CATCH
GO 