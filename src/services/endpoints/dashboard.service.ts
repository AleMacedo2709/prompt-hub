import api from '@/services/api';
import { IDashboardData } from '@/interfaces/models/dashboard.interface';
import { handleApiError } from '@/utils/error-handler';

const mockDashboardData: IDashboardData = {
  stats: {
    totalPrompts: 150,
    promptsAprovados: 120,
    promptsPendentes: 20,
    promptsRejeitados: 10,
    totalUsuarios: 50,
    usuariosAtivos: 35,
    totalCategorias: 8,
    totalCurtidas: 300,
    totalFavoritos: 180
  },
  promptsPorDia: [
    { data: new Date().toISOString(), valor: 15 }
  ],
  usuariosPorDia: [
    { data: new Date().toISOString(), valor: 5 }
  ],
  distribuicaoCategorias: [
    { 
      CategoriaId: 'criminal',
      Nome: 'Criminal',
      Descricao: 'Prompts relacionados à área criminal',
      Ativo: true,
      DataCriacao: new Date().toISOString(),
      quantidade: 40,
      percentual: 40
    },
    { 
      CategoriaId: 'civil',
      Nome: 'Cível',
      Descricao: 'Prompts relacionados à área cível',
      Ativo: true,
      DataCriacao: new Date().toISOString(),
      quantidade: 35,
      percentual: 35
    }
  ],
  topUsuarios: [
    { 
      UsuarioId: 1,
      Nome: 'Usuário Exemplo',
      Email: 'usuario@exemplo.com',
      Cargo: 'Promotor de Justiça',
      Unidade: 'MPSP',
      Avatar: 'https://ui-avatars.com/api/?name=Usuario+Exemplo',
      Localizacao: 'São Paulo, SP',
      Ativo: true,
      DataCriacao: new Date().toISOString(),
      UltimoAcesso: new Date().toISOString(),
      totalPrompts: 25,
      totalCurtidas: 150,
      totalFavoritos: 75
    }
  ],
  topPrompts: [
    {
      PromptId: '1',
      Titulo: 'Modelo de Denúncia Criminal',
      Descricao: 'Modelo base para denúncias criminais',
      Conteudo: 'Conteúdo do prompt...',
      CategoriaId: 'criminal',
      Publico: true,
      Status: 'approved',
      UsuarioCriadorId: 1,
      DataCriacao: new Date().toISOString(),
      DataAprovacao: new Date().toISOString(),
      UsuarioAprovadorId: 2,
      PalavrasChave: ['criminal', 'denúncia', 'processo penal'],
      curtidas: 50,
      favoritos: 25,
      autor: {
        UsuarioId: 1,
        Nome: 'Usuário Exemplo',
        Email: 'usuario@exemplo.com',
        Cargo: 'Promotor de Justiça',
        Avatar: 'https://ui-avatars.com/api/?name=Usuario+Exemplo'
      }
    }
  ]
};

/**
 * Serviço para obtenção de dados do dashboard
 * @namespace DashboardService
 */
export class DashboardService {
  /**
   * Obtém todos os dados do dashboard
   * @async
   * @returns {Promise<IDashboardData>} Dados do dashboard
   * @throws {ApiError} Erro ao obter dados do dashboard
   */
  static async obterDados(): Promise<IDashboardData> {
    try {
      const response = await api.get<IDashboardData>('/dashboard');
      return response.data;
    } catch (error) {
      console.warn('Usando dados mockados devido a indisponibilidade da API:', error);
      return mockDashboardData;
    }
  }

  /**
   * Obtém dados do dashboard filtrados por período
   * @async
   * @param {Date} dataInicio - Data inicial do período
   * @param {Date} dataFim - Data final do período
   * @returns {Promise<IDashboardData>} Dados do dashboard do período
   * @throws {ApiError} Erro ao obter dados do dashboard
   */
  static async obterDadosPorPeriodo(dataInicio: Date, dataFim: Date): Promise<IDashboardData> {
    try {
      const response = await api.get<IDashboardData>('/dashboard/periodo', {
        params: { dataInicio, dataFim }
      });
      return response.data;
    } catch (error) {
      console.warn('Usando dados mockados devido a indisponibilidade da API:', error);
      return mockDashboardData;
    }
  }

  /**
   * Obtém dados do dashboard para uma categoria específica
   * @async
   * @param {string} categoriaId - ID da categoria
   * @returns {Promise<IDashboardData>} Dados do dashboard da categoria
   * @throws {ApiError} Erro ao obter dados do dashboard
   */
  static async obterDadosPorCategoria(categoriaId: string): Promise<IDashboardData> {
    try {
      const response = await api.get<IDashboardData>(`/dashboard/categoria/${categoriaId}`);
      return response.data;
    } catch (error) {
      console.warn('Usando dados mockados devido a indisponibilidade da API:', error);
      return mockDashboardData;
    }
  }

  /**
   * Obtém dados do dashboard para um usuário específico
   * @async
   * @param {number} usuarioId - ID do usuário
   * @returns {Promise<IDashboardData>} Dados do dashboard do usuário
   * @throws {ApiError} Erro ao obter dados do dashboard
   */
  static async obterDadosPorUsuario(usuarioId: number): Promise<IDashboardData> {
    try {
      const response = await api.get<IDashboardData>(`/dashboard/usuario/${usuarioId}`);
      return response.data;
    } catch (error) {
      console.warn('Usando dados mockados devido a indisponibilidade da API:', error);
      return mockDashboardData;
    }
  }
} 