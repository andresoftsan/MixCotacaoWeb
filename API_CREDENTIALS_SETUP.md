# Mix Cotação Web - Configuração de Credenciais da API

## Configuração Atual

### Credenciais do Administrador
- **Email:** `administrador@softsan.com.br`
- **Senha:** `M1xgestao@2025`

### Configuração via Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto ou configure as seguintes variáveis:

```bash
# Segredo da sessão (recomendado alterar em produção)
SESSION_SECRET=mix-cotacao-secret-key-production

# URL do banco de dados
DATABASE_URL=postgresql://user:password@host:port/database

# Configurações opcionais
NODE_ENV=production
PORT=5000
```

## Autenticação para Integração com Terceiros

### Método 1: Autenticação por Sessão (Recomendado para aplicações web)

```javascript
// 1. Fazer login para obter sessão
const loginResponse = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'administrador@softsan.com.br',
    password: 'M1xgestao@2025'
  }),
  credentials: 'include' // Importante para manter cookies
});

// 2. Usar a sessão para outras requisições
const quotations = await fetch('/api/quotations', {
  credentials: 'include' // Mantém a sessão
});
```

### Método 2: Bearer Token (Para APIs de sistema)

Se precisar de autenticação via token, configure um header personalizado:

```javascript
// Usando token fixo (configure no seu sistema)
const API_TOKEN = 'your-secure-api-token-here';

const response = await fetch('/api/quotations', {
  headers: {
    'Authorization': `Bearer ${API_TOKEN}`,
    'Content-Type': 'application/json'
  }
});
```

## Configuração de Segurança

### Para Produção

1. **Altere as credenciais padrão:**
   - Acesse o sistema como administrador
   - Vá em Configurações → Vendedores
   - Edite o usuário administrador e altere a senha

2. **Configure variáveis de ambiente:**
   ```bash
   SESSION_SECRET=sua-chave-secreta-super-forte-aqui
   NODE_ENV=production
   ```

3. **Configure HTTPS:**
   - Em produção, certifique-se de usar HTTPS
   - Atualize a configuração de cookies para `secure: true`

### Permissões por Tipo de Usuário

**Administrador (`administrador@softsan.com.br`):**
- Acesso total a todas as APIs
- Gerenciamento de vendedores
- Visualização de todas as cotações
- Estatísticas globais

**Vendedores:**
- Acesso apenas às próprias cotações
- Criação e edição de cotações próprias
- Estatísticas pessoais

## Endpoints de Configuração

### Alterar Senha do Administrador
```http
PUT /api/sellers/2
Content-Type: application/json
Authorization: Session (login required)

{
  "password": "nova-senha-segura"
}
```

### Listar Usuários (Admin only)
```http
GET /api/sellers
Authorization: Session (admin required)
```

## Teste de Conectividade

### Verificar Status da API
```bash
curl -X GET http://your-domain.com/api/auth/me
# Retorna 401 se não autenticado, ou dados do usuário se autenticado
```

### Teste de Login
```bash
curl -X POST http://your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"administrador@softsan.com.br","password":"M1xgestao@2025"}' \
  -c cookies.txt

# Usar a sessão salva
curl -X GET http://your-domain.com/api/quotations \
  -b cookies.txt
```

## Integração com Sistemas Terceiros

### Exemplo: Sistema ERP
```python
import requests
from datetime import datetime, timedelta

class MixCotacaoAPI:
    def __init__(self, base_url, email, password):
        self.base_url = base_url
        self.session = requests.Session()
        self.login(email, password)
    
    def login(self, email, password):
        response = self.session.post(f'{self.base_url}/api/auth/login', json={
            'email': email,
            'password': password
        })
        if response.status_code != 200:
            raise Exception(f"Login failed: {response.text}")
        return response.json()
    
    def create_quotation(self, supplier_data, client_data, items):
        # Criar cotação
        quotation_data = {
            'date': datetime.now().isoformat()[:10],
            'deadline': (datetime.now() + timedelta(days=5)).isoformat()[:10],
            'supplierCnpj': supplier_data['cnpj'],
            'supplierName': supplier_data['name'],
            'clientCnpj': client_data['cnpj'],
            'clientName': client_data['name'],
            'sellerId': 2  # ID do administrador
        }
        
        response = self.session.post(f'{self.base_url}/api/quotations', json=quotation_data)
        quotation = response.json()
        
        # Adicionar itens
        for item in items:
            item_data = {
                'quotationId': quotation['id'],
                'barcode': item['barcode'],
                'productName': item['name'],
                'quotedQuantity': item['quantity']
            }
            self.session.post(f'{self.base_url}/api/quotation-items', json=item_data)
        
        return quotation

# Uso
api = MixCotacaoAPI('http://your-domain.com', 'administrador@softsan.com.br', 'M1xgestao@2025')

quotation = api.create_quotation(
    supplier_data={'cnpj': '12.345.678/0001-90', 'name': 'Fornecedor ABC'},
    client_data={'cnpj': '98.765.432/0001-10', 'name': 'Cliente XYZ'},
    items=[
        {'barcode': '1234567890123', 'name': 'Produto A', 'quantity': 10},
        {'barcode': '1234567890124', 'name': 'Produto B', 'quantity': 5}
    ]
)
```

## Monitoramento

### Logs de Acesso
O sistema registra automaticamente:
- Tentativas de login
- Acessos às APIs
- Operações de CRUD
- Erros de autenticação

### Verificação de Saúde
```bash
# Status geral do sistema
curl http://your-domain.com/api/dashboard/stats

# Verificar conectividade do banco
curl http://your-domain.com/api/sellers
```

## Solução de Problemas

**Erro 401 - Não autorizado:**
- Verificar se o login foi realizado corretamente
- Confirmar que os cookies estão sendo enviados
- Validar credenciais

**Erro 403 - Acesso negado:**
- Usuário não tem permissão para a operação
- Vendedores só acessam próprios dados

**Erro 500 - Erro interno:**
- Verificar logs do servidor
- Confirmar conexão com banco de dados
- Validar formato dos dados enviados

## Contato

Para suporte na configuração da API, consulte os logs do sistema ou entre em contato com o administrador técnico.