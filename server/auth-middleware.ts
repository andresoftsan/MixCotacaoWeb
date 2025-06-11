import { Request, Response, NextFunction } from "express";
import { storage } from "./storage";

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: number;
        name: string;
        email: string;
        isAdmin: boolean;
      };
      apiKey?: {
        id: number;
        name: string;
        sellerId: number;
      };
    }
  }
}

// Middleware para autenticação por token API
export async function authenticateApiToken(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Token de acesso requerido' });
  }

  const token = authHeader.substring(7); // Remove "Bearer "
  
  try {
    const apiKey = await storage.getApiKey(token);
    
    if (!apiKey || !apiKey.isActive) {
      return res.status(401).json({ message: 'Token inválido ou inativo' });
    }

    // Buscar dados do vendedor associado ao token
    const seller = await storage.getSeller(apiKey.sellerId);
    
    if (!seller || seller.status !== 'Ativo') {
      return res.status(401).json({ message: 'Vendedor inativo' });
    }

    // Atualizar último uso do token
    await storage.updateApiKeyLastUsed(apiKey.id);

    // Adicionar informações do usuário e API key ao request
    req.user = {
      id: seller.id,
      name: seller.name,
      email: seller.email,
      isAdmin: seller.email === 'administrador@softsan.com.br'
    };

    req.apiKey = {
      id: apiKey.id,
      name: apiKey.name,
      sellerId: apiKey.sellerId
    };

    next();
  } catch (error) {
    console.error('Erro na autenticação por token:', error);
    res.status(500).json({ message: 'Erro interno do servidor' });
  }
}

// Middleware flexível que aceita tanto sessão quanto token
export async function authenticateFlexible(req: Request, res: Response, next: NextFunction) {
  console.log('authenticateFlexible called with Authorization header:', req.headers.authorization?.substring(0, 20) + '...');
  
  // Primeiro tenta autenticação por token
  const authHeader = req.headers.authorization;
  
  if (authHeader && authHeader.startsWith('Bearer ')) {
    console.log('Using token authentication');
    return authenticateApiToken(req, res, next);
  }

  console.log('Using session authentication, session userId:', req.session?.userId);
  
  // Se não há token, verifica sessão
  if (!req.session?.userId) {
    return res.status(401).json({ message: 'Não autorizado' });
  }

  try {
    const seller = await storage.getSeller(req.session.userId);
    
    if (!seller || seller.status !== 'Ativo') {
      return res.status(401).json({ message: 'Usuário inativo' });
    }

    req.user = {
      id: seller.id,
      name: seller.name,
      email: seller.email,
      isAdmin: seller.email === 'administrador@softsan.com.br'
    };

    console.log('Session authentication successful, user:', req.user);
    next();
  } catch (error) {
    console.error('Erro na autenticação por sessão:', error);
    res.status(500).json({ message: 'Erro interno do servidor' });
  }
}

// Middleware para verificar se é admin
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  console.log('requireAdmin middleware - req.user:', req.user);
  if (!req.user?.isAdmin) {
    console.log('Access denied - user is not admin');
    return res.status(403).json({ message: 'Acesso restrito a administradores' });
  }
  console.log('Admin access granted');
  next();
}

// Middleware para verificar se o usuário pode acessar dados de um vendedor específico
export function requireSellerAccess(req: Request, res: Response, next: NextFunction) {
  const sellerId = parseInt(req.params.sellerId || req.body.sellerId);
  
  // Admin pode acessar qualquer vendedor
  if (req.user?.isAdmin) {
    return next();
  }

  // Vendedor só pode acessar seus próprios dados
  if (req.user?.id !== sellerId) {
    return res.status(403).json({ message: 'Acesso negado' });
  }

  next();
}