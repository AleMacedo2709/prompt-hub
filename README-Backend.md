# Guia de Replicação do Backend

Este guia fornece instruções detalhadas para replicar a estrutura do backend em um novo projeto.

## Índice

1. [Estrutura de Projetos](#1-estrutura-de-projetos)
2. [Pacotes NuGet](#2-pacotes-nuget)
3. [Arquivos de Configuração](#3-arquivos-de-configuração)
4. [Classes Base](#4-classes-base)
5. [Scripts de Banco de Dados](#5-scripts-de-banco-de-dados)
6. [Implementação de Repositórios](#6-implementação-de-repositórios)
7. [Configuração do Startup](#7-configuração-do-startup)
8. [Considerações de Segurança](#8-considerações-de-segurança)
9. [Boas Práticas](#9-boas-práticas)
10. [Próximos Passos](#10-próximos-passos)

## 1. Estrutura de Projetos

Crie uma nova solution com os seguintes projetos:

```
NovoSistema.sln
├── NovoSistema.Domain
├── NovoSistema.DataAccess
├── NovoSistema.Business
├── NovoSistema.Presentation.Web.Administrativo
├── NovoSistema.Presentation.ViewComponents
└── NovoSistema.Services.WebApi
```

## 2. Pacotes NuGet

### DataAccess:
```xml
<PackageReference Include="Dapper" Version="2.0.123" />
<PackageReference Include="System.Data.SqlClient" Version="4.8.5" />
```

### Presentation.Web.Administrativo:
```xml
<PackageReference Include="Microsoft.AspNetCore.Authentication.AzureAD.UI" />
<PackageReference Include="NLog.Web.AspNetCore" />
```

## 3. Arquivos de Configuração

### appsettings.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=SEUSERVER;Initial Catalog=SeuBanco;Integrated Security=True;MultipleActiveResultSets=True",
    "ArmazenamentoArquivos": "Data Source=SEUSERVER;Initial Catalog=ArmazenamentoArquivos;Integrated Security=True;MultipleActiveResultSets=True"
  },
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "Domain": "seudominio.com",
    "TenantId": "seu-tenant-id",
    "ClientId": "seu-client-id",
    "CallbackPath": "/signin-oidc"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### nlog.config
```xml
<?xml version="1.0" encoding="utf-8"?>
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      autoReload="true"
      throwExceptions="true">
  
  <extensions>
    <add assembly="NLog.Web.AspNetCore"/>
  </extensions>
  
  <targets>
    <target name="logfile" xsi:type="File" fileName="${basedir}/logs/${shortdate}.log" />
    <target name="dataLog" xsi:type="Database" 
            dbProvider="System.Data.SqlClient" 
            connectionString="sua-connection-string">
      <commandText>
        insert into dbo.LogErro (Projeto, Data, Tipo, Mensagem, Username, ServerName, Logger, CallSite, Exception, InformacaoAdicional) 
        values (@Projeto, @Data, @Tipo, @Mensagem, @Username, @ServerName, @Logger, @Callsite, @Exception, @InformacaoAdicional);
      </commandText>
    </target>
  </targets>
</nlog>
```

## 4. Classes Base

### Domain/Logging/ILogger.cs
```csharp
public interface ILogger
{
    void Debug(string message, object additionalInfo = null);
    void Error(string message, object additionalInfo = null, Exception ex = null);
    void Info(string message, object additionalInfo = null);
    void Warning(string message, object additionalInfo = null);
}
```

### DataAccess/EntityClientRepository.cs
```csharp
public abstract class EntityClientRepository
{
    protected EntityClientRepository(string connectionString)
    {
        Connection = new SqlConnection(connectionString);
    }

    public SqlConnection Connection { get; }
}
```

### DataAccess/DefaultRepository.cs
```csharp
public abstract class DefaultRepository
{
    private readonly string _connectionString;
    public ILogger Logger { get; }

    protected DefaultRepository(string connectionString, ILogger logger)
    {
        _connectionString = connectionString;
        Logger = logger;
    }

    protected virtual SqlConnection CriarConexao()
    {
        Logger.Debug("Criando conexão BD", new { ConnectionString = _connectionString });
        return new SqlConnection(_connectionString);
    }

    protected virtual IEnumerable<T> Query<T>(string sql, object parameters = null)
    {
        try
        {
            using (var connection = CriarConexao())
            {
                return connection.Query<T>(sql, parameters, commandTimeout: 180);
            }
        }
        catch (Exception ex)
        {
            Logger.Error($"Falha ao executar comando", null, ex);
            throw;
        }
    }
}
```

## 5. Scripts de Banco de Dados

Veja o arquivo [README-Database.md](README-Database.md) para detalhes sobre a estrutura do banco de dados.

## 6. Implementação de Repositórios

```csharp
public class SeuRepositorio : DefaultRepository
{
    public SeuRepositorio(string connectionString, ILogger logger) 
        : base(connectionString, logger)
    {
    }

    public IEnumerable<SeuTipo> ObterTodos()
    {
        return Query<SeuTipo>("SELECT * FROM SuaTabela WITH (NOLOCK)");
    }

    public SeuTipo ObterPorId(int id)
    {
        return Query<SeuTipo>(
            "SELECT * FROM SuaTabela WITH (NOLOCK) WHERE Id = @Id", 
            new { Id = id }
        ).FirstOrDefault();
    }
}
```

## 7. Configuração do Startup

```csharp
public void ConfigureServices(IServiceCollection services)
{
    // Configurar conexões
    services.AddTransient<ILogger, NLogLogger>();
    
    // Configurar repositórios
    services.AddScoped<ISeuRepositorio, SeuRepositorio>(sp =>
        new SeuRepositorio(
            Configuration.GetConnectionString("DefaultConnection"),
            sp.GetRequiredService<ILogger>()
        )
    );

    // Configurar autenticação Azure AD
    services.AddAuthentication(AzureADDefaults.AuthenticationScheme)
        .AddAzureAD(options => Configuration.Bind("AzureAd", options));

    services.AddControllersWithViews();
}
```

## 8. Considerações de Segurança

1. Nunca armazene senhas ou chaves em texto claro
2. Use sempre autenticação integrada quando possível
3. Implemente HTTPS em todas as APIs
4. Configure corretamente os grupos de AD para controle de acesso
5. Implemente logging de todas as operações críticas

## 9. Boas Práticas

1. Use sempre parâmetros em queries SQL para evitar SQL Injection
2. Implemente timeout adequado nas queries
3. Use transações quando necessário
4. Implemente tratamento de erros adequado
5. Mantenha logs detalhados das operações
6. Use NOLOCK apenas quando apropriado
7. Implemente paginação em consultas que retornam muitos registros

## 10. Próximos Passos

1. Adapte os nomes das tabelas e entidades para seu contexto
2. Configure as connection strings para seus servidores
3. Ajuste as configurações de AD para sua organização
4. Implemente as regras de negócio específicas do seu sistema
5. Configure o pipeline de CI/CD

## Contribuição

Para contribuir com este projeto:

1. Faça um Fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes.