# API Token Configuration - Mix Cotação Web

## Overview
O sistema suporta autenticação por tokens API para integração com sistemas externos, além da autenticação por sessão para interface web.

## Configuração do Banco de Dados

### 1. Migração da Tabela API Keys
Execute no PostgreSQL:

```sql
-- Criar tabela de API keys se não existir
CREATE TABLE IF NOT EXISTS api_keys (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  key TEXT NOT NULL UNIQUE,
  seller_id INTEGER REFERENCES sellers(id) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  last_used_at TIMESTAMP
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_api_keys_key ON api_keys(key);
CREATE INDEX IF NOT EXISTS idx_api_keys_seller_id ON api_keys(seller_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON api_keys(is_active);
```

### 2. Verificar Estrutura
```sql
-- Verificar se tabela foi criada corretamente
\d api_keys

-- Verificar dados existentes
SELECT COUNT(*) FROM api_keys;
```

## Como Gerar Tokens API

### 1. Via Interface Web
1. Faça login no sistema
2. Acesse a seção "API Keys" (será adicionada ao menu)
3. Clique em "Criar Nova API Key"
4. Insira um nome descritivo
5. Copie o token gerado (só será exibido uma vez)

### 2. Via API (Programaticamente)
```http
POST /api/api-keys
Authorization: Bearer SEU_TOKEN_EXISTENTE
Content-Type: application/json

{
  "name": "Integração Sistema ERP"
}
```

**Resposta:**
```json
{
  "id": 1,
  "name": "Integração Sistema ERP",
  "key": "mxc_abcdef123456789012345678901234567890",
  "isActive": true,
  "createdAt": "2025-01-15T10:30:00.000Z",
  "message": "API key criada com sucesso. Guarde esta chave em local seguro, ela não será exibida novamente."
}
```

## Usando Tokens na API

### 1. Autenticação por Token
Inclua o token no header `Authorization`:

```http
GET /api/quotations
Authorization: Bearer mxc_abcdef123456789012345678901234567890
```

### 2. Exemplos Práticos

#### Listar Cotações
```bash
curl -H "Authorization: Bearer mxc_YOUR_TOKEN_HERE" \
     http://localhost:5000/api/quotations
```

#### Criar Nova Cotação
```bash
curl -X POST \
  -H "Authorization: Bearer mxc_YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "COT-2025-007",
    "deadline": "2025-01-30T23:59:59.000Z",
    "supplierCnpj": "12.345.678/0001-90",
    "supplierName": "Fornecedor API Ltda",
    "clientCnpj": "98.765.432/0001-10",
    "clientName": "Cliente API S/A",
    "sellerId": 1
  }' \
  http://localhost:5000/api/quotations
```

#### Buscar Estatísticas
```bash
curl -H "Authorization: Bearer mxc_YOUR_TOKEN_HERE" \
     http://localhost:5000/api/dashboard/stats
```

## Gerenciamento de Tokens

### 1. Listar Tokens do Usuário
```http
GET /api/api-keys
Authorization: Bearer mxc_YOUR_TOKEN_HERE
```

**Resposta:**
```json
[
  {
    "id": 1,
    "name": "Integração ERP",
    "isActive": true,
    "createdAt": "2025-01-15T10:30:00.000Z",
    "lastUsedAt": "2025-01-15T15:45:00.000Z",
    "keyPreview": "mxc_abcd...7890"
  }
]
```

### 2. Desativar Token
```http
PATCH /api/api-keys/1/toggle
Authorization: Bearer mxc_YOUR_TOKEN_HERE
Content-Type: application/json

{
  "isActive": false
}
```

### 3. Deletar Token
```http
DELETE /api/api-keys/1
Authorization: Bearer mxc_YOUR_TOKEN_HERE
```

## Segurança

### 1. Formato do Token
- Prefixo: `mxc_` (Mix Cotação)
- Comprimento: 36 caracteres totais
- Geração: nanoid(32) para alta entropia
- Exemplo: `mxc_V1StGXR8_Z5jdHi6B-myT1StGXR8_Z5j`

### 2. Boas Práticas
- **Guarde tokens em local seguro** (variáveis de ambiente)
- **Não exponha tokens em logs** ou código-fonte
- **Use HTTPS em produção** sempre
- **Revogue tokens não utilizados** regularmente
- **Monitore uso** através do campo `lastUsedAt`

### 3. Variáveis de Ambiente
```bash
# .env
MIX_COTACAO_API_TOKEN=mxc_abcdef123456789012345678901234567890
MIX_COTACAO_API_URL=https://mixcotacao.seudominio.com.br
```

## Exemplos de Integração

