using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using NovoSistema.DataAccess.Config;

namespace NovoSistema.Services.WebApi
{
    public class Startup
    {
        public IConfiguration Configuration { get; }

        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public void ConfigureServices(IServiceCollection services)
        {
            // ... outros serviços ...
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            using (var scope = app.ApplicationServices.CreateScope())
            {
                var services = scope.ServiceProvider;
                var configuration = services.GetRequiredService<IConfiguration>();
                
                var connectionString = DatabaseConfig.GetConnectionString(configuration);
                
                // Garantir que o banco de dados está criado e atualizado
                DatabaseConfig.EnsureDatabaseCreated(connectionString).Wait();
                
                // Executar migrações pendentes
                DatabaseConfig.ExecuteMigrations(connectionString).Wait();
            }

            // ... resto da configuração ...
        }
    }
} 