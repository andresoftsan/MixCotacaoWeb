# Exemplos Práticos - Tokens API Mix Cotação Web

## Token Fixo Configurado

**Token de Teste Ativo:**
```
mxc_test123456789012345678901234567890
```

**Usuário Associado:** Administrador (acesso total)

## Exemplos de Uso

### 1. Listar Vendedores
```bash
curl -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
     http://localhost:5000/api/sellers
```

**Resposta:**
```json
[
  {
    "id": 1,
    "email": "administrador",
    "name": "Administrador",
    "status": "Ativo",
    "createdAt": "2025-06-10T14:46:13.949Z"
  },
  {
    "id": 2,
    "email": "administrador@softsan.com.br",
    "name": "Administrador",
    "status": "Ativo",
    "createdAt": "2025-06-10T14:52:58.120Z"
  }
]
```

### 1.1. Buscar Vendedor por E-mail
```bash
curl -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
     "http://localhost:5000/api/sellers?email=administrador%40softsan.com.br"
```

**Resposta:**
```json
{
  "id": 2,
  "email": "administrador@softsan.com.br",
  "name": "Administrador",
  "status": "Ativo",
  "createdAt": "2025-06-10T14:52:58.120Z"
}
```

**Nota:** O caractere `@` deve ser codificado como `%40` na URL.

### 2. Verificar Usuário Logado
```bash
curl -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
     http://localhost:5000/api/auth/me
```

**Resposta:**
```json
{
  "id": 2,
  "name": "Administrador",
  "email": "administrador@softsan.com.br",
  "isAdmin": true
}
```

### 3. Listar Cotações
```bash
curl -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
     http://localhost:5000/api/quotations
```

### 4. Criar Nova Cotação
```bash
curl -X POST \
  -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "COT-2025-API-001",
    "deadline": "2025-01-30T23:59:59.000Z",
    "supplierCnpj": "12.345.678/0001-90",
    "supplierName": "API Fornecedor Ltda",
    "clientCnpj": "98.765.432/0001-10",
    "clientName": "API Cliente S/A",
    "sellerId": 2
  }' \
  http://localhost:5000/api/quotations
```

## Como Criar Seu Próprio Token

### Opção 1: Via Banco de Dados (Direto)
```sql
INSERT INTO api_keys (name, key, seller_id, is_active) 
VALUES ('Meu Token Personalizado', 'mxc_SEU_TOKEN_PERSONALIZADO_AQUI', 2, true);
```

### Opção 2: Via API (Programático)
```bash
# Primeiro faça login via sessão web, depois:
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name": "Token Integração ERP"}' \
  http://localhost:5000/api/api-keys
```

### Opção 3: Gerar Token Seguro
```bash
# Gerar token aleatório
TOKEN="mxc_$(openssl rand -hex 32)"
echo "Novo token: $TOKEN"

# Inserir no banco
psql -d mixcotacao -c "INSERT INTO api_keys (name, key, seller_id) VALUES ('Token Produção', '$TOKEN', 2);"
```

## Integração com Sistemas Externos

### Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'http://localhost:5000',
  headers: {
    'Authorization': 'Bearer mxc_test123456789012345678901234567890',
    'Content-Type': 'application/json'
  }
});

// Buscar cotações
async function getCotacoes() {
  const response = await api.get('/api/quotations');
  return response.data;
}

// Criar cotação
async function criarCotacao(dados) {
  const response = await api.post('/api/quotations', dados);
  return response.data;
}
```

### Python
```python
import requests

headers = {
    'Authorization': 'Bearer mxc_test123456789012345678901234567890',
    'Content-Type': 'application/json'
}

# Buscar vendedores
response = requests.get('http://localhost:5000/api/sellers', headers=headers)
vendedores = response.json()

# Criar cotação
cotacao_data = {
    "number": "COT-2025-PYTHON-001",
    "deadline": "2025-01-30T23:59:59.000Z",
    "supplierCnpj": "11.222.333/0001-44",
    "supplierName": "Python Fornecedor",
    "clientCnpj": "55.666.777/0001-88",
    "clientName": "Python Cliente",
    "sellerId": 2
}

response = requests.post('http://localhost:5000/api/quotations', 
                        json=cotacao_data, 
                        headers=headers)
nova_cotacao = response.json()
```

### PHP
```php
<?php
$token = 'mxc_test123456789012345678901234567890';
$headers = [
    'Authorization: Bearer ' . $token,
    'Content-Type: application/json'
];

// Buscar cotações
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:5000/api/quotations');
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$cotacoes = json_decode(curl_exec($ch), true);
curl_close($ch);

echo "Total de cotações: " . count($cotacoes);
?>
```

## Segurança e Boas Práticas

### Configuração de Ambiente
```bash
# .env
MIX_COTACAO_TOKEN=mxc_test123456789012345678901234567890
MIX_COTACAO_URL=http://localhost:5000
```

### Verificação de Token
```bash
# Testar se token está funcionando
curl -f -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
     http://localhost:5000/api/auth/me && echo "Token OK" || echo "Token inválido"
```

### Monitoramento
```sql
-- Verificar uso do token
SELECT 
  ak.name,
  ak.last_used_at,
  s.name as seller_name
FROM api_keys ak
JOIN sellers s ON ak.seller_id = s.id
WHERE ak.key = 'mxc_test123456789012345678901234567890';
```

## Troubleshooting

### Token não funciona (401)
- Verificar se token está ativo no banco
- Confirmar formato correto: "Bearer mxc_..."
- Validar se vendedor associado está ativo

### Acesso negado (403)
- Verificar se vendedor tem permissões necessárias
- Para `/api/sellers` precisa ser administrador
- Vendedores comuns só acessam próprios dados

### Endpoint não encontrado (404)
- Confirmar URL está correta
- Verificar se servidor está rodando na porta 5000
- Validar sintaxe da requisição

## Resumo do Sistema

**✅ Funcionando:**
- Autenticação por token API
- Autenticação por sessão web
- Middleware flexível (aceita ambos)
- Controle de permissões por usuário
- Logs de uso automáticos

**🔑 Token Ativo:** `mxc_test123456789012345678901234567890`
**👤 Usuário:** Administrador (acesso total)
**🌐 Base URL:** `http://localhost:5000`

## Endpoints Corrigidos e Testados

✅ **Vendedores (Admin):**
- GET /api/sellers
- POST /api/sellers
- PUT /api/sellers/:id
- DELETE /api/sellers/:id

✅ **Cotações:**
- GET /api/quotations
- GET /api/quotations/:id
- POST /api/quotations
- PUT /api/quotations/:id

✅ **Itens de Cotação:**
- GET /api/quotations/:id/items
- POST /api/quotations/:id/items
- PATCH /api/quotation-items/:id

✅ **Dashboard e Sistema:**
- GET /api/dashboard/stats
- GET /api/api-keys
- GET /api/auth/me

O sistema está pronto para integração com qualquer aplicação externa usando tokens API seguros.