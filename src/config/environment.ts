interface Environment {
  production: boolean;
  apiUrl: string;
  authUrl: string;
  clientId: string;
}

const isDevelopment = !import.meta.env.PROD;

export const environment: Environment = {
  production: import.meta.env.PROD,
  apiUrl: isDevelopment 
    ? 'http://localhost:5000/api' // Local development server
    : (import.meta.env.VITE_API_URL || 'https://api.juristpromptshub.mp.gov.br'),
  authUrl: import.meta.env.VITE_AUTH_URL || 'https://login.microsoftonline.com/seu-tenant-id',
  clientId: import.meta.env.VITE_CLIENT_ID || 'seu-client-id',
}; 