using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Dapper;
using NovoSistema.Domain.Interfaces;
using NovoSistema.Domain.Models;

namespace NovoSistema.DataAccess.Repositories
{
    public class PromptRepository : DefaultRepository, IPromptRepository
    {
        public PromptRepository(string connectionString, ILogger logger) 
            : base(connectionString, logger)
        {
        }

        public async Task<IEnumerable<Prompt>> ObterTodosAsync()
        {
            const string sql = @"
                SELECT p.*, c.Nome as CategoriaNome, u.Nome as UsuarioCriadorNome, u.Avatar as UsuarioCriadorAvatar,
                       (SELECT COUNT(*) FROM dbo.PromptCurtida WHERE PromptId = p.PromptId) as CurtidasCount
                FROM dbo.Prompt p
                INNER JOIN dbo.Categoria c ON p.CategoriaId = c.CategoriaId
                INNER JOIN dbo.Usuario u ON p.UsuarioCriadorId = u.UsuarioId
                WHERE p.Status = 'approved'
                ORDER BY p.DataCriacao DESC";

            using var connection = CriarConexao();
            var prompts = await connection.QueryAsync<Prompt>(sql);
            await CarregarPalavrasChave(prompts, connection);
            return prompts;
        }

        public async Task<IEnumerable<Prompt>> ObterPorCategoriaAsync(string categoriaId)
        {
            const string sql = @"
                SELECT p.*, c.Nome as CategoriaNome, u.Nome as UsuarioCriadorNome, u.Avatar as UsuarioCriadorAvatar,
                       (SELECT COUNT(*) FROM dbo.PromptCurtida WHERE PromptId = p.PromptId) as CurtidasCount
                FROM dbo.Prompt p
                INNER JOIN dbo.Categoria c ON p.CategoriaId = c.CategoriaId
                INNER JOIN dbo.Usuario u ON p.UsuarioCriadorId = u.UsuarioId
                WHERE p.CategoriaId = @CategoriaId AND p.Status = 'approved'
                ORDER BY p.DataCriacao DESC";

            using var connection = CriarConexao();
            var prompts = await connection.QueryAsync<Prompt>(sql, new { CategoriaId = categoriaId });
            await CarregarPalavrasChave(prompts, connection);
            return prompts;
        }

        public async Task<IEnumerable<Prompt>> ObterPorUsuarioAsync(int usuarioId)
        {
            const string sql = @"
                SELECT p.*, c.Nome as CategoriaNome, u.Nome as UsuarioCriadorNome, u.Avatar as UsuarioCriadorAvatar,
                       (SELECT COUNT(*) FROM dbo.PromptCurtida WHERE PromptId = p.PromptId) as CurtidasCount
                FROM dbo.Prompt p
                INNER JOIN dbo.Categoria c ON p.CategoriaId = c.CategoriaId
                INNER JOIN dbo.Usuario u ON p.UsuarioCriadorId = u.UsuarioId
                WHERE p.UsuarioCriadorId = @UsuarioId
                ORDER BY p.DataCriacao DESC";

            using var connection = CriarConexao();
            var prompts = await connection.QueryAsync<Prompt>(sql, new { UsuarioId = usuarioId });
            await CarregarPalavrasChave(prompts, connection);
            return prompts;
        }

        public async Task<Prompt> ObterPorIdAsync(string promptId)
        {
            const string sql = @"
                SELECT p.*, c.Nome as CategoriaNome, u.Nome as UsuarioCriadorNome, u.Avatar as UsuarioCriadorAvatar,
                       (SELECT COUNT(*) FROM dbo.PromptCurtida WHERE PromptId = p.PromptId) as CurtidasCount
                FROM dbo.Prompt p
                INNER JOIN dbo.Categoria c ON p.CategoriaId = c.CategoriaId
                INNER JOIN dbo.Usuario u ON p.UsuarioCriadorId = u.UsuarioId
                WHERE p.PromptId = @PromptId";

            using var connection = CriarConexao();
            var prompt = await connection.QueryFirstOrDefaultAsync<Prompt>(sql, new { PromptId = promptId });
            if (prompt != null)
            {
                await CarregarPalavrasChave(new[] { prompt }, connection);
            }
            return prompt;
        }

        public async Task<Prompt> CriarAsync(Prompt prompt)
        {
            const string sql = @"
                INSERT INTO dbo.Prompt (PromptId, Titulo, Descricao, Conteudo, CategoriaId, Publico, Status, 
                                      UsuarioCriadorId, DataCriacao)
                VALUES (@PromptId, @Titulo, @Descricao, @Conteudo, @CategoriaId, @Publico, @Status,
                        @UsuarioCriadorId, @DataCriacao);
                
                INSERT INTO dbo.PromptPalavraChave (PromptId, PalavraChave)
                SELECT @PromptId, value
                FROM STRING_SPLIT(@PalavrasChave, ',');";

            using var connection = CriarConexao();
            using var transaction = connection.BeginTransaction();

            try
            {
                prompt.PromptId = Guid.NewGuid().ToString();
                await connection.ExecuteAsync(sql, new
                {
                    prompt.PromptId,
                    prompt.Titulo,
                    prompt.Descricao,
                    prompt.Conteudo,
                    prompt.CategoriaId,
                    prompt.Publico,
                    prompt.Status,
                    prompt.UsuarioCriadorId,
                    prompt.DataCriacao,
                    PalavrasChave = string.Join(",", prompt.PalavrasChave)
                }, transaction);

                transaction.Commit();
                return await ObterPorIdAsync(prompt.PromptId);
            }
            catch (Exception ex)
            {
                transaction.Rollback();
                Logger.Error("Erro ao criar prompt", null, ex);
                throw;
            }
        }

        public async Task<bool> CurtirAsync(string promptId, int usuarioId)
        {
            const string sql = @"
                IF NOT EXISTS (SELECT 1 FROM dbo.PromptCurtida WHERE PromptId = @PromptId AND UsuarioId = @UsuarioId)
                BEGIN
                    INSERT INTO dbo.PromptCurtida (PromptId, UsuarioId, DataCurtida)
                    VALUES (@PromptId, @UsuarioId, GETDATE())
                END";

            using var connection = CriarConexao();
            var result = await connection.ExecuteAsync(sql, new { PromptId = promptId, UsuarioId = usuarioId });
            return result > 0;
        }

        public async Task<bool> DescurtirAsync(string promptId, int usuarioId)
        {
            const string sql = @"
                DELETE FROM dbo.PromptCurtida 
                WHERE PromptId = @PromptId AND UsuarioId = @UsuarioId";

            using var connection = CriarConexao();
            var result = await connection.ExecuteAsync(sql, new { PromptId = promptId, UsuarioId = usuarioId });
            return result > 0;
        }

        private async Task CarregarPalavrasChave(IEnumerable<Prompt> prompts, IDbConnection connection)
        {
            if (!prompts.Any()) return;

            const string sql = @"
                SELECT PromptId, PalavraChave
                FROM dbo.PromptPalavraChave
                WHERE PromptId IN @PromptIds";

            var palavrasChave = await connection.QueryAsync<(string PromptId, string PalavraChave)>(
                sql, new { PromptIds = prompts.Select(p => p.PromptId) });

            foreach (var prompt in prompts)
            {
                prompt.PalavrasChave = palavrasChave
                    .Where(pc => pc.PromptId == prompt.PromptId)
                    .Select(pc => pc.PalavraChave)
                    .ToList();
            }
        }

        // Implementar os demais métodos da interface...
    }
} 