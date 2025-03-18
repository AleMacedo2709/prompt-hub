/**
 * Interface para estatísticas gerais do dashboard
 */
export interface IDashboardStats {
  totalPrompts: number
  promptsAprovados: number
  promptsPendentes: number
  promptsRejeitados: number
  totalUsuarios: number
  usuariosAtivos: number
  totalCategorias: number
  totalCurtidas: number
  totalFavoritos: number
}

/**
 * Interface para dados de tendência ao longo do tempo
 */
export interface ITrendData {
  data: string
  valor: number
}

/**
 * Interface para dados de distribuição por categoria
 */
export interface ICategoria {
  CategoriaId: string
  Nome: string
  Descricao?: string
  Ativo: boolean
  DataCriacao: string
  DataAtualizacao?: string
  quantidade: number
  percentual: number
}

/**
 * Interface para ranking de usuários
 */
export interface IUsuario {
  UsuarioId: number
  Nome: string
  Email: string
  Cargo?: string
  Unidade?: string
  Avatar?: string
  Localizacao?: string
  Ativo: boolean
  DataCriacao: string
  DataAtualizacao?: string
  UltimoAcesso?: string
  totalPrompts?: number
  totalCurtidas?: number
  totalFavoritos?: number
}

/**
 * Interface para dados completos do dashboard
 */
export interface IPrompt {
  PromptId: string
  Titulo: string
  Descricao?: string
  Conteudo: string
  CategoriaId: string
  Publico: boolean
  Status: 'pending' | 'approved' | 'rejected'
  UsuarioCriadorId: number
  DataCriacao: string
  DataAtualizacao?: string
  DataAprovacao?: string
  UsuarioAprovadorId?: number
  MotivoRejeicao?: string
  PalavrasChave: string[]
  curtidas: number
  favoritos: number
  autor: IUsuario
}

export interface IDashboardData {
  stats: IDashboardStats
  promptsPorDia: ITrendData[]
  usuariosPorDia: ITrendData[]
  distribuicaoCategorias: ICategoria[]
  topUsuarios: IUsuario[]
  topPrompts: IPrompt[]
} 