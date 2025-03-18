using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NovoSistema.Domain.Interfaces;
using NovoSistema.Domain.Models;
using NovoSistema.Services.WebApi.Models;

namespace NovoSistema.Services.WebApi.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class PromptsController : ControllerBase
    {
        private readonly IPromptRepository _promptRepository;
        private readonly ILogger _logger;

        public PromptsController(IPromptRepository promptRepository, ILogger logger)
        {
            _promptRepository = promptRepository;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<ApiResponse<IEnumerable<Prompt>>>> ObterTodos()
        {
            try
            {
                var prompts = await _promptRepository.ObterTodosAsync();
                return Ok(new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = true,
                    Dados = prompts
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts", null, ex);
                return StatusCode(500, new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao obter prompts"
                });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<Prompt>>> ObterPorId(string id)
        {
            try
            {
                var prompt = await _promptRepository.ObterPorIdAsync(id);
                if (prompt == null)
                {
                    return NotFound(new ApiResponse<Prompt>
                    {
                        Sucesso = false,
                        Mensagem = "Prompt não encontrado"
                    });
                }

                return Ok(new ApiResponse<Prompt>
                {
                    Sucesso = true,
                    Dados = prompt
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompt", new { PromptId = id }, ex);
                return StatusCode(500, new ApiResponse<Prompt>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao obter prompt"
                });
            }
        }

        [HttpPost]
        public async Task<ActionResult<ApiResponse<Prompt>>> Criar([FromBody] Prompt prompt)
        {
            try
            {
                prompt.UsuarioCriadorId = int.Parse(User.Identity.Name); // Ajustar conforme implementação de autenticação
                var novoPrompt = await _promptRepository.CriarAsync(prompt);
                
                return CreatedAtAction(nameof(ObterPorId), new { id = novoPrompt.PromptId }, 
                    new ApiResponse<Prompt>
                    {
                        Sucesso = true,
                        Dados = novoPrompt
                    });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao criar prompt", null, ex);
                return StatusCode(500, new ApiResponse<Prompt>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao criar prompt"
                });
            }
        }

        [HttpPost("{id}/curtir")]
        public async Task<ActionResult<ApiResponse<bool>>> Curtir(string id)
        {
            try
            {
                var usuarioId = int.Parse(User.Identity.Name); // Ajustar conforme implementação de autenticação
                var resultado = await _promptRepository.CurtirAsync(id, usuarioId);
                
                return Ok(new ApiResponse<bool>
                {
                    Sucesso = true,
                    Dados = resultado
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao curtir prompt", new { PromptId = id }, ex);
                return StatusCode(500, new ApiResponse<bool>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao curtir prompt"
                });
            }
        }

        [HttpDelete("{id}/curtir")]
        public async Task<ActionResult<ApiResponse<bool>>> Descurtir(string id)
        {
            try
            {
                var usuarioId = int.Parse(User.Identity.Name); // Ajustar conforme implementação de autenticação
                var resultado = await _promptRepository.DescurtirAsync(id, usuarioId);
                
                return Ok(new ApiResponse<bool>
                {
                    Sucesso = true,
                    Dados = resultado
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao descurtir prompt", new { PromptId = id }, ex);
                return StatusCode(500, new ApiResponse<bool>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao descurtir prompt"
                });
            }
        }

        [HttpGet("categoria/{categoriaId}")]
        public async Task<ActionResult<ApiResponse<IEnumerable<Prompt>>>> ObterPorCategoria(string categoriaId)
        {
            try
            {
                var prompts = await _promptRepository.ObterPorCategoriaAsync(categoriaId);
                return Ok(new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = true,
                    Dados = prompts
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts por categoria", new { CategoriaId = categoriaId }, ex);
                return StatusCode(500, new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao obter prompts por categoria"
                });
            }
        }

        [HttpGet("meus-prompts")]
        public async Task<ActionResult<ApiResponse<IEnumerable<Prompt>>>> ObterMeusPrompts()
        {
            try
            {
                var usuarioId = int.Parse(User.Identity.Name); // Ajustar conforme implementação de autenticação
                var prompts = await _promptRepository.ObterPorUsuarioAsync(usuarioId);
                return Ok(new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = true,
                    Dados = prompts
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts do usuário", null, ex);
                return StatusCode(500, new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao obter prompts do usuário"
                });
            }
        }

        [HttpGet("pendentes")]
        [Authorize(Roles = "Administrador")] // Ajustar conforme implementação de autenticação
        public async Task<ActionResult<ApiResponse<IEnumerable<Prompt>>>> ObterPendentes()
        {
            try
            {
                var prompts = await _promptRepository.ObterPendentesAprovacaoAsync();
                return Ok(new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = true,
                    Dados = prompts
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao obter prompts pendentes", null, ex);
                return StatusCode(500, new ApiResponse<IEnumerable<Prompt>>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao obter prompts pendentes"
                });
            }
        }

        [HttpPost("{id}/aprovar")]
        [Authorize(Roles = "Administrador")] // Ajustar conforme implementação de autenticação
        public async Task<ActionResult<ApiResponse<bool>>> Aprovar(string id)
        {
            try
            {
                var usuarioId = int.Parse(User.Identity.Name); // Ajustar conforme implementação de autenticação
                var resultado = await _promptRepository.AprovarAsync(id, usuarioId);
                
                return Ok(new ApiResponse<bool>
                {
                    Sucesso = true,
                    Dados = resultado
                });
            }
            catch (Exception ex)
            {
                _logger.Error("Erro ao aprovar prompt", new { PromptId = id }, ex);
                return StatusCode(500, new ApiResponse<bool>
                {
                    Sucesso = false,
                    Mensagem = "Erro ao aprovar prompt"
                });
            }
        }
    }
} 