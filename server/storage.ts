import { sellers, quotations, quotationItems, apiKeys, type Seller, type InsertSeller, type Quotation, type InsertQuotation, type QuotationItem, type InsertQuotationItem, type UpdateQuotationItem, type ApiKey, type InsertApiKey } from "@shared/schema";
import { db } from "./db";
import { eq, desc, and, lt, like } from "drizzle-orm";

export interface IStorage {
  // Sellers
  getSeller(id: number): Promise<Seller | undefined>;
  getSellerByEmail(email: string): Promise<Seller | undefined>;
  getSellersByName(name: string): Promise<Seller[]>;
  createSeller(seller: InsertSeller): Promise<Seller>;
  updateSeller(id: number, seller: Partial<InsertSeller>): Promise<Seller | undefined>;
  getAllSellers(): Promise<Seller[]>;
  deleteSeller(id: number): Promise<boolean>;

  // Quotations
  getQuotation(id: number): Promise<Quotation | undefined>;
  getQuotationsBySeller(sellerId: number): Promise<Quotation[]>;
  getAllQuotations(): Promise<Quotation[]>;
  getQuotationByClientCnpjAndNumber(clientCnpj: string, number: string): Promise<Quotation | undefined>;
  createQuotation(quotation: InsertQuotation): Promise<Quotation>;
  updateQuotation(id: number, quotation: Partial<InsertQuotation>): Promise<Quotation | undefined>;
  deleteQuotation(id: number): Promise<boolean>;

  // Quotation Items
  getQuotationItems(quotationId: number): Promise<QuotationItem[]>;
  createQuotationItem(item: InsertQuotationItem): Promise<QuotationItem>;
  updateQuotationItem(id: number, item: UpdateQuotationItem): Promise<QuotationItem | undefined>;
  deleteQuotationItem(id: number): Promise<boolean>;

  // Dashboard Stats
  getSellerQuotationStats(sellerId: number): Promise<{
    total: number;
    aguardandoDigitacao: number;
    enviadas: number;
    prazoEncerrado: number;
  }>;

  // Update expired quotations
  updateExpiredQuotations(): Promise<void>;

  // API Keys
  getApiKey(key: string): Promise<ApiKey | undefined>;
  getApiKeysBySeller(sellerId: number): Promise<ApiKey[]>;
  createApiKey(apiKey: InsertApiKey): Promise<ApiKey>;
  updateApiKeyLastUsed(id: number): Promise<void>;
  deleteApiKey(id: number): Promise<boolean>;
  toggleApiKey(id: number, isActive: boolean): Promise<boolean>;
}

export class DatabaseStorage implements IStorage {
  async getSeller(id: number): Promise<Seller | undefined> {
    const [seller] = await db.select().from(sellers).where(eq(sellers.id, id));
    return seller || undefined;
  }

  async getSellerByEmail(email: string): Promise<Seller | undefined> {
    const [seller] = await db.select().from(sellers).where(eq(sellers.email, email));
    return seller || undefined;
  }

  async getSellersByName(name: string): Promise<Seller[]> {
    return await db
      .select()
      .from(sellers)
      .where(like(sellers.name, `%${name}%`));
  }

  async createSeller(insertSeller: InsertSeller): Promise<Seller> {
    const [seller] = await db
      .insert(sellers)
      .values(insertSeller)
      .returning();
    return seller;
  }

  async updateSeller(id: number, sellerData: Partial<InsertSeller>): Promise<Seller | undefined> {
    const [seller] = await db
      .update(sellers)
      .set(sellerData)
      .where(eq(sellers.id, id))
      .returning();
    return seller || undefined;
  }

  async getAllSellers(): Promise<Seller[]> {
    return await db.select().from(sellers).orderBy(sellers.name);
  }

  async deleteSeller(id: number): Promise<boolean> {
    const result = await db.delete(sellers).where(eq(sellers.id, id));
    return (result.rowCount ?? 0) > 0;
  }

  async getQuotation(id: number): Promise<Quotation | undefined> {
    const [quotation] = await db.select().from(quotations).where(eq(quotations.id, id));
    return quotation || undefined;
  }

  async getQuotationsBySeller(sellerId: number): Promise<Quotation[]> {
    // First update expired quotations
    await this.updateExpiredQuotations();
    
    return await db
      .select()
      .from(quotations)
      .where(eq(quotations.sellerId, sellerId))
      .orderBy(desc(quotations.createdAt));
  }

  async getAllQuotations(): Promise<Quotation[]> {
    // First update expired quotations
    await this.updateExpiredQuotations();
    
    return await db
      .select()
      .from(quotations)
      .orderBy(desc(quotations.createdAt));
  }

