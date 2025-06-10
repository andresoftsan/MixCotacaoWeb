export interface Seller {
  id: number;
  email: string;
  name: string;
  status: "Ativo" | "Inativo";
  createdAt: string;
}

export interface Quotation {
  id: number;
  number: string;
  date: string;
  status: "Aguardando digitação" | "Prazo Encerrado" | "Enviada";
  deadline: string;
  supplierCnpj: string;
  supplierName: string;
  clientCnpj: string;
  clientName: string;
  internalObservation?: string;
  sellerId: number;
  createdAt: string;
}

export interface QuotationItem {
  id: number;
  quotationId: number;
  barcode: string;
  productName: string;
  quotedQuantity: number;
  availableQuantity?: number;
  unitPrice?: string;
  validity?: string;
  situation?: "Disponível" | "Indisponível" | "Parcial";
}

export interface DashboardStats {
  total: number;
  aguardandoDigitacao: number;
  enviadas: number;
  prazoEncerrado: number;
}
