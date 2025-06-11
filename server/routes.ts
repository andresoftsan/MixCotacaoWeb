import type { Express } from "express";
import { createServer, type Server } from "http";
import session from "express-session";
import { storage } from "./storage";
import bcrypt from "bcrypt";
import { insertSellerSchema, insertQuotationSchema, insertQuotationItemSchema, updateQuotationItemSchema, insertApiKeySchema } from "@shared/schema";
import { authenticateFlexible, authenticateApiToken, requireAdmin, requireSellerAccess } from "./auth-middleware";
import { nanoid } from "nanoid";

declare module "express-session" {
  interface SessionData {
    userId?: number;
    isAdmin?: boolean;
  }
}

export async function registerRoutes(app: Express): Promise<Server> {
  // Session middleware setup
  app.use(session({
    secret: process.env.SESSION_SECRET || 'mix-cotacao-secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: { 
      secure: false, // Set to true if using HTTPS
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
  }));

  // Initialize admin user if not exists
  app.use(async (req, res, next) => {
    try {
      console.log("Testing database connection...");
      const adminExists = await storage.getSellerByEmail("administrador@softsan.com.br");
      console.log("Database connection successful. Admin exists:", !!adminExists);
      
      if (!adminExists) {
        console.log("Creating admin user...");
        const hashedPassword = await bcrypt.hash("M1xgestao@2025", 10);
        await storage.createSeller({
          email: "administrador@softsan.com.br",
          name: "Administrador",
          password: hashedPassword,
          status: "Ativo"
        });
        console.log("Admin user created successfully");
      }
    } catch (error: any) {
      console.error("Database connection error:", {
        message: error.message,
        code: error.code,
        stack: error.stack
      });
    }
    next();
  });

  // Auth middleware
  const requireAuth = (req: any, res: any, next: any) => {
    if (!req.session.userId) {
      return res.status(401).json({ message: "Não autorizado" });
    }
    next();
  };

  const requireAdmin = (req: any, res: any, next: any) => {
    if (!req.session.userId || !req.session.isAdmin) {
      return res.status(403).json({ message: "Acesso negado" });
    }
    next();
  };

  const requireSuperAdmin = async (req: any, res: any, next: any) => {
    if (!req.session.userId) {
      return res.status(401).json({ message: "Não autorizado" });
    }
    
    try {
      const seller = await storage.getSeller(req.session.userId);
      if (!seller || seller.email !== "administrador@softsan.com.br") {
        return res.status(403).json({ message: "Acesso negado" });
      }
      next();
    } catch (error) {
      console.error("Super admin check error:", error);
      return res.status(500).json({ message: "Erro interno do servidor" });
    }
  };

  // Login
  app.post("/api/auth/login", async (req, res) => {
    try {
      console.log("Login attempt:", { email: req.body?.email, hasPassword: !!req.body?.password });
      
      const { email, password } = req.body;
      
      if (!email || !password) {
        console.log("Missing credentials");
        return res.status(400).json({ message: "Email e senha são obrigatórios" });
      }

      console.log("Attempting to find seller by email:", email);
      const seller = await storage.getSellerByEmail(email);
      if (!seller) {
        console.log("Seller not found for email:", email);
        return res.status(401).json({ message: "Credenciais inválidas" });
      }

      console.log("Seller found, checking password");
      const isValidPassword = await bcrypt.compare(password, seller.password);
      if (!isValidPassword) {
        console.log("Invalid password for email:", email);
        return res.status(401).json({ message: "Credenciais inválidas" });
      }

      if (seller.status === "Inativo") {
        console.log("Inactive seller:", email);
        return res.status(401).json({ message: "Usuário inativo" });
      }

      console.log("Setting session for seller:", seller.id);
      req.session.userId = seller.id;
      req.session.isAdmin = seller.email === "administrador@softsan.com.br";

      console.log("Login successful for:", email);
      res.json({ 
        id: seller.id, 
        name: seller.name, 
        email: seller.email,
        isAdmin: seller.email === "administrador@softsan.com.br"
      });
    } catch (error: any) {
      console.error("Login error details:", {
        message: error.message,
        stack: error.stack,
        code: error.code,
        email: req.body?.email
      });
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Logout
  app.post("/api/auth/logout", (req, res) => {
    req.session.destroy((err) => {
      if (err) {
        return res.status(500).json({ message: "Erro ao fazer logout" });
      }
      res.json({ message: "Logout realizado com sucesso" });
    });
  });

  // Health check and diagnostics endpoint
  app.get("/api/health", async (req, res) => {
    try {
      const diagnostics = {
        status: "healthy",
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV,
        database: {
          connected: false,
          url_configured: !!process.env.DATABASE_URL,
          url_sample: process.env.DATABASE_URL ? process.env.DATABASE_URL.substring(0, 20) + "..." : "not configured"
        },
        session: {
          secret_configured: !!process.env.SESSION_SECRET,
          store_type: "memory"
        },
        admin_user: {
          exists: false,
          checked: false
        }
      };

      // Test database connection
      try {
        const adminUser = await storage.getSellerByEmail("administrador@softsan.com.br");
        diagnostics.database.connected = true;
        diagnostics.admin_user.exists = !!adminUser;
        diagnostics.admin_user.checked = true;
        
        if (adminUser) {
          console.log("Health check: Admin user found with ID:", adminUser.id);
        } else {
          console.log("Health check: Admin user not found");
        }
      } catch (dbError: any) {
        diagnostics.database.connected = false;
        diagnostics.status = "unhealthy";
        console.error("Health check database error:", {
          message: dbError.message,
          code: dbError.code
        });
      }

      res.json(diagnostics);
    } catch (error: any) {
      console.error("Health check error:", error);
      res.status(503).json({
        status: "unhealthy",
        timestamp: new Date().toISOString(),
        error: error.message
      });
    }
  });

  // Get current user
  app.get("/api/auth/me", authenticateFlexible, async (req, res) => {
    try {
      res.json(req.user);
    } catch (error) {
      console.error("Get user error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Sellers routes
  app.get("/api/sellers", authenticateFlexible, async (req, res) => {
    try {
      // Check if user is admin
      if (!req.user?.isAdmin) {
        return res.status(403).json({ message: "Acesso restrito a administradores" });
      }
      
      // Check if searching by email
      const email = req.query.email as string;
      if (email) {
        const seller = await storage.getSellerByEmail(email);
        if (!seller) {
          return res.status(404).json({ message: "Vendedor não encontrado" });
        }
        return res.json({
          ...seller,
          password: undefined // Don't send password
        });
      }
      
      const sellers = await storage.getAllSellers();
      res.json(sellers.map(seller => ({
        ...seller,
        password: undefined // Don't send password
      })));
    } catch (error) {
      console.error("Get sellers error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Buscar vendedor por e-mail via POST
  app.post("/api/sellers/search", authenticateFlexible, async (req, res) => {
    try {
      // Check if user is admin
      if (!req.user?.isAdmin) {
        return res.status(403).json({ message: "Acesso restrito a administradores" });
      }
      
      const { email } = req.body;
      if (!email) {
        return res.status(400).json({ message: "Campo 'email' é obrigatório" });
      }
      
      const seller = await storage.getSellerByEmail(email);
      
      if (!seller) {
        return res.status(404).json({ message: "Vendedor não encontrado" });
      }

      res.json({
        ...seller,
        password: undefined // Don't send password
      });
    } catch (error) {
      console.error("Get seller by email error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.post("/api/sellers", authenticateFlexible, async (req, res) => {
    try {
      if (!req.user?.isAdmin) {
        return res.status(403).json({ message: "Acesso restrito a administradores" });
      }

      const sellerData = insertSellerSchema.parse(req.body);
      
      const existingSeller = await storage.getSellerByEmail(sellerData.email);
      if (existingSeller) {
        return res.status(400).json({ message: "Email já está em uso" });
      }

      const hashedPassword = await bcrypt.hash(sellerData.password, 10);
      const seller = await storage.createSeller({
        ...sellerData,
        password: hashedPassword
      });

      res.json({
        ...seller,
        password: undefined
      });
    } catch (error) {
      console.error("Create seller error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.put("/api/sellers/:id", authenticateFlexible, async (req, res) => {
    try {
      if (!req.user?.isAdmin) {
        return res.status(403).json({ message: "Acesso restrito a administradores" });
      }

      const id = parseInt(req.params.id);
      const sellerData = insertSellerSchema.partial().parse(req.body);

      if (sellerData.password) {
        sellerData.password = await bcrypt.hash(sellerData.password, 10);
      }

      const seller = await storage.updateSeller(id, sellerData);
      if (!seller) {
        return res.status(404).json({ message: "Vendedor não encontrado" });
      }

      res.json({
        ...seller,
        password: undefined
      });
    } catch (error) {
      console.error("Update seller error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.delete("/api/sellers/:id", authenticateFlexible, async (req, res) => {
    try {
      if (!req.user?.isAdmin) {
        return res.status(403).json({ message: "Acesso restrito a administradores" });
      }

      const id = parseInt(req.params.id);
      const success = await storage.deleteSeller(id);
      
      if (!success) {
        return res.status(404).json({ message: "Vendedor não encontrado" });
      }

      res.json({ message: "Vendedor removido com sucesso" });
    } catch (error) {
      console.error("Delete seller error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Quotations routes
  app.get("/api/quotations", authenticateFlexible, async (req, res) => {
    try {
      const { clientCnpj, number } = req.query;
      
      // Se ambos os parâmetros estão presentes, buscar cotação específica
      if (clientCnpj && number) {
        const quotation = await storage.getQuotationByClientCnpjAndNumber(
          clientCnpj as string, 
          number as string
        );
        
        if (!quotation) {
          return res.status(404).json({ message: "Cotação não encontrada" });
        }
        
        // Verificar se o usuário tem acesso a esta cotação
        if (!req.user!.isAdmin && quotation.sellerId !== req.user!.id) {
          return res.status(403).json({ message: "Acesso negado" });
        }
        
        return res.json(quotation);
      }
      
      // Busca normal - todas as cotações do usuário
      let quotations;
      
      if (req.user!.isAdmin) {
        quotations = await storage.getAllQuotations();
      } else {
        quotations = await storage.getQuotationsBySeller(req.user!.id);
      }

      res.json(quotations);
    } catch (error) {
      console.error("Get quotations error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });



  app.get("/api/quotations/:id", authenticateFlexible, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const quotation = await storage.getQuotation(id);
      
      if (!quotation) {
        return res.status(404).json({ message: "Cotação não encontrada" });
      }

      // Check if user can access this quotation
      if (!req.user?.isAdmin && quotation.sellerId !== req.user?.id) {
        return res.status(403).json({ message: "Acesso negado" });
      }

      res.json(quotation);
    } catch (error) {
      console.error("Get quotation error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.post("/api/quotations", authenticateFlexible, async (req, res) => {
    try {
      const quotationData = insertQuotationSchema.parse(req.body);
      
      // Generate quotation number
      const year = new Date().getUTCFullYear();
      const allQuotations = await storage.getAllQuotations();
      const nextNumber = allQuotations.length + 1;
      const number = `COT-${year}-${String(nextNumber).padStart(3, '0')}`;

      const quotation = await storage.createQuotation({
        ...quotationData,
        number,
        sellerId: req.user!.id
      });

      res.json(quotation);
    } catch (error) {
      console.error("Create quotation error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.put("/api/quotations/:id", authenticateFlexible, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const quotationData = insertQuotationSchema.partial().parse(req.body);

      const existingQuotation = await storage.getQuotation(id);
      if (!existingQuotation) {
        return res.status(404).json({ message: "Cotação não encontrada" });
      }

      // Check if user can update this quotation
      if (!req.user?.isAdmin && existingQuotation.sellerId !== req.user?.id) {
        return res.status(403).json({ message: "Acesso negado" });
      }

      const quotation = await storage.updateQuotation(id, quotationData);
      res.json(quotation);
    } catch (error) {
      console.error("Update quotation error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Quotation items routes
  app.get("/api/quotations/:id/items", authenticateFlexible, async (req, res) => {
    try {
      const quotationId = parseInt(req.params.id);
      
      const quotation = await storage.getQuotation(quotationId);
      if (!quotation) {
        return res.status(404).json({ message: "Cotação não encontrada" });
      }

      // Check if user can access this quotation
      if (!req.user?.isAdmin && quotation.sellerId !== req.user?.id) {
        return res.status(403).json({ message: "Acesso negado" });
      }

      const items = await storage.getQuotationItems(quotationId);
      res.json(items);
    } catch (error) {
      console.error("Get quotation items error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.post("/api/quotations/:id/items", authenticateFlexible, async (req, res) => {
    try {
      const quotationId = parseInt(req.params.id);
      const itemData = insertQuotationItemSchema.parse({
        ...req.body,
        quotationId
      });

      const quotation = await storage.getQuotation(quotationId);
      if (!quotation) {
        return res.status(404).json({ message: "Cotação não encontrada" });
      }

      // Check if user can modify this quotation
      if (!req.user?.isAdmin && quotation.sellerId !== req.user?.id) {
        return res.status(403).json({ message: "Acesso negado" });
      }

      const item = await storage.createQuotationItem(itemData);
      res.json(item);
    } catch (error) {
      console.error("Create quotation item error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.patch("/api/quotation-items/:id", authenticateFlexible, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const itemData = updateQuotationItemSchema.parse(req.body);

      const item = await storage.updateQuotationItem(id, itemData);
      if (!item) {
        return res.status(404).json({ message: "Item não encontrado" });
      }

      res.json(item);
    } catch (error) {
      console.error("Update quotation item error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Dashboard stats
  app.get("/api/dashboard/stats", authenticateFlexible, async (req, res) => {
    try {
      const stats = await storage.getSellerQuotationStats(req.user!.id);
      res.json(stats);
    } catch (error) {
      console.error("Get dashboard stats error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // API Key Management Routes
  
  // List API keys for current user
  app.get("/api/api-keys", authenticateFlexible, async (req, res) => {
    try {
      const apiKeys = await storage.getApiKeysBySeller(req.user!.id);
      // Remove the actual key from response for security
      const safeApiKeys = apiKeys.map(key => ({
        id: key.id,
        name: key.name,
        isActive: key.isActive,
        createdAt: key.createdAt,
        lastUsedAt: key.lastUsedAt,
        keyPreview: key.key.substring(0, 8) + "..." + key.key.slice(-4)
      }));
      res.json(safeApiKeys);
    } catch (error) {
      console.error("Get API keys error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Create new API key
  app.post("/api/api-keys", authenticateFlexible, async (req, res) => {
    try {
      const { name } = req.body;
      
      if (!name || name.trim().length === 0) {
        return res.status(400).json({ message: "Nome da API key é obrigatório" });
      }

      // Generate a secure API key
      const apiKey = "mxc_" + nanoid(32);
      
      const newApiKey = await storage.createApiKey({
        name: name.trim(),
        key: apiKey,
        sellerId: req.user!.id,
        isActive: true
      });

      res.status(201).json({
        id: newApiKey.id,
        name: newApiKey.name,
        key: apiKey, // Only return the full key on creation
        isActive: newApiKey.isActive,
        createdAt: newApiKey.createdAt,
        message: "API key criada com sucesso. Guarde esta chave em local seguro, ela não será exibida novamente."
      });
    } catch (error) {
      console.error("Create API key error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Toggle API key active status
  app.patch("/api/api-keys/:id/toggle", authenticateFlexible, async (req, res) => {
    try {
      const keyId = parseInt(req.params.id);
      const { isActive } = req.body;

      if (typeof isActive !== 'boolean') {
        return res.status(400).json({ message: "Status deve ser true ou false" });
      }

      // Check if user owns this API key
      const apiKeys = await storage.getApiKeysBySeller(req.user!.id);
      const apiKey = apiKeys.find(key => key.id === keyId);
      
      if (!apiKey) {
        return res.status(404).json({ message: "API key não encontrada" });
      }

      const success = await storage.toggleApiKey(keyId, isActive);
      
      if (success) {
        res.json({ 
          message: `API key ${isActive ? 'ativada' : 'desativada'} com sucesso`,
          isActive 
        });
      } else {
        res.status(404).json({ message: "API key não encontrada" });
      }
    } catch (error) {
      console.error("Toggle API key error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Delete API key
  app.delete("/api/api-keys/:id", authenticateFlexible, async (req, res) => {
    try {
      const keyId = parseInt(req.params.id);

      // Check if user owns this API key
      const apiKeys = await storage.getApiKeysBySeller(req.user!.id);
      const apiKey = apiKeys.find(key => key.id === keyId);
      
      if (!apiKey) {
        return res.status(404).json({ message: "API key não encontrada" });
      }

      const success = await storage.deleteApiKey(keyId);
      
      if (success) {
        res.json({ message: "API key deletada com sucesso" });
      } else {
        res.status(404).json({ message: "API key não encontrada" });
      }
    } catch (error) {
      console.error("Delete API key error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Update existing routes to use flexible authentication
  // This allows both session and token authentication

  const httpServer = createServer(app);
  return httpServer;
}
