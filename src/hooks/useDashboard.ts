import { useQuery } from '@tanstack/react-query';
import { DashboardService } from '@/services/endpoints/dashboard.service';
import { IDashboardData } from '@/interfaces/models/dashboard.interface';

export const DASHBOARD_QUERY_KEY = 'dashboard';

interface UseDashboardOptions {
  dataInicio?: Date;
  dataFim?: Date;
  categoriaId?: string;
  usuarioId?: number;
  enabled?: boolean;
}

/**
 * Hook personalizado para gerenciar dados do dashboard
 * @param {UseDashboardOptions} options - Opções de configuração do hook
 * @returns {UseQueryResult<IDashboardData>} Resultado da query com dados do dashboard
 */
export function useDashboard(options: UseDashboardOptions = {}) {
  const { dataInicio, dataFim, categoriaId, usuarioId, enabled = true } = options;

  return useQuery({
    queryKey: [DASHBOARD_QUERY_KEY, dataInicio, dataFim, categoriaId, usuarioId],
    queryFn: async () => {
      try {
        if (dataInicio && dataFim) {
          return await DashboardService.obterDadosPorPeriodo(dataInicio, dataFim);
        }
        if (categoriaId) {
          return await DashboardService.obterDadosPorCategoria(categoriaId);
        }
        if (usuarioId) {
          return await DashboardService.obterDadosPorUsuario(usuarioId);
        }
        return await DashboardService.obterDados();
      } catch (error) {
        // Retorna dados mockados em caso de erro de conexão
        return {
          stats: {
            totalPrompts: 0,
            promptsAprovados: 0,
            promptsPendentes: 0,
            promptsRejeitados: 0,
            totalUsuarios: 0,
            usuariosAtivos: 0,
            totalCategorias: 0,
            totalCurtidas: 0,
            totalFavoritos: 0
          },
          promptsPorDia: [],
          usuariosPorDia: [],
          distribuicaoCategorias: [],
          topUsuarios: [],
          topPrompts: []
        };
      }
    },
    enabled,
    staleTime: 5 * 60 * 1000, // 5 minutos
    retry: 1, // Tenta apenas uma vez em caso de erro
    retryDelay: 1000, // Espera 1 segundo antes de tentar novamente
  });
} 