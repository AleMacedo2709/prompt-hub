using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using NovoSistema.Business.Interfaces;
using NovoSistema.Domain.Interfaces;
using NovoSistema.Domain.Models;

namespace NovoSistema.Business.Services
{
    public class PromptService : IPromptService
    {
        private readonly IPromptRepository _promptRepository;
        private readonly ILogger _logger;

        public PromptService(IPromptRepository promptRepository, ILogger logger)
        {
            _promptRepository = promptRepository;
            _logger = logger;
        }

        public async Task<IEnumerable<Prompt>> ObterTodosAsync()
        {
            try
            {
                return await _promptRepository.ObterTodosAsync();
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter todos os prompts", null, ex);
                throw;
            }
        }

        public async Task<IEnumerable<Prompt>> ObterPorCategoriaAsync(string categoriaId)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(categoriaId))
                    throw new ArgumentException("ID da categoria é obrigatório");

                return await _promptRepository.ObterPorCategoriaAsync(categoriaId);
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts por categoria", new { CategoriaId = categoriaId }, ex);
                throw;
            }
        }

        public async Task<IEnumerable<Prompt>> ObterPorUsuarioAsync(int usuarioId)
        {
            try
            {
                return await _promptRepository.ObterPorUsuarioAsync(usuarioId);
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts do usuário", new { UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<IEnumerable<Prompt>> ObterFavoritosDoUsuarioAsync(int usuarioId)
        {
            try
            {
                return await _promptRepository.ObterFavoritosDoUsuarioAsync(usuarioId);
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts favoritos do usuário", new { UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<Prompt> ObterPorIdAsync(string promptId)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(promptId))
                    throw new ArgumentException("ID do prompt é obrigatório");

                return await _promptRepository.ObterPorIdAsync(promptId);
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompt por ID", new { PromptId = promptId }, ex);
                throw;
            }
        }

        public async Task<Prompt> CriarAsync(Prompt prompt, int usuarioId)
        {
            try
            {
                // Validações de negócio
                if (string.IsNullOrWhiteSpace(prompt.Titulo))
                    throw new ArgumentException("O título do prompt é obrigatório");

                if (string.IsNullOrWhiteSpace(prompt.Conteudo))
                    throw new ArgumentException("O conteúdo do prompt é obrigatório");

                if (string.IsNullOrWhiteSpace(prompt.CategoriaId))
                    throw new ArgumentException("A categoria do prompt é obrigatória");

                // Configurar dados iniciais
                prompt.UsuarioCriadorId = usuarioId;
                prompt.Status = "pending";
                prompt.DataCriacao = DateTime.Now;

                // Criar o prompt
                var novoPrompt = await _promptRepository.CriarAsync(prompt);
                _logger.Info("Prompt criado com sucesso", new { PromptId = novoPrompt.PromptId });

                return novoPrompt;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao criar prompt", new { UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> AtualizarAsync(Prompt prompt, int usuarioId)
        {
            try
            {
                // Validar permissão
                if (!await ValidarPermissaoEdicaoAsync(prompt.PromptId, usuarioId))
                    throw new UnauthorizedAccessException("Usuário não tem permissão para editar este prompt");

                // Validações de negócio
                if (string.IsNullOrWhiteSpace(prompt.Titulo))
                    throw new ArgumentException("O título do prompt é obrigatório");

                if (string.IsNullOrWhiteSpace(prompt.Conteudo))
                    throw new ArgumentException("O conteúdo do prompt é obrigatório");

                if (string.IsNullOrWhiteSpace(prompt.CategoriaId))
                    throw new ArgumentException("A categoria do prompt é obrigatória");

                prompt.DataAtualizacao = DateTime.Now;

                var resultado = await _promptRepository.AtualizarAsync(prompt);
                if (resultado)
                {
                    _logger.Info("Prompt atualizado com sucesso", new { PromptId = prompt.PromptId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao atualizar prompt", new { PromptId = prompt.PromptId, UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> ExcluirAsync(string promptId, int usuarioId)
        {
            try
            {
                // Validar permissão
                if (!await ValidarPermissaoEdicaoAsync(promptId, usuarioId))
                    throw new UnauthorizedAccessException("Usuário não tem permissão para excluir este prompt");

                var resultado = await _promptRepository.ExcluirAsync(promptId);
                if (resultado)
                {
                    _logger.Info("Prompt excluído com sucesso", new { PromptId = promptId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao excluir prompt", new { PromptId = promptId, UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> CurtirAsync(string promptId, int usuarioId)
        {
            try
            {
                var resultado = await _promptRepository.CurtirAsync(promptId, usuarioId);
                if (resultado)
                {
                    _logger.Info("Prompt curtido com sucesso", new { PromptId = promptId, UsuarioId = usuarioId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao curtir prompt", new { PromptId = promptId, UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> DescurtirAsync(string promptId, int usuarioId)
        {
            try
            {
                var resultado = await _promptRepository.DescurtirAsync(promptId, usuarioId);
                if (resultado)
                {
                    _logger.Info("Prompt descurtido com sucesso", new { PromptId = promptId, UsuarioId = usuarioId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao descurtir prompt", new { PromptId = promptId, UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> FavoritarAsync(string promptId, int usuarioId)
        {
            try
            {
                var resultado = await _promptRepository.FavoritarAsync(promptId, usuarioId);
                if (resultado)
                {
                    _logger.Info("Prompt favoritado com sucesso", new { PromptId = promptId, UsuarioId = usuarioId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao favoritar prompt", new { PromptId = promptId, UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> DesfavoritarAsync(string promptId, int usuarioId)
        {
            try
            {
                var resultado = await _promptRepository.DesfavoritarAsync(promptId, usuarioId);
                if (resultado)
                {
                    _logger.Info("Prompt desfavoritado com sucesso", new { PromptId = promptId, UsuarioId = usuarioId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao desfavoritar prompt", new { PromptId = promptId, UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> AprovarAsync(string promptId, int usuarioAprovadorId)
        {
            try
            {
                // Validar permissão
                if (!await ValidarPermissaoAprovacaoAsync(usuarioAprovadorId))
                    throw new UnauthorizedAccessException("Usuário não tem permissão para aprovar prompts");

                // Validar se o prompt existe e está pendente
                var prompt = await _promptRepository.ObterPorIdAsync(promptId);
                if (prompt == null)
                    throw new ArgumentException("Prompt não encontrado");

                if (prompt.Status != "pending")
                    throw new InvalidOperationException("Apenas prompts pendentes podem ser aprovados");

                // Aprovar o prompt
                var resultado = await _promptRepository.AprovarAsync(promptId, usuarioAprovadorId);
                if (resultado)
                {
                    _logger.Info("Prompt aprovado com sucesso", new { PromptId = promptId, AprovadorId = usuarioAprovadorId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao aprovar prompt", new { PromptId = promptId, AprovadorId = usuarioAprovadorId }, ex);
                throw;
            }
        }

        public async Task<bool> RejeitarAsync(string promptId, int usuarioAprovadorId, string motivoRejeicao)
        {
            try
            {
                // Validar permissão
                if (!await ValidarPermissaoAprovacaoAsync(usuarioAprovadorId))
                    throw new UnauthorizedAccessException("Usuário não tem permissão para rejeitar prompts");

                if (string.IsNullOrWhiteSpace(motivoRejeicao))
                    throw new ArgumentException("O motivo da rejeição é obrigatório");

                // Validar se o prompt existe e está pendente
                var prompt = await _promptRepository.ObterPorIdAsync(promptId);
                if (prompt == null)
                    throw new ArgumentException("Prompt não encontrado");

                if (prompt.Status != "pending")
                    throw new InvalidOperationException("Apenas prompts pendentes podem ser rejeitados");

                // Rejeitar o prompt
                var resultado = await _promptRepository.RejeitarAsync(promptId, usuarioAprovadorId, motivoRejeicao);
                if (resultado)
                {
                    _logger.Info("Prompt rejeitado com sucesso", new { PromptId = promptId, AprovadorId = usuarioAprovadorId });
                }

                return resultado;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao rejeitar prompt", new { PromptId = promptId, AprovadorId = usuarioAprovadorId }, ex);
                throw;
            }
        }

        public async Task<IEnumerable<Prompt>> ObterPendentesAprovacaoAsync()
        {
            try
            {
                return await _promptRepository.ObterPendentesAprovacaoAsync();
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts pendentes de aprovação", null, ex);
                throw;
            }
        }

        public async Task<IEnumerable<Prompt>> ObterAprovadosAsync()
        {
            try
            {
                return await _promptRepository.ObterAprovadosAsync();
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts aprovados", null, ex);
                throw;
            }
        }

        public async Task<IEnumerable<Prompt>> PesquisarAsync(string termo, IEnumerable<string> categorias = null)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(termo))
                    throw new ArgumentException("O termo de pesquisa é obrigatório");

                return await _promptRepository.PesquisarAsync(termo, categorias);
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao pesquisar prompts", new { Termo = termo, Categorias = categorias }, ex);
                throw;
            }
        }

        public async Task<bool> ValidarPermissaoEdicaoAsync(string promptId, int usuarioId)
        {
            try
            {
                var prompt = await _promptRepository.ObterPorIdAsync(promptId);
                if (prompt == null)
                    return false;

                // O criador do prompt pode editar
                if (prompt.UsuarioCriadorId == usuarioId)
                    return true;

                // Implementar outras regras de permissão conforme necessário
                return false;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao validar permissão de edição", new { PromptId = promptId, UsuarioId = usuarioId }, ex);
                throw;
            }
        }

        public async Task<bool> ValidarPermissaoAprovacaoAsync(int usuarioId)
        {
            try
            {
                // Implementar lógica de verificação de papel/permissão do usuário
                // Por exemplo, verificar se o usuário tem o papel de Administrador
                // Esta é uma implementação simplificada
                return true;
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao validar permissão de aprovação", new { UsuarioId = usuarioId }, ex);
                throw;
            }
        }
    }
} 