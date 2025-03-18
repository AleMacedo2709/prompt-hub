using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using NovoSistema.Domain.Models;

namespace NovoSistema.Domain.Interfaces
{
    public interface IPromptRepository
    {
        Task<IEnumerable<Prompt>> ObterTodosAsync();
        Task<IEnumerable<Prompt>> ObterPorCategoriaAsync(string categoriaId);
        Task<IEnumerable<Prompt>> ObterPorUsuarioAsync(int usuarioId);
        Task<IEnumerable<Prompt>> ObterFavoritosDoUsuarioAsync(int usuarioId);
        Task<Prompt> ObterPorIdAsync(string promptId);
        Task<Prompt> CriarAsync(Prompt prompt);
        Task<Prompt> AtualizarAsync(Prompt prompt);
        Task<bool> ExcluirAsync(string promptId);
        Task<bool> CurtirAsync(string promptId, int usuarioId);
        Task<bool> DescurtirAsync(string promptId, int usuarioId);
        Task<bool> FavoritarAsync(string promptId, int usuarioId);
        Task<bool> DesfavoritarAsync(string promptId, int usuarioId);
        Task<bool> AprovarAsync(string promptId, int usuarioAprovadorId);
        Task<bool> RejeitarAsync(string promptId, int usuarioAprovadorId);
        Task<IEnumerable<Prompt>> ObterPendentesAprovacaoAsync();
        Task<IEnumerable<Prompt>> ObterAprovadosAsync();
        Task<IEnumerable<Prompt>> PesquisarAsync(string termo, IEnumerable<string> categorias = null);
    }
} 