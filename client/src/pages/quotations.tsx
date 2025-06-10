import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination";
import { Plus, Edit, Eye, Search } from "lucide-react";
import { Quotation } from "@/lib/types";
import QuotationDetailModal from "@/components/quotation-detail-modal";

export default function QuotationsPage() {
  const [selectedQuotationId, setSelectedQuotationId] = useState<number | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [, setLocation] = useLocation();
  const itemsPerPage = 20;

  const { data: quotations, isLoading } = useQuery<Quotation[]>({
    queryKey: ["/api/quotations"],
  });

  // Filter quotations based on search term
  const filteredQuotations = useMemo(() => {
    if (!quotations) return [];
    if (!searchTerm.trim()) return quotations;

    return quotations.filter((quotation) =>
      quotation.number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      quotation.supplierName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      quotation.clientName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      quotation.supplierCnpj.includes(searchTerm) ||
      quotation.clientCnpj.includes(searchTerm)
    );
  }, [quotations, searchTerm]);

  // Pagination calculations
  const totalPages = Math.ceil(filteredQuotations.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentQuotations = filteredQuotations.slice(startIndex, endIndex);

  // Reset to page 1 when search changes
  const handleSearchChange = (value: string) => {
    setSearchTerm(value);
    setCurrentPage(1);
  };

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

      {/* Search Filter */}
      <div className="flex items-center space-x-2">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-gray-400" />
          <Input
            placeholder="Buscar por número, fornecedor, cliente ou CNPJ..."
            value={searchTerm}
            onChange={(e) => handleSearchChange(e.target.value)}
            className="pl-8"
          />
        </div>
        {searchTerm && (
          <Button
            variant="outline"
            onClick={() => handleSearchChange("")}
            size="sm"
          >
            Limpar
          </Button>
        )}
      </div>

      {/* Results summary */}
      {searchTerm && (
        <div className="text-sm text-gray-600">
          Mostrando {filteredQuotations.length} resultado(s) para "{searchTerm}"
        </div>
      )}

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
                {currentQuotations?.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-8 text-gray-500">
                      {searchTerm ? "Nenhuma cotação encontrada para a busca" : "Nenhuma cotação encontrada"}
                    </TableCell>
                  </TableRow>
                ) : (
                  currentQuotations?.map((quotation) => (
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

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-700">
            Mostrando {startIndex + 1} a {Math.min(endIndex, filteredQuotations.length)} de {filteredQuotations.length} cotações
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

      {selectedQuotationId && (
        <QuotationDetailModal
          quotationId={selectedQuotationId}
          onClose={handleCloseModal}
        />
      )}
    </div>
  );
}
