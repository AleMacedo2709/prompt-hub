import { AxiosError } from 'axios';

export interface ApiError {
  message: string;
  code?: string;
  details?: unknown;
}

export const handleApiError = (error: AxiosError): ApiError => {
  // Log do erro para ferramentas de monitoramento
  console.error('API Error:', error);

  if (error.response) {
    // Erro com resposta do servidor
    const data = error.response.data as any;
    return {
      message: data.mensagem || 'Ocorreu um erro ao processar sua requisição',
      code: data.codigo,
      details: data.detalhes
    };
  } else if (error.request) {
    // Erro sem resposta do servidor
    return {
      message: 'Não foi possível conectar ao servidor',
      code: 'NETWORK_ERROR'
    };
  } else {
    // Erro na configuração da requisição
    return {
      message: 'Erro ao preparar a requisição',
      code: 'REQUEST_CONFIG_ERROR',
      details: error.message
    };
  }
};

export const showErrorMessage = (error: ApiError): void => {
  // Implementar lógica de exibição de erro (toast, alert, etc)
  console.error('Error:', error.message);
}; 