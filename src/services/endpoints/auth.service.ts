import { PublicClientApplication, AuthenticationResult } from '@azure/msal-browser';
import api from '../api';
import { environment } from '@/config/environment';
import { IUser } from '@/interfaces/models/user.interface';

const msalConfig = {
  auth: {
    clientId: environment.clientId,
    authority: `${environment.authUrl}`,
    redirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'localStorage',
    storeAuthStateInCookie: false,
  },
};

const msalInstance = new PublicClientApplication(msalConfig);

/**
 * Serviço para gerenciamento de autenticação com Azure AD
 * @namespace AuthService
 */
export const AuthService = {
  msalInstance,

  /**
   * Realiza o login do usuário usando Azure AD
   * @async
   * @returns {Promise<void>}
   * @throws {Error} Erro ao fazer login
   */
  login: async (): Promise<void> => {
    try {
      const loginResponse = await msalInstance.loginPopup({
        scopes: ['user.read'],
        prompt: 'select_account',
      });
      
      await AuthService.handleLoginSuccess(loginResponse);
    } catch (error) {
      console.error('Erro ao fazer login:', error);
      throw error;
    }
  },

  /**
   * Processa o resultado do login bem-sucedido
   * @async
   * @param {AuthenticationResult} response - Resultado da autenticação
   * @returns {Promise<void>}
   */
  handleLoginSuccess: async (response: AuthenticationResult): Promise<void> => {
    localStorage.setItem('token', response.accessToken);
    localStorage.setItem('isAuthenticated', 'true');

    // Registrar o token no interceptor do axios
    api.defaults.headers.common['Authorization'] = `Bearer ${response.accessToken}`;

    // Obter informações adicionais do usuário da nossa API
    try {
      const userResponse = await api.get<IUser>('/api/usuarios/me');
      localStorage.setItem('userInfo', JSON.stringify(userResponse.data));
    } catch (error) {
      console.error('Erro ao obter informações do usuário:', error);
    }
  },

  /**
   * Realiza o logout do usuário
   * @async
   * @returns {Promise<void>}
   */
  logout: async (): Promise<void> => {
    await msalInstance.logoutPopup();
    localStorage.removeItem('token');
    localStorage.removeItem('isAuthenticated');
    localStorage.removeItem('userInfo');
    delete api.defaults.headers.common['Authorization'];
  },

  /**
   * Obtém o token de acesso armazenado
   * @returns {string | null} Token de acesso ou null se não existir
   */
  getToken: (): string | null => {
    return localStorage.getItem('token');
  },

  /**
   * Verifica se o usuário está autenticado
   * @returns {boolean} True se o usuário estiver autenticado
   */
  isAuthenticated: (): boolean => {
    return localStorage.getItem('isAuthenticated') === 'true';
  },

  /**
   * Obtém as informações do usuário atual
   * @returns {IUser | null} Informações do usuário ou null se não estiver autenticado
   */
  getCurrentUser: (): IUser | null => {
    const userInfo = localStorage.getItem('userInfo');
    return userInfo ? JSON.parse(userInfo) : null;
  },

  /**
   * Verifica se o usuário possui determinado papel
   * @param {string} role - Papel a ser verificado
   * @returns {boolean} True se o usuário possuir o papel
   */
  hasRole: (role: string): boolean => {
    const user = AuthService.getCurrentUser();
    return user?.role === role;
  },
};