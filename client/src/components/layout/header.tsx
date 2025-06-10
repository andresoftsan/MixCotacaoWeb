import { User } from "@/lib/auth";

interface HeaderProps {
  user: User;
}

export default function Header({ user }: HeaderProps) {
  const formatDateTime = () => {
    return new Date().toLocaleString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((word) => word[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <header className="bg-white shadow-sm border-b border-gray-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">
          Sistema de Cotações
        </h1>
        <div className="flex items-center space-x-4">
          <span className="text-sm text-gray-600">
            Última atualização: {formatDateTime()}
          </span>
          <div className="h-8 w-8 bg-primary rounded-full flex items-center justify-center">
            <span className="text-white text-sm font-medium">
              {getInitials(user.name)}
            </span>
          </div>
        </div>
      </div>
    </header>
  );
}