### 1. Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: process.env.MIX_COTACAO_API_URL,
  headers: {
    'Authorization': `Bearer ${process.env.MIX_COTACAO_API_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

// Listar cotações
async function getQuotations() {
  try {
    const response = await api.get('/api/quotations');
    return response.data;
  } catch (error) {
    console.error('Erro ao buscar cotações:', error.response?.data);
    throw error;
  }
}

// Criar cotação
async function createQuotation(quotationData) {
  try {
    const response = await api.post('/api/quotations', quotationData);
    return response.data;
  } catch (error) {
    console.error('Erro ao criar cotação:', error.response?.data);
    throw error;
  }
}
```

### 2. Python
```python
import requests
import os

class MixCotacaoAPI:
    def __init__(self):
        self.base_url = os.getenv('MIX_COTACAO_API_URL')
        self.token = os.getenv('MIX_COTACAO_API_TOKEN')
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
    
    def get_quotations(self):
        response = requests.get(f'{self.base_url}/api/quotations', headers=self.headers)
        response.raise_for_status()
        return response.json()
    
    def create_quotation(self, quotation_data):
        response = requests.post(
            f'{self.base_url}/api/quotations',
            json=quotation_data,
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()

# Uso
api = MixCotacaoAPI()
quotations = api.get_quotations()
print(f"Total de cotações: {len(quotations)}")
```

### 3. PHP
```php
<?php
class MixCotacaoAPI {
    private $baseUrl;
    private $token;
    
    public function __construct() {
        $this->baseUrl = $_ENV['MIX_COTACAO_API_URL'];
        $this->token = $_ENV['MIX_COTACAO_API_TOKEN'];
    }
    
    private function makeRequest($method, $endpoint, $data = null) {
        $curl = curl_init();
        
        curl_setopt_array($curl, [
            CURLOPT_URL => $this->baseUrl . $endpoint,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $this->token,
                'Content-Type: application/json'
            ],
        ]);
        
        if ($data) {
            curl_setopt($curl, CURLOPT_POSTFIELDS, json_encode($data));
        }
        
        $response = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);
        
        if ($httpCode >= 400) {
            throw new Exception("API Error: HTTP $httpCode");
        }
        
        return json_decode($response, true);
    }
    
    public function getQuotations() {
        return $this->makeRequest('GET', '/api/quotations');
    }
    
    public function createQuotation($quotationData) {
        return $this->makeRequest('POST', '/api/quotations', $quotationData);
    }
}

// Uso
$api = new MixCotacaoAPI();
$quotations = $api->getQuotations();
echo "Total de cotações: " . count($quotations);
?>
```

## Postman Collection com Token

### 1. Configurar Environment
```json
{
  "name": "Mix Cotacao API Token",
  "values": [
    {
      "key": "base_url",
      "value": "http://localhost:5000"
    },
    {
      "key": "api_token",
      "value": "mxc_SEU_TOKEN_AQUI"
    }
  ]
}
```

### 2. Configurar Authorization
No Postman:
1. Aba **Authorization**
2. Type: **Bearer Token**
3. Token: `{{api_token}}`

### 3. Exemplo de Request
```http
GET {{base_url}}/api/quotations
Authorization: Bearer {{api_token}}
```

## Monitoramento e Logs

### 1. Verificar Uso de Tokens
```sql
-- Tokens mais utilizados
SELECT 
  ak.name,
  ak.key,
  ak.last_used_at,
  s.name as seller_name
FROM api_keys ak
JOIN sellers s ON ak.seller_id = s.id
WHERE ak.is_active = true
ORDER BY ak.last_used_at DESC;

-- Tokens não utilizados há mais de 30 dias
SELECT 
  ak.name,
  ak.created_at,
  ak.last_used_at,
  s.name as seller_name
FROM api_keys ak
JOIN sellers s ON ak.seller_id = s.id
WHERE ak.last_used_at < NOW() - INTERVAL '30 days'
   OR ak.last_used_at IS NULL;
```

### 2. Logs de Aplicação
O sistema automaticamente registra:
- Uso de tokens (atualiza `last_used_at`)
- Tentativas de autenticação falhidas
- Criação e exclusão de tokens

## Solução de Problemas

### 1. Token Inválido (401)
```json
{
  "message": "Token inválido ou inativo"
}
```
**Solução:**
- Verificar se token está correto
- Verificar se token está ativo
- Gerar novo token se necessário

### 2. Token Expirado
O sistema não implementa expiração automática, mas você pode:
```sql
-- Desativar tokens antigos
UPDATE api_keys 
SET is_active = false 
WHERE last_used_at < NOW() - INTERVAL '90 days';
```

### 3. Permissões
Tokens herdam as permissões do vendedor associado:
- **Vendedores**: Acesso apenas aos próprios dados
- **Administrador**: Acesso total ao sistema

## Rate Limiting (Futuro)
Para implementar rate limiting:
- Adicionar campos na tabela `api_keys`
- Middleware para controlar requisições por minuto
- Headers de resposta com limites restantes

Esta documentação fornece todo o necessário para configurar e usar tokens API no sistema Mix Cotação Web de forma segura e eficiente.