  async getQuotationByClientCnpjAndNumber(clientCnpj: string, number: string): Promise<Quotation | undefined> {
    await this.updateExpiredQuotations();
    
    const [quotation] = await db
      .select()
      .from(quotations)
      .where(and(eq(quotations.clientCnpj, clientCnpj), eq(quotations.number, number)));
    return quotation || undefined;
  }

  async createQuotation(insertQuotation: InsertQuotation): Promise<Quotation> {
    const [quotation] = await db
      .insert(quotations)
      .values(insertQuotation)
      .returning();
    return quotation;
  }

  async updateQuotation(id: number, quotationData: Partial<InsertQuotation>): Promise<Quotation | undefined> {
    const [quotation] = await db
      .update(quotations)
      .set(quotationData)
      .where(eq(quotations.id, id))
      .returning();
    return quotation || undefined;
  }

  async deleteQuotation(id: number): Promise<boolean> {
    // First delete all quotation items
    await db.delete(quotationItems).where(eq(quotationItems.quotationId, id));
    
    // Then delete the quotation
    const result = await db.delete(quotations).where(eq(quotations.id, id));
    return (result.rowCount ?? 0) > 0;
  }

  async getQuotationItems(quotationId: number): Promise<QuotationItem[]> {
    return await db
      .select()
      .from(quotationItems)
      .where(eq(quotationItems.quotationId, quotationId));
  }

  async createQuotationItem(insertItem: InsertQuotationItem): Promise<QuotationItem> {
    const [item] = await db
      .insert(quotationItems)
      .values(insertItem)
      .returning();
    return item;
  }

  async updateQuotationItem(id: number, itemData: UpdateQuotationItem): Promise<QuotationItem | undefined> {
    const [item] = await db
      .update(quotationItems)
      .set(itemData)
      .where(eq(quotationItems.id, id))
      .returning();
    return item || undefined;
  }

  async deleteQuotationItem(id: number): Promise<boolean> {
    const result = await db.delete(quotationItems).where(eq(quotationItems.id, id));
    return (result.rowCount ?? 0) > 0;
  }

  async getSellerQuotationStats(sellerId: number): Promise<{
    total: number;
    aguardandoDigitacao: number;
    enviadas: number;
    prazoEncerrado: number;
  }> {
    // First update expired quotations
    await this.updateExpiredQuotations();
    
    // Check if user is admin to show all quotations or just their own
    const seller = await this.getSeller(sellerId);
    const isAdmin = seller?.email === "administrador@softsan.com.br";
    
    let allQuotations;
    if (isAdmin) {
      // Admin sees all quotations
      allQuotations = await db.select().from(quotations);
    } else {
      // Regular sellers see only their quotations
      allQuotations = await db
        .select()
        .from(quotations)
        .where(eq(quotations.sellerId, sellerId));
    }

    const total = allQuotations.length;
    const aguardandoDigitacao = allQuotations.filter(q => q.status === "Aguardando digitação").length;
    const enviadas = allQuotations.filter(q => q.status === "Enviada").length;
    const prazoEncerrado = allQuotations.filter(q => q.status === "Prazo Encerrado").length;

    return {
      total,
      aguardandoDigitacao,
      enviadas,
      prazoEncerrado
    };
  }

  async updateExpiredQuotations(): Promise<void> {
    const now = new Date();
    
    await db
      .update(quotations)
      .set({ status: "Prazo Encerrado" })
      .where(
        and(
          lt(quotations.deadline, now),
          eq(quotations.status, "Aguardando digitação")
        )
      );
  }

  // API Keys methods
  async getApiKey(key: string): Promise<ApiKey | undefined> {
    const [apiKey] = await db.select().from(apiKeys).where(eq(apiKeys.key, key));
    return apiKey || undefined;
  }

  async getApiKeysBySeller(sellerId: number): Promise<ApiKey[]> {
    return await db.select().from(apiKeys).where(eq(apiKeys.sellerId, sellerId)).orderBy(desc(apiKeys.createdAt));
  }

  async createApiKey(insertApiKey: InsertApiKey): Promise<ApiKey> {
    const [apiKey] = await db.insert(apiKeys).values(insertApiKey).returning();
    return apiKey;
  }

  async updateApiKeyLastUsed(id: number): Promise<void> {
    await db.update(apiKeys).set({ lastUsedAt: new Date() }).where(eq(apiKeys.id, id));
  }

  async deleteApiKey(id: number): Promise<boolean> {
    const result = await db.delete(apiKeys).where(eq(apiKeys.id, id));
    return result.rowCount > 0;
  }

  async toggleApiKey(id: number, isActive: boolean): Promise<boolean> {
    const result = await db.update(apiKeys).set({ isActive }).where(eq(apiKeys.id, id));
    return result.rowCount > 0;
  }
}

export const storage = new DatabaseStorage();
