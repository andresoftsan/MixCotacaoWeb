import { useState, useEffect } from "react";
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
import { ArrowLeft, Save } from "lucide-react";
import { Quotation, QuotationItem } from "@/lib/types";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function QuotationEditPage() {
  const [match, params] = useRoute("/cotacoes/editar/:id");
  const [, setLocation] = useLocation();
  const { toast } = useToast();
  const [items, setItems] = useState<QuotationItem[]>([]);

  const quotationId = params?.id ? parseInt(params.id) : null;

  console.log("Route match:", match, "Params:", params, "QuotationId:", quotationId);

  const { data: quotation, isLoading: quotationLoading, error: quotationError } = useQuery<Quotation>({
    queryKey: ["/api/quotations", quotationId],
    enabled: !!quotationId,
  });

  console.log("Quotation data:", quotation, "Loading:", quotationLoading, "Error:", quotationError);

  const { data: quotationItems, isLoading: itemsLoading } = useQuery<QuotationItem[]>({
    queryKey: ["/api/quotations", quotationId, "items"],
    enabled: !!quotationId,
  });

  useEffect(() => {
    if (quotationItems) {
      setItems(quotationItems);
    }
  }, [quotationItems]);

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
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/quotations", quotationId, "items"] });
      toast({
        title: "Sucesso",
        description: "Item atualizado com sucesso",
      });
    },
    onError: (error: any) => {
      toast({
        title: "Erro",
        description: error.message || "Erro ao atualizar item",
        variant: "destructive",
      });
    },
  });

  const handleItemChange = (itemId: number, field: string, value: string | number | undefined) => {
    setItems(prevItems =>
      prevItems.map(item =>
        item.id === itemId ? { ...item, [field]: value } : item
      )
    );
  };

  const handleSaveItem = (item: QuotationItem) => {
    const updateData = {
      availableQuantity: item.availableQuantity || undefined,
      unitPrice: item.unitPrice || undefined,
      validity: item.validity || undefined,
      situation: item.situation || undefined,
    };

    updateItemMutation.mutate({ itemId: item.id, data: updateData });
  };

  const handleSaveAll = () => {
    items.forEach(item => {
      handleSaveItem(item);
    });
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

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <Button variant="ghost" onClick={handleBack}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar
          </Button>
          <h1 className="text-2xl font-bold">Editar Cotação {quotation.number}</h1>
        </div>
        <Button onClick={handleSaveAll} disabled={updateItemMutation.isPending}>
          <Save className="h-4 w-4 mr-2" />
          Salvar Tudo
        </Button>
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
          <CardTitle>Itens da Cotação</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Código de Barras</TableHead>
                <TableHead>Produto</TableHead>
                <TableHead>Qtd. Solicitada</TableHead>
                <TableHead>Qtd. Disponível</TableHead>
                <TableHead>Preço Unitário</TableHead>
                <TableHead>Validade</TableHead>
                <TableHead>Situação</TableHead>
                <TableHead>Ações</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {items.map((item) => (
                <TableRow key={item.id}>
                  <TableCell className="font-mono text-sm">{item.barcode}</TableCell>
                  <TableCell className="max-w-[200px]">
                    <div className="truncate" title={item.productName}>
                      {item.productName}
                    </div>
                  </TableCell>
                  <TableCell>{item.quotedQuantity}</TableCell>
                  <TableCell>
                    <Input
                      type="number"
                      value={item.availableQuantity || ''}
                      onChange={(e) => handleItemChange(item.id, 'availableQuantity', e.target.value ? parseInt(e.target.value) : 0)}
                      placeholder="Quantidade"
                      className="w-24"
                    />
                  </TableCell>
                  <TableCell>
                    <Input
                      value={item.unitPrice || ''}
                      onChange={(e) => handleItemChange(item.id, 'unitPrice', e.target.value)}
                      placeholder="R$ 0,00"
                      className="w-24"
                    />
                  </TableCell>
                  <TableCell>
                    <Input
                      type="date"
                      value={item.validity ? item.validity.split('T')[0] : ''}
                      onChange={(e) => handleItemChange(item.id, 'validity', e.target.value)}
                      className="w-32"
                    />
                  </TableCell>
                  <TableCell>
                    <Select
                      value={item.situation || ''}
                      onValueChange={(value) => handleItemChange(item.id, 'situation', value)}
                    >
                      <SelectTrigger className="w-32">
                        <SelectValue placeholder="Situação" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Disponível">Disponível</SelectItem>
                        <SelectItem value="Parcial">Parcial</SelectItem>
                        <SelectItem value="Indisponível">Indisponível</SelectItem>
                      </SelectContent>
                    </Select>
                  </TableCell>
                  <TableCell>
                    <Button
                      size="sm"
                      onClick={() => handleSaveItem(item)}
                      disabled={updateItemMutation.isPending}
                    >
                      <Save className="h-3 w-3" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}