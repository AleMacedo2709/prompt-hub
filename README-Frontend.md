# Guia de Estruturação do Frontend

Este guia fornece instruções para estruturar o frontend de forma que se integre adequadamente com o backend .NET.

## Índice

1. [Estrutura de Diretórios](#1-estrutura-de-diretórios)
2. [Integração com Backend](#2-integração-com-backend)
3. [Tipos e Interfaces](#3-tipos-e-interfaces)
4. [Serviços HTTP](#4-serviços-http)
5. [Configuração de Ambiente](#5-configuração-de-ambiente)
6. [Autenticação](#6-autenticação)
7. [Boas Práticas](#7-boas-práticas)

## 1. Estrutura de Diretórios

```
frontend/
├── src/
│   ├── assets/              # Recursos estáticos
│   ├── components/          # Componentes reutilizáveis
│   ├── interfaces/          # Tipos e interfaces TypeScript
│   │   ├── models/         # Interfaces que espelham os modelos do backend
│   │   └── responses/      # Interfaces para respostas da API
│   ├── services/           # Serviços de comunicação com API
│   │   ├── api/           # Configuração e instância do axios
│   │   └── endpoints/     # Serviços específicos por entidade
│   ├── utils/              # Funções utilitárias
│   ├── pages/              # Páginas/rotas da aplicação
│   └── config/             # Configurações do ambiente
└── public/                 # Arquivos públicos
```

## 2. Integração com Backend

### 2.1. Configuração da API (src/services/api/index.ts)
```typescript
import axios from 'axios';
import { getToken } from '@/utils/auth';

const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'https://api.seudominio.com',
  timeout: 30000,
});

// Interceptor para adicionar token de autenticação
api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
```

### 2.2. Exemplo de Serviço (src/services/endpoints/usuario.service.ts)
```typescript
import api from '../api';
import { IUsuario, IUsuarioCreate } from '@/interfaces/models/usuario.interface';

export const UsuarioService = {
  obterTodos: async (): Promise<IUsuario[]> => {
    const response = await api.get('/api/usuarios');
    return response.data;
  },

  obterPorId: async (id: number): Promise<IUsuario> => {
    const response = await api.get(`/api/usuarios/${id}`);
    return response.data;
  },

  criar: async (usuario: IUsuarioCreate): Promise<IUsuario> => {
    const response = await api.post('/api/usuarios', usuario);
    return response.data;
  },

  atualizar: async (id: number, usuario: Partial<IUsuario>): Promise<IUsuario> => {
    const response = await api.put(`/api/usuarios/${id}`, usuario);
    return response.data;
  },

  excluir: async (id: number): Promise<void> => {
    await api.delete(`/api/usuarios/${id}`);
  }
};
```

## 3. Tipos e Interfaces

### 3.1. Modelos (src/interfaces/models/usuario.interface.ts)
```typescript
// Espelha a estrutura da entidade Usuario do backend
export interface IUsuario {
  usuarioId: number;
  nome: string;
  email: string;
  ativo: boolean;
  dataCriacao: string;
  dataAtualizacao?: string;
  ultimoAcesso?: string;
}

// Interface para criação (omite campos gerados automaticamente)
export interface IUsuarioCreate {
  nome: string;
  email: string;
  ativo?: boolean;
}

// Interface para atualização (todos os campos são opcionais)
export type IUsuarioUpdate = Partial<IUsuario>;
```

### 3.2. Respostas (src/interfaces/responses/api.interface.ts)
```typescript
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
```

## 4. Serviços HTTP

### 4.1. Configuração Global (src/config/axios.config.ts)
```typescript
import axios from 'axios';
import { handleError } from '@/utils/error-handler';

export const configureAxios = () => {
  axios.defaults.baseURL = process.env.REACT_APP_API_URL;
  
  axios.interceptors.response.use(
    (response) => response,
    (error) => handleError(error)
  );
};
```

## 5. Configuração de Ambiente

### 5.1. Variáveis de Ambiente (.env)
```env
REACT_APP_API_URL=https://api.seudominio.com
REACT_APP_AUTH_URL=https://login.microsoftonline.com/seu-tenant-id
REACT_APP_CLIENT_ID=seu-client-id
```

### 5.2. Configuração por Ambiente (src/config/environment.ts)
```typescript
export const environment = {
  production: process.env.NODE_ENV === 'production',
  apiUrl: process.env.REACT_APP_API_URL,
  authUrl: process.env.REACT_APP_AUTH_URL,
  clientId: process.env.REACT_APP_CLIENT_ID,
};
```

## 6. Autenticação

### 6.1. Serviço de Autenticação (src/services/auth.service.ts)
```typescript
import { environment } from '@/config/environment';
import { IUsuario } from '@/interfaces/models/usuario.interface';

export const AuthService = {
  login: async (token: string): Promise<IUsuario> => {
    // Implementação específica para seu provedor de autenticação
    // Exemplo usando Azure AD
    const response = await api.post('/api/auth/login', { token });
    return response.data;
  },

  logout: () => {
    localStorage.removeItem('token');
    // Adicione lógica adicional de logout se necessário
  },

  getToken: (): string | null => {
    return localStorage.getItem('token');
  }
};
```

## 7. Boas Práticas

### 7.1. Tipagem
- Use TypeScript para garantir tipagem forte
- Crie interfaces que espelham exatamente as entidades do backend
- Use tipos utilitários do TypeScript (Partial, Pick, Omit) para derivar interfaces

### 7.2. Organização de Código
- Mantenha serviços separados por entidade
- Use constantes para URLs e outros valores fixos
- Implemente tratamento de erros centralizado
- Use interceptors para lógica comum (autenticação, tratamento de erros)

### 7.3. Segurança
- Nunca armazene dados sensíveis no localStorage
- Use HTTPS para todas as chamadas de API
- Implemente timeout em chamadas HTTP
- Valide dados antes de enviar ao backend

### 7.4. Performance
- Implemente cache quando apropriado
- Use lazy loading para módulos grandes
- Otimize bundles para produção

### 7.5. Manutenção
- Mantenha documentação atualizada
- Use comentários para código complexo
- Siga um estilo de código consistente
- Implemente testes unitários

## Contribuição

Para contribuir com este projeto:

1. Faça um Fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes. 