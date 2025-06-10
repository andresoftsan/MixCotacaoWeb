import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { useState, useEffect } from "react";
import { User, authService } from "./lib/auth";
import LoginPage from "@/pages/login";
import DashboardPage from "@/pages/dashboard";
import QuotationsPage from "@/pages/quotations";
import QuotationEditPage from "@/pages/quotation-edit";
import SellersPage from "@/pages/sellers";
import SettingsPage from "@/pages/settings";
import Sidebar from "@/components/layout/sidebar";
import Header from "@/components/layout/header";

function AuthenticatedApp({ user, onLogout }: { user: User; onLogout: () => void }) {
  return (
    <div className="min-h-screen flex bg-gray-50">
      <Sidebar user={user} onLogout={onLogout} />
      <div className="flex-1 flex flex-col">
        <Header user={user} />
        <main className="flex-1 p-6">
          <Switch>
            <Route path="/" component={DashboardPage} />
            <Route path="/cotacoes" component={QuotationsPage} />
            <Route path="/cotacoes/editar/:id" component={QuotationEditPage} />
            <Route path="/vendedores" component={SellersPage} />
            <Route path="/configuracoes" component={SettingsPage} />
          </Switch>
        </main>
      </div>
    </div>
  );
}

function App() {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const currentUser = await authService.getCurrentUser();
        setUser(currentUser);
      } catch (error) {
        console.error("Auth check failed:", error);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  const handleLogin = (user: User) => {
    setUser(user);
  };

  const handleLogout = async () => {
    try {
      await authService.logout();
      setUser(null);
      queryClient.clear();
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        {user ? (
          <AuthenticatedApp user={user} onLogout={handleLogout} />
        ) : (
          <LoginPage onLogin={handleLogin} />
        )}
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
