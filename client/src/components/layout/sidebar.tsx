import { Link, useLocation } from "wouter";
import { BarChart3, FileText, Users, Settings, LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { User } from "@/lib/auth";

interface SidebarProps {
  user: User;
}

const menuItems = [
  {
    icon: BarChart3,
    label: "Dashboard",
    path: "/",
  },
  {
    icon: FileText,
    label: "Cotações",
    path: "/cotacoes",
  },
  {
    icon: Users,
    label: "Vendedores",
    path: "/vendedores",
    adminOnly: true,
  },
  {
    icon: Settings,
    label: "Configurações",
    path: "/configuracoes",
  },
];

export default function Sidebar({ user }: SidebarProps) {
  const [location] = useLocation();

  const filteredMenuItems = menuItems.filter(
    (item) => !item.adminOnly || user.isAdmin
  );

  const handleLogout = () => {
    window.location.reload();
  };

  return (
    <div className="w-64 bg-white shadow-lg flex flex-col">
      <div className="p-6 border-b border-gray-200">
        <h2 className="text-xl font-bold text-gray-900">Mix Cotação</h2>
        <p className="text-sm text-gray-600">
          {user.isAdmin ? "Administrador" : `Vendedor: ${user.name}`}
        </p>
      </div>

      <nav className="mt-6 flex-1">
        {filteredMenuItems.map((item) => {
          const Icon = item.icon;
          const isActive = location === item.path;

          return (
            <Link key={item.path} href={item.path}>
              <a
                className={`flex items-center px-6 py-3 text-gray-700 hover:bg-gray-50 ${
                  isActive
                    ? "bg-blue-50 border-r-2 border-primary text-primary"
                    : ""
                }`}
              >
                <Icon className="mr-3 h-5 w-5" />
                {item.label}
              </a>
            </Link>
          );
        })}
      </nav>

      <div className="p-6 border-t border-gray-200">
        <Button
          variant="ghost"
          onClick={handleLogout}
          className="flex items-center text-gray-600 hover:text-gray-900 w-full justify-start"
        >
          <LogOut className="mr-2 h-4 w-4" />
          Sair
        </Button>
      </div>
    </div>
  );
}
