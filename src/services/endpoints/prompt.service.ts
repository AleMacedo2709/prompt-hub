import api from '../api';
import { IPrompt, IPromptCreate, IPromptUpdate } from '@/interfaces/models/prompt.interface';
import { IListResponse, IItemResponse } from '@/interfaces/responses/api.interface';
import { handleApiError } from '@/utils/error-handler';

/**
 * Serviço para gerenciamento de prompts
 * @namespace PromptService
 */
export const PromptService = {
  /**
   * Obtém todos os prompts aprovados
   * @async
   * @returns {Promise<IPrompt[]>} Lista de prompts
   * @throws {ApiError} Erro ao obter prompts
   */
  obterTodos: async (): Promise<IPrompt[]> => {
    try {
      const response = await api.get<IListResponse<IPrompt>>('/api/prompts');
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Obtém um prompt específico por ID
   * @async
   * @param {string} id - ID do prompt
   * @returns {Promise<IPrompt>} Prompt encontrado
   * @throws {ApiError} Erro ao obter prompt
   */
  obterPorId: async (id: string): Promise<IPrompt> => {
    try {
      const response = await api.get<IItemResponse<IPrompt>>(`/api/prompts/${id}`);
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Obtém prompts por categoria
   * @async
   * @param {string} categoriaId - ID da categoria
   * @returns {Promise<IPrompt[]>} Lista de prompts da categoria
   * @throws {ApiError} Erro ao obter prompts
   */
  obterPorCategoria: async (categoriaId: string): Promise<IPrompt[]> => {
    try {
      const response = await api.get<IListResponse<IPrompt>>(`/api/prompts/categoria/${categoriaId}`);
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Obtém prompts do usuário autenticado
   * @async
   * @returns {Promise<IPrompt[]>} Lista de prompts do usuário
   * @throws {ApiError} Erro ao obter prompts
   */
  obterMeusPrompts: async (): Promise<IPrompt[]> => {
    try {
      const response = await api.get<IListResponse<IPrompt>>('/api/prompts/meus-prompts');
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Obtém prompts pendentes de aprovação
   * @async
   * @returns {Promise<IPrompt[]>} Lista de prompts pendentes
   * @throws {ApiError} Erro ao obter prompts
   * @requires Papel de Administrador
   */
  obterPendentes: async (): Promise<IPrompt[]> => {
    try {
      const response = await api.get<IListResponse<IPrompt>>('/api/prompts/pendentes');
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Cria um novo prompt
   * @async
   * @param {IPromptCreate} prompt - Dados do prompt a ser criado
   * @returns {Promise<IPrompt>} Prompt criado
   * @throws {ApiError} Erro ao criar prompt
   */
  criar: async (prompt: IPromptCreate): Promise<IPrompt> => {
    try {
      const response = await api.post<IItemResponse<IPrompt>>('/api/prompts', prompt);
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Atualiza um prompt existente
   * @async
   * @param {string} id - ID do prompt
   * @param {IPromptUpdate} prompt - Dados a serem atualizados
   * @returns {Promise<IPrompt>} Prompt atualizado
   * @throws {ApiError} Erro ao atualizar prompt
   */
  atualizar: async (id: string, prompt: IPromptUpdate): Promise<IPrompt> => {
    try {
      const response = await api.put<IItemResponse<IPrompt>>(`/api/prompts/${id}`, prompt);
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Exclui um prompt
   * @async
   * @param {string} id - ID do prompt
   * @returns {Promise<void>}
   * @throws {ApiError} Erro ao excluir prompt
   */
  excluir: async (id: string): Promise<void> => {
    try {
      await api.delete(`/api/prompts/${id}`);
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Curte um prompt
   * @async
   * @param {string} id - ID do prompt
   * @returns {Promise<void>}
   * @throws {ApiError} Erro ao curtir prompt
   */
  curtir: async (id: string): Promise<void> => {
    try {
      await api.post(`/api/prompts/${id}/curtir`);
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Remove curtida de um prompt
   * @async
   * @param {string} id - ID do prompt
   * @returns {Promise<void>}
   * @throws {ApiError} Erro ao descurtir prompt
   */
  descurtir: async (id: string): Promise<void> => {
    try {
      await api.delete(`/api/prompts/${id}/curtir`);
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Favorita um prompt
   * @async
   * @param {string} id - ID do prompt
   * @returns {Promise<void>}
   * @throws {ApiError} Erro ao favoritar prompt
   */
  favoritar: async (id: string): Promise<void> => {
    try {
      await api.post(`/api/prompts/${id}/favoritar`);
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Remove favorito de um prompt
   * @async
   * @param {string} id - ID do prompt
   * @returns {Promise<void>}
   * @throws {ApiError} Erro ao desfavoritar prompt
   */
  desfavoritar: async (id: string): Promise<void> => {
    try {
      await api.delete(`/api/prompts/${id}/favoritar`);
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Aprova um prompt pendente
   * @async
   * @param {string} id - ID do prompt
   * @returns {Promise<void>}
   * @throws {ApiError} Erro ao aprovar prompt
   * @requires Papel de Administrador
   */
  aprovar: async (id: string): Promise<void> => {
    try {
      await api.post(`/api/prompts/${id}/aprovar`);
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Rejeita um prompt pendente
   * @async
   * @param {string} id - ID do prompt
   * @param {string} motivoRejeicao - Motivo da rejeição
   * @returns {Promise<void>}
   * @throws {ApiError} Erro ao rejeitar prompt
   * @requires Papel de Administrador
   */
  rejeitar: async (id: string, motivoRejeicao: string): Promise<void> => {
    try {
      await api.post(`/api/prompts/${id}/rejeitar`, { motivoRejeicao });
    } catch (error) {
      throw handleApiError(error);
    }
  },

  /**
   * Pesquisa prompts por termo e categorias
   * @async
   * @param {string} termo - Termo de pesquisa
   * @param {string[]} [categorias] - Lista de IDs de categorias para filtrar
   * @returns {Promise<IPrompt[]>} Lista de prompts encontrados
   * @throws {ApiError} Erro ao pesquisar prompts
   */
  pesquisar: async (termo: string, categorias?: string[]): Promise<IPrompt[]> => {
    try {
      const params = new URLSearchParams();
      params.append('termo', termo);
      if (categorias?.length) {
        categorias.forEach(cat => params.append('categorias', cat));
      }
      const response = await api.get<IListResponse<IPrompt>>(`/api/prompts/pesquisar?${params.toString()}`);
      return response.data.dados;
    } catch (error) {
      throw handleApiError(error);
    }
  }
};