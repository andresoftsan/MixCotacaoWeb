import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Card, CardContent } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { authService, type User } from "@/lib/auth";

interface LoginPageProps {
  onLogin: (user: User) => void;
}

export default function LoginPage({ onLogin }: LoginPageProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();

  // Load saved credentials if available
  useState(() => {
    const savedEmail = localStorage.getItem("mixCotacao_email");
    const savedPassword = localStorage.getItem("mixCotacao_password");
    const shouldRemember = localStorage.getItem("mixCotacao_remember") === "true";
    
    if (shouldRemember && savedEmail && savedPassword) {
      setEmail(savedEmail);
      setPassword(savedPassword);
      setRememberMe(true);
    }
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const user = await authService.login({ email, password });
      
      // Save credentials if remember me is checked
      if (rememberMe) {
        localStorage.setItem("mixCotacao_email", email);
        localStorage.setItem("mixCotacao_password", password);
        localStorage.setItem("mixCotacao_remember", "true");
      } else {
        localStorage.removeItem("mixCotacao_email");
        localStorage.removeItem("mixCotacao_password");
        localStorage.removeItem("mixCotacao_remember");
      }

      onLogin(user);
      
      toast({
        title: "Login realizado com sucesso",
        description: `Bem-vindo, ${user.name}!`,
      });
    } catch (error: any) {
      toast({
        title: "Erro no login",
        description: error.message || "Credenciais inválidas",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleForgotPassword = () => {
    toast({
      title: "Recuperação de senha",
      description: "Entre em contato com o administrador do sistema para recuperar sua senha.",
    });
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-gray-50">
      <div className="max-w-md w-full">
        <Card className="shadow-lg">
          <CardContent className="p-8">
            <div className="text-center mb-8">
              <h1 className="text-3xl font-bold text-gray-900 mb-2">
                Mix Cotação Web
              </h1>
              <p className="text-gray-600">Sistema de Gestão de Cotações</p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="email">E-mail</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="seu@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  disabled={isLoading}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">Senha</Label>
                <Input
                  id="password"
                  type="password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  disabled={isLoading}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="remember"
                    checked={rememberMe}
                    onCheckedChange={(checked) => setRememberMe(checked as boolean)}
                    disabled={isLoading}
                  />
                  <Label 
                    htmlFor="remember" 
                    className="text-sm text-gray-600 cursor-pointer"
                  >
                    Lembrar credenciais
                  </Label>
                </div>
                <button
                  type="button"
                  onClick={handleForgotPassword}
                  className="text-sm text-primary hover:underline"
                  disabled={isLoading}
                >
                  Esqueci a senha
                </button>
              </div>

              <Button
                type="submit"
                className="w-full"
                disabled={isLoading}
              >
                {isLoading ? "Entrando..." : "Entrar"}
              </Button>
            </form>

            <div className="mt-6 pt-6 border-t border-gray-200">
              <p className="text-xs text-gray-500 text-center">
                Acesso Administrador: administrador / M1xgestao@2025
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
