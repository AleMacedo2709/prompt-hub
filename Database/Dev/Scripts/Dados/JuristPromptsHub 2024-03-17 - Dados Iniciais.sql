/*
Nome: Dados Iniciais
Data: 2024-03-17
Versão: 1.0
Descrição: Inserção de dados iniciais do sistema
*/

USE JuristPromptsHub;
GO

-- Inserção de Configurações Básicas
INSERT INTO dbo.Configuracoes (Area, Chave, Valor, Descricao)
VALUES 
    ('Sistema', 'VersaoAtual', '1.0.0', 'Versão atual do sistema'),
    ('Sistema', 'NomeInstituicao', 'Ministério Público Estadual', 'Nome da instituição'),
    ('Sistema', 'UrlBase', 'https://juristpromptshub.mp.gov.br', 'URL base do sistema'),
    ('Email', 'ServidorSMTP', 'smtp.mp.gov.br', 'Servidor de email'),
    ('Email', 'PortaSMTP', '587', 'Porta do servidor de email'),
    ('Email', 'UsarSSL', 'true', 'Usar SSL para conexão SMTP'),
    ('Email', 'RemetenteNome', 'Jurist Prompts Hub', 'Nome do remetente de emails'),
    ('Email', 'RemetenteEmail', 'noreply@mp.gov.br', 'Email do remetente');
GO

-- Inserção de Categorias
INSERT INTO dbo.Categoria (CategoriaId, Nome, Descricao)
VALUES 
    ('criminal', 'Direito Criminal', 'Prompts relacionados à área criminal'),
    ('civil', 'Direito Civil', 'Prompts relacionados à área cível'),
    ('family', 'Direito de Família', 'Prompts relacionados ao direito de família'),
    ('consumer', 'Direito do Consumidor', 'Prompts relacionados ao direito do consumidor'),
    ('administrative', 'Direito Administrativo', 'Prompts relacionados ao direito administrativo'),
    ('constitutional', 'Direito Constitucional', 'Prompts relacionados ao direito constitucional'),
    ('environmental', 'Direito Ambiental', 'Prompts relacionados ao direito ambiental'),
    ('labor', 'Direito do Trabalho', 'Prompts relacionados ao direito do trabalho'),
    ('election', 'Direito Eleitoral', 'Prompts relacionados ao direito eleitoral'),
    ('tax', 'Direito Tributário', 'Prompts relacionados ao direito tributário');
GO

-- Inserção de Usuário Administrador Inicial
INSERT INTO dbo.Usuario (Nome, Email, Cargo, Unidade, Localizacao, Ativo)
VALUES 
    ('Administrador do Sistema', 'admin@mp.gov.br', 'Administrador', 'TI', 'Sede', 1);
GO

-- Registro da Versão Inicial do Banco
INSERT INTO dbo.DatabaseVersion (VersionNumber, ScriptName)
VALUES ('1.0.0', '02_InitialData.sql');
GO 