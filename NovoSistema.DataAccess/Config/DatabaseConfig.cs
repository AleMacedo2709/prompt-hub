using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Dapper;

namespace NovoSistema.DataAccess.Config
{
    public static class DatabaseConfig
    {
        public static string GetConnectionString(IConfiguration configuration, string name = "DefaultConnection")
        {
            return configuration.GetConnectionString(name);
        }

        public static async Task EnsureDatabaseCreated(string connectionString)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                var scripts = new[]
                {
                    "JuristPromptsHub 2024-03-17 - Criação Inicial das Tabelas.sql",
                    "JuristPromptsHub 2024-03-17 - Dados Iniciais.sql"
                };

                foreach (var script in scripts)
                {
                    var scriptPath = Path.Combine("Database", "Dev", "Scripts", script.StartsWith("JuristPromptsHub") ? "Estrutura" : "Dados", script);
                    if (!File.Exists(scriptPath))
                    {
                        throw new FileNotFoundException($"Script não encontrado: {scriptPath}");
                    }

                    var scriptContent = await File.ReadAllTextAsync(scriptPath);
                    await connection.ExecuteAsync(scriptContent);
                }
            }
        }

        public static async Task ExecuteMigrations(string connectionString)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                var migrationPath = Path.Combine("Database", "Dev", "Migrations");
                if (!Directory.Exists(migrationPath))
                {
                    return;
                }

                var migrationFiles = Directory.GetFiles(migrationPath, "*.sql")
                    .OrderBy(f => f);

                foreach (var migrationFile in migrationFiles)
                {
                    var scriptName = Path.GetFileName(migrationFile);
                    
                    // Verificar se a migração já foi aplicada
                    var alreadyApplied = await connection.QueryFirstOrDefaultAsync<bool>(
                        "SELECT 1 FROM dbo.DatabaseVersion WHERE ScriptName = @ScriptName",
                        new { ScriptName = scriptName });

                    if (!alreadyApplied)
                    {
                        var scriptContent = await File.ReadAllTextAsync(migrationFile);
                        await connection.ExecuteAsync(scriptContent);
                    }
                }
            }
        }
    }
}