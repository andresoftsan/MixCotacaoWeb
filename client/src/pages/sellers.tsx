import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
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
import { Plus, Edit, Trash2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Seller } from "@/lib/types";
import SellerFormModal from "@/components/seller-form-modal";

export default function SellersPage() {
  const [selectedSeller, setSelectedSeller] = useState<Seller | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const { toast } = useToast();

  const { data: sellers, isLoading } = useQuery<Seller[]>({
    queryKey: ["/api/sellers"],
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => apiRequest("DELETE", `/api/sellers/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/sellers"] });
      toast({
        title: "Vendedor removido",
        description: "Vendedor removido com sucesso.",
      });
    },
    onError: (error: any) => {
      toast({
        title: "Erro ao remover vendedor",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const handleNewSeller = () => {
    setSelectedSeller(null);
    setIsModalOpen(true);
  };

  const handleEditSeller = (seller: Seller) => {
    setSelectedSeller(seller);
    setIsModalOpen(true);
  };

  const handleDeleteSeller = (seller: Seller) => {
    if (seller.email === "administrador") {
      toast({
        title: "Ação não permitida",
        description: "Não é possível remover o usuário administrador.",
        variant: "destructive",
      });
      return;
    }

    if (confirm(`Tem certeza que deseja remover o vendedor ${seller.name}?`)) {
      deleteMutation.mutate(seller.id);
    }
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedSeller(null);
  };

  const getStatusBadge = (status: string) => {
    const baseClasses = "status-badge";
    return status === "Ativo" 
      ? `${baseClasses} status-ativo`
      : `${baseClasses} status-inativo`;
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
        <h1 className="text-2xl font-semibold text-gray-900">Gerenciar Vendedores</h1>
        <Button onClick={handleNewSeller}>
          <Plus className="mr-2 h-4 w-4" />
          Novo Vendedor
        </Button>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Nome</TableHead>
                  <TableHead>E-mail</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sellers?.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center py-8 text-gray-500">
                      Nenhum vendedor encontrado
                    </TableCell>
                  </TableRow>
                ) : (
                  sellers?.map((seller) => (
                    <TableRow key={seller.id}>
                      <TableCell className="font-medium">
                        {seller.name}
                      </TableCell>
                      <TableCell>{seller.email}</TableCell>
                      <TableCell>
                        <span className={getStatusBadge(seller.status)}>
                          {seller.status}
                        </span>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleEditSeller(seller)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          {seller.email !== "administrador" && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleDeleteSeller(seller)}
                              disabled={deleteMutation.isPending}
                            >
                              <Trash2 className="h-4 w-4 text-red-600" />
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

      {isModalOpen && (
        <SellerFormModal
          seller={selectedSeller}
          onClose={handleCloseModal}
        />
      )}
    </div>
  );
}
