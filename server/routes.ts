import type { Express } from "express";
import { createServer, type Server } from "http";
import session from "express-session";
import { storage } from "./storage";
import bcrypt from "bcrypt";
import { insertSellerSchema, insertQuotationSchema, insertQuotationItemSchema, updateQuotationItemSchema } from "@shared/schema";

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
  app.get("/api/auth/me", requireAuth, async (req, res) => {
    try {
      const seller = await storage.getSeller(req.session.userId!);
      if (!seller) {
        return res.status(404).json({ message: "Usuário não encontrado" });
      }

      res.json({
        id: seller.id,
        name: seller.name,
        email: seller.email,
        isAdmin: seller.email === "administrador@softsan.com.br"
      });
    } catch (error) {
      console.error("Get user error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  // Sellers routes
  app.get("/api/sellers", requireAuth, async (req, res) => {
    try {
      if (!req.session.isAdmin) {
        return res.status(403).json({ message: "Acesso negado" });
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

  app.post("/api/sellers", requireAdmin, async (req, res) => {
    try {
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

  app.put("/api/sellers/:id", requireAdmin, async (req, res) => {
    try {
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

  app.delete("/api/sellers/:id", requireAdmin, async (req, res) => {
    try {
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
  app.get("/api/quotations", requireAuth, async (req, res) => {
    try {
      let quotations;
      
      if (req.session.isAdmin) {
        quotations = await storage.getAllQuotations();
      } else {
        quotations = await storage.getQuotationsBySeller(req.session.userId!);
      }

      res.json(quotations);
    } catch (error) {
      console.error("Get quotations error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.get("/api/quotations/:id", requireAuth, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const quotation = await storage.getQuotation(id);
      
      if (!quotation) {
        return res.status(404).json({ message: "Cotação não encontrada" });
      }

      // Check if user can access this quotation
      if (!req.session.isAdmin && quotation.sellerId !== req.session.userId) {
        return res.status(403).json({ message: "Acesso negado" });
      }

      res.json(quotation);
    } catch (error) {
      console.error("Get quotation error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.post("/api/quotations", requireAuth, async (req, res) => {
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
        sellerId: req.session.userId!
      });

      res.json(quotation);
    } catch (error) {
      console.error("Create quotation error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.put("/api/quotations/:id", requireAuth, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const quotationData = insertQuotationSchema.partial().parse(req.body);

      const existingQuotation = await storage.getQuotation(id);
      if (!existingQuotation) {
        return res.status(404).json({ message: "Cotação não encontrada" });
      }

      // Check if user can update this quotation
      if (!req.session.isAdmin && existingQuotation.sellerId !== req.session.userId) {
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
  app.get("/api/quotations/:id/items", requireAuth, async (req, res) => {
    try {
      const quotationId = parseInt(req.params.id);
      
      const quotation = await storage.getQuotation(quotationId);
      if (!quotation) {
        return res.status(404).json({ message: "Cotação não encontrada" });
      }

      // Check if user can access this quotation
      if (!req.session.isAdmin && quotation.sellerId !== req.session.userId) {
        return res.status(403).json({ message: "Acesso negado" });
      }

      const items = await storage.getQuotationItems(quotationId);
      res.json(items);
    } catch (error) {
      console.error("Get quotation items error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.post("/api/quotations/:id/items", requireAuth, async (req, res) => {
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
      if (!req.session.isAdmin && quotation.sellerId !== req.session.userId) {
        return res.status(403).json({ message: "Acesso negado" });
      }

      const item = await storage.createQuotationItem(itemData);
      res.json(item);
    } catch (error) {
      console.error("Create quotation item error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  app.patch("/api/quotation-items/:id", requireAuth, async (req, res) => {
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
  app.get("/api/dashboard/stats", requireAuth, async (req, res) => {
    try {
      const stats = await storage.getSellerQuotationStats(req.session.userId!);
      res.json(stats);
    } catch (error) {
      console.error("Get dashboard stats error:", error);
      res.status(500).json({ message: "Erro interno do servidor" });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}
