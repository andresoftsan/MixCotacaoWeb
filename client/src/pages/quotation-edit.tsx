import { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { queryClient } from "@/lib/queryClient";
import { useRoute, useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination";
import { ArrowLeft, Send, Search } from "lucide-react";
import { Quotation, QuotationItem } from "@/lib/types";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function QuotationEditPage() {
  const [match, params] = useRoute("/cotacoes/editar/:id");
  const [, setLocation] = useLocation();
  const { toast } = useToast();
  const [items, setItems] = useState<QuotationItem[]>([]);
  const [saveTimeouts, setSaveTimeouts] = useState<Map<number, NodeJS.Timeout>>(new Map());
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 20;

  const quotationId = params?.id ? parseInt(params.id) : null;

  const { data: quotation, isLoading: quotationLoading, error: quotationError } = useQuery<Quotation>({
    queryKey: [`/api/quotations/${quotationId}`],
    enabled: !!quotationId,
  });

  const { data: quotationItems, isLoading: itemsLoading } = useQuery<QuotationItem[]>({
    queryKey: [`/api/quotations/${quotationId}/items`],
    enabled: !!quotationId,
  });

  useEffect(() => {
    if (quotationItems) {
      // Initialize items with correct situation based on quantities
      const itemsWithCorrectSituation = quotationItems.map(item => {
        const availableQty = item.availableQuantity;
        const quotedQty = item.quotedQuantity;
        
        let situation = item.situation;
        // Only consider null/undefined as "Indisponível", allow 0 as valid quantity
        if (availableQty === null || availableQty === undefined) {
          situation = 'Indisponível';
        } else if (availableQty >= quotedQty) {
          situation = 'Disponível';
        } else if (availableQty < quotedQty && availableQty >= 0) {
          situation = 'Parcial';
        }
        
        return { ...item, situation };
      });
      
      setItems(itemsWithCorrectSituation);
    }
  }, [quotationItems]);

  // Filter items based on search term
  const filteredItems = useMemo(() => {
    if (!items) return [];
    if (!searchTerm.trim()) return items;

    return items.filter((item) =>
      item.barcode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.productName.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [items, searchTerm]);

  // Pagination calculations
  const totalPages = Math.ceil(filteredItems.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentItems = filteredItems.slice(startIndex, endIndex);

  // Reset to page 1 when search changes
  const handleSearchChange = (value: string) => {
    setSearchTerm(value);
    setCurrentPage(1);
  };

  const updateItemMutation = useMutation({
    mutationFn: async ({ itemId, data }: { itemId: number; data: any }) => {
      const response = await fetch(`/api/quotation-items/${itemId}`, {
        method: "PATCH",
        body: JSON.stringify(data),
        headers: { "Content-Type": "application/json" },
      });
      if (!response.ok) {
        throw new Error('Failed to update item');
      }
      return response.json();
    },
    onMutate: async ({ itemId, data }) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: [`/api/quotations/${quotationId}/items`] });
      
      // Snapshot the previous value
      const previousItems = queryClient.getQueryData([`/api/quotations/${quotationId}/items`]);
      
      // Optimistically update to the new value
      queryClient.setQueryData([`/api/quotations/${quotationId}/items`], (old: QuotationItem[] | undefined) => {
        if (!old) return old;
        return old.map(item => 
          item.id === itemId ? { ...item, ...data } : item
        );
      });
      
      return { previousItems };
    },
    onError: (error: any, variables, context) => {
      // Rollback on error
      if (context?.previousItems) {
        queryClient.setQueryData([`/api/quotations/${quotationId}/items`], context.previousItems);
      }
      toast({
        title: "Erro",
        description: error.message || "Erro ao atualizar item",
        variant: "destructive",
      });
    },
    onSuccess: (updatedItem) => {
      // Update local state without refetching to maintain order
      setItems(prevItems => 
        prevItems.map(item => 
          item.id === updatedItem.id ? updatedItem : item
        )
      );
    },
  });

  const validateQuotationBeforeSend = () => {
    const errors: string[] = [];
    
    // Check for items with available quantity but missing or zero unit price
    const itemsWithQuantityButNoPrice = items.filter(item => {
      const hasAvailableQuantity = item.availableQuantity !== null && item.availableQuantity !== undefined && item.availableQuantity > 0;
      
      // Check if price is missing, empty, or zero
      let invalidPrice = false;
      if (!item.unitPrice || item.unitPrice.trim() === '') {
        invalidPrice = true;
      } else {
        try {
          const priceValue = parseFloat(item.unitPrice.replace(',', '.'));
          if (isNaN(priceValue) || priceValue <= 0) {
            invalidPrice = true;
          }
        } catch (e) {
          invalidPrice = true;
        }
      }
      
      return hasAvailableQuantity && invalidPrice;
    });

    // Check for items with unit price but missing or zero available quantity
    const itemsWithPriceButNoQuantity = items.filter(item => {
      if (!item.unitPrice || item.unitPrice.trim() === '') {
        return false;
      }
      
      let priceValue = 0;
      try {
        priceValue = parseFloat(item.unitPrice.replace(',', '.'));
      } catch (e) {
        return false;
      }
      
      const hasPriceGreaterThanZero = !isNaN(priceValue) && priceValue > 0;
      const missingOrZeroQuantity = item.availableQuantity === null || item.availableQuantity === undefined || item.availableQuantity === 0;
      
      return hasPriceGreaterThanZero && missingOrZeroQuantity;
    });

    if (itemsWithQuantityButNoPrice.length > 0) {
      const itemDetails = itemsWithQuantityButNoPrice.map(item => `${item.productName} (${item.barcode})`).join(', ');
      errors.push(`Itens com quantidade disponível mas sem preço unitário válido (maior que zero): ${itemDetails}`);
    }

    if (itemsWithPriceButNoQuantity.length > 0) {
      const itemDetails = itemsWithPriceButNoQuantity.map(item => `${item.productName} (${item.barcode})`).join(', ');
      errors.push(`Itens com preço unitário mas sem quantidade disponível: ${itemDetails}`);
    }

    if (errors.length > 0) {
      toast({
        title: "Validação necessária",
        description: errors.join('. '),
        variant: "destructive",
      });
      return false;
    }
    return true;
  };

  const handleSendQuotation = () => {
    // Validate before sending
    if (!validateQuotationBeforeSend()) {
      return; // Stop execution if validation fails
    }
    
    // If validation passes, proceed with sending
    sendQuotationMutation.mutate();
  };

  const sendQuotationMutation = useMutation({
    mutationFn: async () => {
      const response = await fetch(`/api/quotations/${quotationId}`, {
        method: "PUT",
        body: JSON.stringify({ status: "Enviada" }),
        headers: { "Content-Type": "application/json" },
      });
      if (!response.ok) {
        throw new Error('Failed to send quotation');
      }
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/quotations/${quotationId}`] });
      queryClient.invalidateQueries({ queryKey: ["/api/quotations"] });
      queryClient.invalidateQueries({ queryKey: ["/api/dashboard/stats"] });
      toast({
        title: "Sucesso",
        description: "Cotação enviada com sucesso",
      });
      setLocation("/cotacoes");
    },
    onError: (error: any) => {
      toast({
        title: "Erro",
        description: error.message || "Erro ao enviar cotação",
        variant: "destructive",
      });
    },
  });

  const handleItemChange = (itemId: number, field: string, value: string | number | null | undefined) => {
    const updatedItems = items.map(item => {
      if (item.id === itemId) {
        const updatedItem = { ...item, [field]: value };
        
        // Auto-update situation based on availableQuantity vs quotedQuantity
        if (field === 'availableQuantity') {
          const quotedQty = item.quotedQuantity;
          
          // Handle null/undefined/0 as "Indisponível"
          if (value === null || value === undefined) {
            updatedItem.situation = 'Indisponível';
          } else {
            const availableQty = typeof value === 'number' ? value : parseInt(value as string);
            if (isNaN(availableQty) || availableQty === 0) {
              updatedItem.situation = 'Indisponível';
            } else if (availableQty >= quotedQty) {
              updatedItem.situation = 'Disponível';
            } else {
              updatedItem.situation = 'Parcial';
            }
          }
        }
        
        return updatedItem;
      }
      return item;
    });
    
    setItems(updatedItems);
    
    // Clear existing timeout for this item
    const existingTimeout = saveTimeouts.get(itemId);
    if (existingTimeout) {
      clearTimeout(existingTimeout);
    }
    
    // Set new timeout for auto-save
    const newTimeout = setTimeout(() => {
      const updatedItem = updatedItems.find(item => item.id === itemId);
      if (updatedItem) {
        handleSaveItem(updatedItem);
      }
      setSaveTimeouts(prev => {
        const newMap = new Map(prev);
        newMap.delete(itemId);
        return newMap;
      });
    }, 1000);
    
    setSaveTimeouts(prev => {
      const newMap = new Map(prev);
      newMap.set(itemId, newTimeout);
      return newMap;
    });
  };

  const handleSaveItem = (item: QuotationItem) => {
    // Convert comma to dot for decimal prices
    const normalizedPrice = item.unitPrice ? item.unitPrice.replace(',', '.') : undefined;
    
    const updateData = {
      availableQuantity: item.availableQuantity === null ? null : item.availableQuantity,
      unitPrice: normalizedPrice,
      validity: item.validity || undefined,
      situation: item.situation || undefined,
    };

    updateItemMutation.mutate({ itemId: item.id, data: updateData });
  };



  const handleBack = () => {
    setLocation("/cotacoes");
  };

  if (!match || !quotationId) {
    return <div>Cotação não encontrada</div>;
  }

  if (quotationLoading || itemsLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!quotation) {
    return <div>Cotação não encontrada</div>;
  }

  // Bloquear edição quando status for "Enviada" ou "Prazo Encerrado"
  const isEditable = quotation?.status === "Aguardando digitação";

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <Button variant="ghost" onClick={handleBack}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar
          </Button>
          <h1 className="text-2xl font-bold">
            {isEditable ? "Editar" : "Visualizar"} Cotação {quotation.number}
          </h1>
        </div>
        {isEditable && (
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button disabled={sendQuotationMutation.isPending}>
                <Send className="h-4 w-4 mr-2" />
                Enviar Cotação
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Confirmar envio</AlertDialogTitle>
                <AlertDialogDescription>
                  Deseja realmente enviar esta cotação? Após o envio, não será possível editar os dados.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Não</AlertDialogCancel>
                <AlertDialogAction onClick={handleSendQuotation}>
                  Sim, Enviar
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Informações da Cotação</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Número</Label>
                <Input value={quotation.number} disabled />
              </div>
              <div>
                <Label>Status</Label>
                <Input value={quotation.status} disabled />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Data</Label>
                <Input value={new Date(quotation.date).toLocaleDateString("pt-BR")} disabled />
              </div>
              <div>
                <Label>Prazo</Label>
                <Input value={new Date(quotation.deadline).toLocaleDateString("pt-BR")} disabled />
              </div>
            </div>
            <div>
              <Label>Fornecedor</Label>
              <Input value={`${quotation.supplierName} (${quotation.supplierCnpj})`} disabled />
            </div>
            <div>
              <Label>Cliente</Label>
              <Input value={`${quotation.clientName} (${quotation.clientCnpj})`} disabled />
            </div>
            {quotation.internalObservation && (
              <div>
                <Label>Observação Interna</Label>
                <Textarea value={quotation.internalObservation} disabled />
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Resumo dos Itens</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Total de itens:</span>
                <span className="font-semibold">{items.length}</span>
              </div>
              <div className="flex justify-between">
                <span>Disponíveis:</span>
                <span className="text-green-600 font-semibold">
                  {items.filter(item => item.situation === "Disponível").length}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Parciais:</span>
                <span className="text-yellow-600 font-semibold">
                  {items.filter(item => item.situation === "Parcial").length}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Indisponíveis:</span>
                <span className="text-red-600 font-semibold">
                  {items.filter(item => item.situation === "Indisponível").length}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Itens da Cotação</CardTitle>
            <div className="text-sm text-gray-600">
              {filteredItems.length} de {items.length} itens
            </div>
          </div>
          
          {/* Search Filter */}
          <div className="flex items-center space-x-2 mt-4">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-2 top-2.5 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Buscar por código de barras ou produto..."
                value={searchTerm}
                onChange={(e) => handleSearchChange(e.target.value)}
                className="pl-8"
                disabled={!isEditable}
              />
            </div>
            {searchTerm && (
              <Button
                variant="outline"
                onClick={() => handleSearchChange("")}
                size="sm"
                disabled={!isEditable}
              >
                Limpar
              </Button>
            )}
          </div>

          {searchTerm && (
            <div className="text-sm text-gray-600 mt-2">
              Mostrando {filteredItems.length} resultado(s) para "{searchTerm}"
            </div>
          )}
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="min-w-[120px]">Código de Barras</TableHead>
                  <TableHead className="min-w-[250px]">Produto</TableHead>
                  <TableHead className="min-w-[100px]">Qtd. Solicitada</TableHead>
                  <TableHead className="min-w-[120px]">Qtd. Disponível</TableHead>
                  <TableHead className="min-w-[110px]">Preço Unitário</TableHead>
                  <TableHead className="min-w-[120px]">Validade</TableHead>
                  <TableHead className="min-w-[120px]">Situação</TableHead>
                </TableRow>
              </TableHeader>
            <TableBody>
              {currentItems.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-8 text-gray-500">
                    {searchTerm ? "Nenhum item encontrado para a busca" : "Nenhum item encontrado"}
                  </TableCell>
                </TableRow>
              ) : (
                currentItems.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell className="font-mono text-sm">{item.barcode}</TableCell>
                    <TableCell className="min-w-[250px] max-w-[400px]">
                      <div className="whitespace-normal break-words text-sm leading-tight">
                        {item.productName}
                      </div>
                    </TableCell>
                    <TableCell>{item.quotedQuantity}</TableCell>
                    <TableCell>
                      <Input
                        type="text"
                        value={item.availableQuantity === null || item.availableQuantity === undefined ? '' : item.availableQuantity.toString()}
                        onChange={(e) => {
                          const value = e.target.value;
                          
                          // Only allow numbers (including 0) and empty string
                          if (value !== '' && !/^\d*$/.test(value)) {
                            return;
                          }
                          
                          // Handle empty string as null, but allow "0" as valid
                          let numValue: number | null;
                          if (value === '') {
                            numValue = null;
                          } else {
                            const parsed = parseInt(value);
                            // Check if parsed value is valid and not greater than quoted quantity
                            if (isNaN(parsed) || parsed < 0 || parsed > item.quotedQuantity) {
                              return; // Don't update if invalid
                            }
                            numValue = parsed;
                          }
                          
                          handleItemChange(item.id, 'availableQuantity', numValue);
                        }}
                        placeholder="Quantidade"
                        className="w-24"
                        disabled={!isEditable}
                      />
                    </TableCell>
                    <TableCell>
                      <Input
                        value={item.unitPrice || ''}
                        onChange={(e) => {
                          // Allow both comma and dot as decimal separators during typing
                          const value = e.target.value.replace(/[^\d,.-]/g, '');
                          handleItemChange(item.id, 'unitPrice', value);
                        }}
                        placeholder="R$ 0,00"
                        className="w-24"
                        disabled={!isEditable}
                      />
                    </TableCell>
                    <TableCell>
                      <Input
                        type="date"
                        value={item.validity ? item.validity.split('T')[0] : ''}
                        onChange={(e) => handleItemChange(item.id, 'validity', e.target.value)}
                        className="w-32"
                        disabled={!isEditable}
                      />
                    </TableCell>
                    <TableCell>
                      <span className={`px-2 py-1 rounded text-xs font-medium ${
                        item.situation === 'Disponível' ? 'bg-green-100 text-green-800' :
                        item.situation === 'Parcial' ? 'bg-yellow-100 text-yellow-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {item.situation || 'Indisponível'}
                      </span>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
            </Table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-4">
              <div className="text-sm text-gray-700">
                Mostrando {startIndex + 1} a {Math.min(endIndex, filteredItems.length)} de {filteredItems.length} itens
              </div>
              <Pagination>
                <PaginationContent>
                  <PaginationItem>
                    <PaginationPrevious 
                      onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                      className={currentPage === 1 ? "pointer-events-none opacity-50" : "cursor-pointer"}
                    />
                  </PaginationItem>
                  
                  {/* Page numbers */}
                  {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                    let pageNum;
                    if (totalPages <= 5) {
                      pageNum = i + 1;
                    } else if (currentPage <= 3) {
                      pageNum = i + 1;
                    } else if (currentPage >= totalPages - 2) {
                      pageNum = totalPages - 4 + i;
                    } else {
                      pageNum = currentPage - 2 + i;
                    }
                    
                    return (
                      <PaginationItem key={pageNum}>
                        <PaginationLink
                          onClick={() => setCurrentPage(pageNum)}
                          isActive={currentPage === pageNum}
                          className="cursor-pointer"
                        >
                          {pageNum}
                        </PaginationLink>
                      </PaginationItem>
                    );
                  })}

                  {totalPages > 5 && currentPage < totalPages - 2 && (
                    <PaginationItem>
                      <PaginationEllipsis />
                    </PaginationItem>
                  )}

                  <PaginationItem>
                    <PaginationNext 
                      onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                      className={currentPage === totalPages ? "pointer-events-none opacity-50" : "cursor-pointer"}
                    />
                  </PaginationItem>
                </PaginationContent>
              </Pagination>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}