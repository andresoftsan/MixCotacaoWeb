import { apiRequest } from "./queryClient";

export interface User {
  id: number;
  name: string;
  email: string;
  isAdmin: boolean;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export const authService = {
  async login(credentials: LoginCredentials): Promise<User> {
    const response = await apiRequest("POST", "/api/auth/login", credentials);
    return response.json();
  },

  async logout(): Promise<void> {
    await apiRequest("POST", "/api/auth/logout");
  },

  async getCurrentUser(): Promise<User | null> {
    try {
      const response = await apiRequest("GET", "/api/auth/me");
      return response.json();
    } catch (error) {
      return null;
    }
  }
};
