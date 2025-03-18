/**
 * Interface que representa as informações do usuário
 */
export interface IUser {
  id: string;
  name: string;
  email: string;
  role: string;
  unit: string;
  avatar: string;
  interests: string[];
  location: string;
}

/**
 * Interface para criação de usuário
 */
export interface IUserCreate {
  name: string;
  email: string;
  unit?: string;
  interests?: string[];
  location?: string;
}

/**
 * Interface para atualização de usuário
 */
export type IUserUpdate = Partial<Omit<IUser, 'id' | 'role'>>; 