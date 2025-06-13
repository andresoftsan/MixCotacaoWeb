import { pgTable, text, serial, integer, boolean, timestamp, decimal, varchar } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const sellers = pgTable("sellers", {
  id: serial("id").primaryKey(),
  email: text("email").notNull().unique(),
  name: text("name").notNull(),
  password: text("password").notNull(),
  status: text("status").notNull().default("Ativo"), // "Ativo" | "Inativo"
  createdAt: timestamp("created_at").defaultNow(),
});

export const quotations = pgTable("quotations", {
  id: serial("id").primaryKey(),
  number: text("number").notNull().unique(),
  date: timestamp("date").notNull().defaultNow(),
  status: text("status").notNull().default("Aguardando digitação"), // "Aguardando digitação" | "Prazo Encerrado" | "Enviada"
  deadline: timestamp("deadline").notNull(),
  supplierCnpj: text("supplier_cnpj").notNull(),
  supplierName: text("supplier_name").notNull(),
  clientCnpj: text("client_cnpj").notNull(),
  clientName: text("client_name").notNull(),
  internalObservation: text("internal_observation"),
  sellerId: integer("seller_id").references(() => sellers.id).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});

export const apiKeys = pgTable("api_keys", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  key: text("key").notNull().unique(),
  sellerId: integer("seller_id").references(() => sellers.id).notNull(),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
  lastUsedAt: timestamp("last_used_at"),
});

export const quotationItems = pgTable("quotation_items", {
  id: serial("id").primaryKey(),
  quotationId: integer("quotation_id").references(() => quotations.id).notNull(),
  barcode: text("barcode").notNull(),
  productName: text("product_name").notNull(),
  quotedQuantity: integer("quoted_quantity").notNull(),
  availableQuantity: integer("available_quantity"),
  unitPrice: decimal("unit_price", { precision: 10, scale: 2 }),
  validity: timestamp("validity"),
  situation: text("situation"), // "Disponível" | "Indisponível" | "Parcial"
});

export const insertSellerSchema = createInsertSchema(sellers).omit({
  id: true,
  createdAt: true,
});

export const insertQuotationSchema = createInsertSchema(quotations).omit({
  id: true,
  createdAt: true,
  number: true,
  sellerId: true,
}).extend({
  date: z.string().transform(str => new Date(str)),
  deadline: z.string().transform(str => new Date(str)),
});

export const insertQuotationItemSchema = createInsertSchema(quotationItems).omit({
  id: true,
}).extend({
  validity: z.string().datetime().transform(str => new Date(str)).optional(),
});

export const updateQuotationItemSchema = createInsertSchema(quotationItems).omit({
  id: true,
  quotationId: true,
  barcode: true,
  productName: true,
  quotedQuantity: true,
}).extend({
  validity: z.string().transform(str => str ? new Date(str) : null).optional(),
}).partial();

export const insertApiKeySchema = createInsertSchema(apiKeys).omit({
  id: true,
  createdAt: true,
  lastUsedAt: true,
});

export type InsertSeller = z.infer<typeof insertSellerSchema>;
export type Seller = typeof sellers.$inferSelect;

export type InsertQuotation = z.infer<typeof insertQuotationSchema>;
export type Quotation = typeof quotations.$inferSelect;

export type InsertQuotationItem = z.infer<typeof insertQuotationItemSchema>;
export type QuotationItem = typeof quotationItems.$inferSelect;

export type UpdateQuotationItem = z.infer<typeof updateQuotationItemSchema>;

export type InsertApiKey = z.infer<typeof insertApiKeySchema>;
export type ApiKey = typeof apiKeys.$inferSelect;
