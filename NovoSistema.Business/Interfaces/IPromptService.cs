using System.Collections.Generic;
using System.Threading.Tasks;
using NovoSistema.Domain.Models;

namespace NovoSistema.Business.Interfaces
{
    public interface IPromptService
    {
        Task<IEnumerable<Prompt>> ObterTodosAsync();
        Task<IEnumerable<Prompt>> ObterPorCategoriaAsync(string categoriaId);
        Task<IEnumerable<Prompt>> ObterPorUsuarioAsync(int usuarioId);
        Task<IEnumerable<Prompt>> ObterFavoritosDoUsuarioAsync(int usuarioId);
        Task<Prompt> ObterPorIdAsync(string promptId);
        Task<Prompt> CriarAsync(Prompt prompt, int usuarioId);
        Task<Prompt> AtualizarAsync(Prompt prompt, int usuarioId);
        Task<bool> ExcluirAsync(string promptId, int usuarioId);
        Task<bool> CurtirAsync(string promptId, int usuarioId);
        Task<bool> DescurtirAsync(string promptId, int usuarioId);
        Task<bool> FavoritarAsync(string promptId, int usuarioId);
        Task<bool> DesfavoritarAsync(string promptId, int usuarioId);
        Task<bool> AprovarAsync(string promptId, int usuarioAprovadorId);
        Task<bool> RejeitarAsync(string promptId, int usuarioAprovadorId, string motivoRejeicao);
        Task<IEnumerable<Prompt>> ObterPendentesAprovacaoAsync();
        Task<IEnumerable<Prompt>> ObterAprovadosAsync();
        Task<IEnumerable<Prompt>> PesquisarAsync(string termo, IEnumerable<string> categorias = null);
        Task<bool> ValidarPermissaoEdicaoAsync(string promptId, int usuarioId);
        Task<bool> ValidarPermissaoAprovacaoAsync(int usuarioId);
    }
}