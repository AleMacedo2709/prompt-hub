import axios from 'axios';
import { environment } from '@/config/environment';
import { AuthService } from '@/services/endpoints/auth.service';
import { handleApiError } from '@/utils/error-handler';

const api = axios.create({
  baseURL: environment.apiUrl,
  timeout: 30000,
});

// Interceptor para adicionar token de autenticação
api.interceptors.request.use((config) => {
  const token = AuthService.getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor para tratamento de erros
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    // Se o erro for 401 (não autorizado), tenta renovar o token
    if (error.response?.status === 401) {
      try {
        // Fazer logout e redirecionar para login
        await AuthService.logout();
        window.location.href = '/login';
      } catch (refreshError) {
        return Promise.reject(refreshError);
      }
    }
    return Promise.reject(handleApiError(error));
  }
);

export default api; 