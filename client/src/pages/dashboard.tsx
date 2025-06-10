import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Clock, CheckCircle, AlertTriangle } from "lucide-react";
import { DashboardStats, Quotation } from "@/lib/types";

export default function DashboardPage() {
  const { data: stats, isLoading: statsLoading } = useQuery<DashboardStats>({
    queryKey: ["/api/dashboard/stats"],
  });

  const { data: quotations, isLoading: quotationsLoading } = useQuery<Quotation[]>({
    queryKey: ["/api/quotations"],
  });

  const recentQuotations = quotations?.slice(0, 3) || [];

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

  if (statsLoading || quotationsLoading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => (
            <Card key={i} className="animate-pulse">
              <CardContent className="p-6">
                <div className="h-16 bg-gray-200 rounded"></div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-full bg-blue-100">
                <Clock className="text-primary text-xl" size={24} />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">
                  Aguardando Digitação
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats?.aguardandoDigitacao || 0}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-full bg-green-100">
                <CheckCircle className="text-green-600 text-xl" size={24} />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">
                  Cotações Enviadas
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats?.enviadas || 0}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="p-3 rounded-full bg-red-100">
                <AlertTriangle className="text-red-600 text-xl" size={24} />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">
                  Prazo Encerrado
                </p>
                <p className="text-2xl font-semibold text-gray-900">
                  {stats?.prazoEncerrado || 0}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">
            Cotações Recentes
          </h3>
        </div>
        <CardContent className="p-6">
          {recentQuotations.length === 0 ? (
            <p className="text-gray-500 text-center py-8">
              Nenhuma cotação encontrada
            </p>
          ) : (
            <div className="space-y-4">
              {recentQuotations.map((quotation) => (
                <div
                  key={quotation.id}
                  className="flex items-center justify-between p-4 border border-gray-200 rounded-lg"
                >
                  <div>
                    <p className="font-medium text-gray-900">
                      {quotation.number}
                    </p>
                    <p className="text-sm text-gray-600">
                      Cliente: {quotation.clientName}
                    </p>
                  </div>
                  <div className="text-right">
                    <span className={getStatusBadge(quotation.status)}>
                      {quotation.status}
                    </span>
                    <p className="text-sm text-gray-600 mt-1">
                      {quotation.status === "Enviada"
                        ? `Enviado: ${formatDate(quotation.date)}`
                        : `Prazo: ${formatDate(quotation.deadline)}`}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
