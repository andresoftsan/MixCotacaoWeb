import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Quotation, QuotationItem } from "@/lib/types";

interface QuotationDetailModalProps {
  quotationId: number;
  onClose: () => void;
}

export default function QuotationDetailModal({
  quotationId,
  onClose,
}: QuotationDetailModalProps) {
  const [internalObservation, setInternalObservation] = useState("");
  const { toast } = useToast();

  const { data: quotation, isLoading: quotationLoading } = useQuery<Quotation>({
    queryKey: [`/api/quotations/${quotationId}`],
  });

  const { data: items, isLoading: itemsLoading } = useQuery<QuotationItem[]>({
    queryKey: [`/api/quotations/${quotationId}/items`],
  });

  const updateItemMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: any }) =>
      apiRequest("PATCH", `/api/quotation-items/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: [`/api/quotations/${quotationId}/items`],
      });
    },
  });

  const updateQuotationMutation = useMutation({
    mutationFn: (data: any) =>
      apiRequest("PUT", `/api/quotations/${quotationId}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/quotations"] });
      queryClient.invalidateQueries({
        queryKey: [`/api/quotations/${quotationId}`],
      });
      toast({
        title: "Cotação atualizada",
        description: "Cotação atualizada com sucesso.",
      });
    },
  });

  const handleItemUpdate = (itemId: number, field: string, value: any) => {
    updateItemMutation.mutate({
      id: itemId,
      data: { [field]: value },
    });
  };

  const handleSaveQuotation = () => {
    updateQuotationMutation.mutate({
      internalObservation,
    });
  };

  const handleSendQuotation = () => {
    updateQuotationMutation.mutate({
      status: "Enviada",
      internalObservation,
    });
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("pt-BR");
  };

  if (quotationLoading || itemsLoading) {
    return (
      <Dialog open={true} onOpenChange={onClose}>
        <DialogContent className="max-w-6xl max-h-[90vh] overflow-y-auto">
          <div className="animate-pulse space-y-4">
            <div className="h-6 bg-gray-200 rounded w-1/3"></div>
            <div className="space-y-2">
              <div className="h-4 bg-gray-200 rounded"></div>
              <div className="h-4 bg-gray-200 rounded w-2/3"></div>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  if (!quotation) {
    return null;
  }

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="max-w-6xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            Detalhes da Cotação - {quotation.number}
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <Label>Fornecedor</Label>
                <p className="text-sm text-gray-900">
                  {quotation.supplierName} - {quotation.supplierCnpj}
                </p>
              </div>
              <div>
                <Label>Cliente</Label>
                <p className="text-sm text-gray-900">
                  {quotation.clientName} - {quotation.clientCnpj}
                </p>
              </div>
            </div>
            <div className="space-y-4">
              <div>
                <Label>Data da Cotação</Label>
                <p className="text-sm text-gray-900">
                  {formatDate(quotation.date)}
                </p>
              </div>
              <div>
                <Label>Prazo para Preenchimento</Label>
                <p className="text-sm text-gray-900">
                  {formatDate(quotation.deadline)}
                </p>
              </div>
            </div>
          </div>

          <div>
            <Label htmlFor="observation">Observação Interna</Label>
            <Textarea
              id="observation"
              placeholder="Observações internas sobre a cotação..."
              value={internalObservation || quotation.internalObservation || ""}
              onChange={(e) => setInternalObservation(e.target.value)}
              rows={3}
              disabled={quotation.status === "Enviada"}
            />
          </div>

          <div>
            <h4 className="text-md font-semibold text-gray-900 mb-4">
              Itens da Cotação
            </h4>
            <div className="border border-gray-200 rounded-lg overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow className="bg-gray-50">
                    <TableHead className="text-xs">Código de Barras</TableHead>
                    <TableHead className="text-xs">Produto</TableHead>
                    <TableHead className="text-xs">Qtd. Cotada</TableHead>
                    <TableHead className="text-xs">Qtd. Disponível</TableHead>
                    <TableHead className="text-xs">Valor Unit.</TableHead>
                    <TableHead className="text-xs">Validade</TableHead>
                    <TableHead className="text-xs">Situação</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {items?.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell className="text-sm">{item.barcode}</TableCell>
                      <TableCell className="text-sm">{item.productName}</TableCell>
                      <TableCell className="text-sm">{item.quotedQuantity}</TableCell>
                      <TableCell>
                        <Input
                          type="number"
                          className="w-20 text-sm"
                          value={item.availableQuantity || ""}
                          onChange={(e) =>
                            handleItemUpdate(
                              item.id,
                              "availableQuantity",
                              parseInt(e.target.value) || null
                            )
                          }
                          disabled={quotation.status === "Enviada"}
                        />
                      </TableCell>
                      <TableCell>
                        <Input
                          type="number"
                          step="0.01"
                          className="w-24 text-sm"
                          value={item.unitPrice || ""}
                          onChange={(e) =>
                            handleItemUpdate(item.id, "unitPrice", e.target.value)
                          }
                          disabled={quotation.status === "Enviada"}
                        />
                      </TableCell>
                      <TableCell>
                        <Input
                          type="date"
                          className="w-32 text-sm"
                          value={
                            item.validity
                              ? new Date(item.validity).toISOString().split("T")[0]
                              : ""
                          }
                          onChange={(e) =>
                            handleItemUpdate(
                              item.id,
                              "validity",
                              e.target.value || null
                            )
                          }
                          disabled={quotation.status === "Enviada"}
                        />
                      </TableCell>
                      <TableCell>
                        <Select
                          value={item.situation || ""}
                          onValueChange={(value) =>
                            handleItemUpdate(item.id, "situation", value)
                          }
                          disabled={quotation.status === "Enviada"}
                        >
                          <SelectTrigger className="w-24 text-sm">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="Disponível">Disponível</SelectItem>
                            <SelectItem value="Indisponível">Indisponível</SelectItem>
                            <SelectItem value="Parcial">Parcial</SelectItem>
                          </SelectContent>
                        </Select>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </div>

          <div className="flex justify-end space-x-4">
            <Button variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            {quotation.status !== "Enviada" && (
              <>
                <Button
                  onClick={handleSaveQuotation}
                  disabled={updateQuotationMutation.isPending}
                >
                  Salvar Cotação
                </Button>
                <Button
                  onClick={handleSendQuotation}
                  disabled={updateQuotationMutation.isPending}
                  className="bg-green-600 hover:bg-green-700"
                >
                  Enviar Cotação
                </Button>
              </>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
