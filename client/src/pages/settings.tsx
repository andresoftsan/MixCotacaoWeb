import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/hooks/use-toast";

export default function SettingsPage() {
  const { toast } = useToast();

  const handleSaveEmailSettings = () => {
    toast({
      title: "Configurações salvas",
      description: "Configurações de e-mail salvas com sucesso.",
    });
  };

  const handleSaveGeneralSettings = () => {
    toast({
      title: "Configurações salvas",
      description: "Configurações gerais salvas com sucesso.",
    });
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-gray-900">
        Configurações do Sistema
      </h1>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">
              Configurações de E-mail
            </h3>
          </div>
          <CardContent className="p-6">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="smtp-server">Servidor SMTP</Label>
                <Input
                  id="smtp-server"
                  placeholder="smtp.servidor.com"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="smtp-port">Porta</Label>
                <Input
                  id="smtp-port"
                  type="number"
                  placeholder="587"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="smtp-user">Usuário</Label>
                <Input
                  id="smtp-user"
                  placeholder="usuario@servidor.com"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="smtp-password">Senha</Label>
                <Input
                  id="smtp-password"
                  type="password"
                  placeholder="••••••••"
                />
              </div>
              <Button onClick={handleSaveEmailSettings}>
                Salvar Configurações
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">
              Configurações Gerais
            </h3>
          </div>
          <CardContent className="p-6">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="default-deadline">Prazo padrão (dias)</Label>
                <Input
                  id="default-deadline"
                  type="number"
                  placeholder="7"
                  defaultValue="7"
                />
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="email-notifications"
                  defaultChecked
                />
                <Label htmlFor="email-notifications" className="cursor-pointer">
                  Notificar por e-mail sobre prazos
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="auto-deadline"
                />
                <Label htmlFor="auto-deadline" className="cursor-pointer">
                  Encerrar cotações automaticamente após o prazo
                </Label>
              </div>
              <Button onClick={handleSaveGeneralSettings}>
                Salvar Configurações
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
