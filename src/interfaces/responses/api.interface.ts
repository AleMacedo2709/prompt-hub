export interface IPaginacao {
  paginaAtual: number;
  totalPaginas: number;
  tamanhoPagina: number;
  totalRegistros: number;
}

export interface IApiResponse<T> {
  sucesso: boolean;
  mensagem?: string;
  dados: T;
  paginacao?: IPaginacao;
}

export interface IApiErrorResponse {
  sucesso: boolean;
  mensagem: string;
  codigo?: string;
  detalhes?: unknown;
}

// Tipo utilitário para respostas paginadas
export type IPaginatedResponse<T> = IApiResponse<T> & {
  paginacao: IPaginacao;
};

// Tipo utilitário para respostas de lista
export type IListResponse<T> = IApiResponse<T[]>;

// Tipo utilitário para respostas de item único
export type IItemResponse<T> = IApiResponse<T>; 