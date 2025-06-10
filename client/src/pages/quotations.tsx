import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Plus, Edit, Eye } from "lucide-react";
import { Quotation } from "@/lib/types";
import QuotationDetailModal from "@/components/quotation-detail-modal";

export default function QuotationsPage() {
  const [selectedQuotationId, setSelectedQuotationId] = useState<number | null>(null);
  const [, setLocation] = useLocation();

  const { data: quotations, isLoading } = useQuery<Quotation[]>({
    queryKey: ["/api/quotations"],
  });

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("pt-BR");
  };

  const getStatusBadge = (status: string) => {
    const baseClasses = "status-badge";
    switch (status) {
      case "Aguardando digitação":
        return `${baseClasses} status-aguardando`;
      case "Enviada":
        return `${baseClasses} status-enviada`;
      case "Prazo Encerrado":
        return `${baseClasses} status-encerrada`;
      default:
        return baseClasses;
    }
  };

  const handleEditQuotation = (quotationId: number) => {
    setLocation(`/cotacoes/editar/${quotationId}`);
  };

  const handleViewQuotation = (quotationId: number) => {
    setSelectedQuotationId(quotationId);
  };

  const handleCloseModal = () => {
    setSelectedQuotationId(null);
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div className="h-8 w-48 bg-gray-200 rounded animate-pulse"></div>
          <div className="h-10 w-32 bg-gray-200 rounded animate-pulse"></div>
        </div>
        <Card>
          <CardContent className="p-6">
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-16 bg-gray-200 rounded animate-pulse"></div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-semibold text-gray-900">Minhas Cotações</h1>
        <Button>
          <Plus className="mr-2 h-4 w-4" />
          Nova Cotação
        </Button>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Número</TableHead>
                  <TableHead>Data</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Prazo</TableHead>
                  <TableHead>Fornecedor</TableHead>
                  <TableHead>Cliente</TableHead>
                  <TableHead>Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {quotations?.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-8 text-gray-500">
                      Nenhuma cotação encontrada
                    </TableCell>
                  </TableRow>
                ) : (
                  quotations?.map((quotation) => (
                    <TableRow key={quotation.id}>
                      <TableCell className="font-medium">
                        {quotation.number}
                      </TableCell>
                      <TableCell>{formatDate(quotation.date)}</TableCell>
                      <TableCell>
                        <span className={getStatusBadge(quotation.status)}>
                          {quotation.status}
                        </span>
                      </TableCell>
                      <TableCell>{formatDate(quotation.deadline)}</TableCell>
                      <TableCell>
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {quotation.supplierName}
                          </div>
                          <div className="text-sm text-gray-500">
                            {quotation.supplierCnpj}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {quotation.clientName}
                          </div>
                          <div className="text-sm text-gray-500">
                            {quotation.clientCnpj}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          {quotation.status === "Aguardando digitação" && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleEditQuotation(quotation.id)}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                          )}
                          {quotation.status !== "Aguardando digitação" && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleViewQuotation(quotation.id)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {selectedQuotationId && (
        <QuotationDetailModal
          quotationId={selectedQuotationId}
          onClose={handleCloseModal}
        />
      )}
    </div>
  );
}
