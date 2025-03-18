export interface IPrompt {
  promptId: string;
  titulo: string;
  descricao?: string;
  conteudo: string;
  categoriaId: string;
  publico: boolean;
  status: 'pending' | 'approved' | 'rejected';
  usuarioCriadorId: number;
  dataCriacao: string;
  dataAtualizacao?: string;
  dataAprovacao?: string;
  usuarioAprovadorId?: number;
  motivoRejeicao?: string;
  palavrasChave: string[];
  curtidasCount: number;
  curtidoPeloUsuarioAtual: boolean;
  favoritadoPeloUsuarioAtual: boolean;
  
  // Propriedades de navegação
  categoria?: ICategoria;
  usuarioCriador?: IUsuario;
  usuarioAprovador?: IUsuario;
}

export interface ICategoria {
  categoriaId: string;
  nome: string;
  descricao?: string;
  ativo: boolean;
  dataCriacao: string;
  dataAtualizacao?: string;
}

export interface IUsuario {
  usuarioId: number;
  nome: string;
  email: string;
  cargo?: string;
  unidade?: string;
  avatar?: string;
  localizacao?: string;
  ativo: boolean;
  dataCriacao: string;
  dataAtualizacao?: string;
  ultimoAcesso?: string;
}

// Interface para criação de prompt
export interface IPromptCreate {
  titulo: string;
  descricao?: string;
  conteudo: string;
  categoriaId: string;
  publico: boolean;
  palavrasChave: string[];
}

// Interface para atualização de prompt
export type IPromptUpdate = Partial<Omit<IPrompt, 
  'promptId' | 'usuarioCriadorId' | 'dataCriacao' | 'dataAtualizacao' | 'dataAprovacao' | 'usuarioAprovadorId'
>>; 