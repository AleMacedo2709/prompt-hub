import { PromptService } from '../prompt.service';
import api from '../../api';
import { handleApiError } from '@/utils/error-handler';

// Mock do módulo axios
jest.mock('../../api');
jest.mock('@/utils/error-handler');

describe('PromptService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('obterTodos', () => {
    it('deve retornar lista de prompts com sucesso', async () => {
      const mockPrompts = [
        { promptId: '1', titulo: 'Prompt 1' },
        { promptId: '2', titulo: 'Prompt 2' }
      ];

      (api.get as jest.Mock).mockResolvedValueOnce({
        data: { sucesso: true, dados: mockPrompts }
      });

      const result = await PromptService.obterTodos();

      expect(api.get).toHaveBeenCalledWith('/api/prompts');
      expect(result).toEqual(mockPrompts);
    });

    it('deve tratar erro ao obter prompts', async () => {
      const mockError = new Error('Erro de API');
      (api.get as jest.Mock).mockRejectedValueOnce(mockError);
      (handleApiError as jest.Mock).mockReturnValueOnce(mockError);

      await expect(PromptService.obterTodos()).rejects.toThrow('Erro de API');
      expect(handleApiError).toHaveBeenCalledWith(mockError);
    });
  });

  describe('criar', () => {
    it('deve criar prompt com sucesso', async () => {
      const mockPrompt = {
        titulo: 'Novo Prompt',
        conteudo: 'Conteúdo do prompt',
        categoriaId: 'cat1',
        publico: true,
        palavrasChave: ['teste']
      };

      const mockResponse = {
        promptId: '1',
        ...mockPrompt,
        status: 'pending',
        dataCriacao: new Date().toISOString()
      };

      (api.post as jest.Mock).mockResolvedValueOnce({
        data: { sucesso: true, dados: mockResponse }
      });

      const result = await PromptService.criar(mockPrompt);

      expect(api.post).toHaveBeenCalledWith('/api/prompts', mockPrompt);
      expect(result).toEqual(mockResponse);
    });

    it('deve tratar erro ao criar prompt', async () => {
      const mockPrompt = {
        titulo: 'Novo Prompt',
        conteudo: 'Conteúdo do prompt',
        categoriaId: 'cat1',
        publico: true,
        palavrasChave: ['teste']
      };

      const mockError = new Error('Erro ao criar prompt');
      (api.post as jest.Mock).mockRejectedValueOnce(mockError);
      (handleApiError as jest.Mock).mockReturnValueOnce(mockError);

      await expect(PromptService.criar(mockPrompt)).rejects.toThrow('Erro ao criar prompt');
      expect(handleApiError).toHaveBeenCalledWith(mockError);
    });
  });

  // Adicionar mais testes para outros métodos...
});