import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Plus, Edit, Trash2, Search, X } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Seller } from "@/lib/types";
import SellerFormModal from "@/components/seller-form-modal";

export default function SellersPage() {
  const [selectedSeller, setSelectedSeller] = useState<Seller | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchEmail, setSearchEmail] = useState("");
  const [searchName, setSearchName] = useState("");
  const [searchResult, setSearchResult] = useState<Seller | Seller[] | null>(null);
  const [isSearching, setIsSearching] = useState(false);
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
    if (seller.email === "administrador@softsan.com.br") {
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

  const handleSearchByEmail = async () => {
    if (!searchEmail.trim()) {
      toast({
        title: "Erro",
        description: "Digite um e-mail para buscar.",
        variant: "destructive",
      });
      return;
    }

    setIsSearching(true);
    try {
      const response = await fetch(`/api/sellers?email=${encodeURIComponent(searchEmail.trim())}`);
      if (response.ok) {
        const seller = await response.json();
        setSearchResult(seller);
      } else if (response.status === 404) {
        setSearchResult(null);
        toast({
          title: "Vendedor não encontrado",
          description: "Nenhum vendedor encontrado com este e-mail.",
        });
      } else {
        throw new Error("Erro na busca");
      }
    } catch (error) {
      toast({
        title: "Erro",
        description: "Erro ao buscar vendedor por e-mail.",
        variant: "destructive",
      });
    } finally {
      setIsSearching(false);
    }
  };

  const handleSearchByName = async () => {
    if (!searchName.trim()) {
      toast({
        title: "Erro",
        description: "Digite um nome para buscar.",
        variant: "destructive",
      });
      return;
    }

    setIsSearching(true);
    try {
      const response = await fetch(`/api/sellers?name=${encodeURIComponent(searchName.trim())}`);
      if (response.ok) {
        const sellers = await response.json();
        setSearchResult(sellers);
      } else if (response.status === 404) {
        setSearchResult(null);
        toast({
          title: "Vendedores não encontrados",
          description: "Nenhum vendedor encontrado com este nome.",
        });
      } else {
        throw new Error("Erro na busca");
      }
    } catch (error) {
      toast({
        title: "Erro",
        description: "Erro ao buscar vendedores por nome.",
        variant: "destructive",
      });
    } finally {
      setIsSearching(false);
    }
  };

  const handleClearSearch = () => {
    setSearchEmail("");
    setSearchName("");
    setSearchResult(null);
  };

  const displayedSellers = searchResult 
    ? (Array.isArray(searchResult) ? searchResult : [searchResult])
    : sellers || [];

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

      {/* Search Section */}
      <Card>
        <CardContent className="p-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="search-email">Buscar por E-mail</Label>
              <div className="flex space-x-2">
                <Input
                  id="search-email"
                  type="email"
                  placeholder="Digite o e-mail..."
                  value={searchEmail}
                  onChange={(e) => setSearchEmail(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSearchByEmail()}
                />
                <Button 
                  onClick={handleSearchByEmail} 
                  disabled={isSearching}
                  size="sm"
                >
                  <Search className="h-4 w-4" />
                </Button>
              </div>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="search-name">Buscar por Nome</Label>
              <div className="flex space-x-2">
                <Input
                  id="search-name"
                  placeholder="Digite o nome..."
                  value={searchName}
                  onChange={(e) => setSearchName(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSearchByName()}
                />
                <Button 
                  onClick={handleSearchByName} 
                  disabled={isSearching}
                  size="sm"
                >
                  <Search className="h-4 w-4" />
                </Button>
              </div>
            </div>

            <div className="flex items-end">
              <Button 
                onClick={handleClearSearch} 
                variant="outline"
                disabled={!searchEmail && !searchName && !searchResult}
              >
                <X className="h-4 w-4 mr-2" />
                Limpar Busca
              </Button>
            </div>
          </div>
          
          {searchResult && (
            <div className="mt-4 p-3 bg-blue-50 rounded-md">
              <p className="text-sm text-blue-700">
                {Array.isArray(searchResult) 
                  ? `${searchResult.length} vendedor(es) encontrado(s)` 
                  : "1 vendedor encontrado"
                }
              </p>
            </div>
          )}
        </CardContent>
      </Card>

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
                  displayedSellers.map((seller) => (
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
                          {seller.email !== "administrador@softsan.com.br" && (
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
