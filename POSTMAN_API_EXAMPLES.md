# Mix Cotação Web - Exemplos API Postman

## Configuração Inicial

### 1. Criar Environment no Postman
```json
{
  "name": "Mix Cotacao Dev",
  "values": [
    {
      "key": "base_url",
      "value": "http://localhost:5000",
      "enabled": true
    },
    {
      "key": "auth_token",
      "value": "",
      "enabled": true
    }
  ]
}
```

### 2. Configuração de Cookies
O sistema usa sessões baseadas em cookies. Configure o Postman para:
- **Settings → General → Cookie and certificate management**
- Habilitar "Automatically follow redirects"
- Habilitar "Send cookies"

## Autenticação

### 1. Login (POST)
```http
POST {{base_url}}/api/auth/login
Content-Type: application/json

{
  "email": "administrador@softsan.com.br",
  "password": "M1xgestao@2025"
}
```

**Resposta de Sucesso (200):**
```json
{
  "id": 2,
  "name": "Administrador",
  "email": "administrador@softsan.com.br",
  "isAdmin": true
}
```

**Resposta de Erro (401):**
```json
{
  "message": "Credenciais inválidas"
}
```

### 2. Verificar Usuário Logado (GET)
```http
GET {{base_url}}/api/auth/me
```

**Resposta (200):**
```json
{
  "id": 2,
  "name": "Administrador",
  "email": "administrador@softsan.com.br",
  "isAdmin": true
}
```

### 3. Logout (POST)
```http
POST {{base_url}}/api/auth/logout
```

**Resposta (200):**
```json
{
  "message": "Logout realizado com sucesso"
}
```

## Vendedores (Sellers)

### 1. Listar Vendedores (GET)
```http
GET {{base_url}}/api/sellers
```

**Resposta (200):**
```json
[
  {
    "id": 1,
    "email": "vendedor1@empresa.com",
    "name": "João Silva",
    "status": "Ativo",
    "createdAt": "2025-01-15T10:30:00.000Z"
  },
  {
    "id": 2,
    "email": "vendedor2@empresa.com",
    "name": "Maria Santos",
    "status": "Ativo",
    "createdAt": "2025-01-15T11:00:00.000Z"
  }
]
```

### 2. Criar Vendedor (POST)
```http
POST {{base_url}}/api/sellers
Content-Type: application/json

{
  "email": "novo@vendedor.com",
  "name": "Carlos Oliveira",
  "password": "senha123",
  "status": "Ativo"
}
```

**Resposta (201):**
```json
{
  "id": 3,
  "email": "novo@vendedor.com",
  "name": "Carlos Oliveira",
  "status": "Ativo",
  "createdAt": "2025-01-15T15:30:00.000Z"
}
```

### 3. Atualizar Vendedor (PUT)
```http
PUT {{base_url}}/api/sellers/3
Content-Type: application/json

{
  "name": "Carlos Oliveira Santos",
  "status": "Inativo"
}
```

### 4. Deletar Vendedor (DELETE)
```http
DELETE {{base_url}}/api/sellers/3
```

**Resposta (200):**
```json
{
  "message": "Vendedor deletado com sucesso"
}
```

## Cotações (Quotations)

### 1. Listar Cotações (GET)
```http
GET {{base_url}}/api/quotations
```

**Resposta (200):**
```json
[
  {
    "id": 1,
    "number": "COT-2025-001",
    "date": "2025-01-15T00:00:00.000Z",
    "status": "Aguardando digitação",
    "deadline": "2025-01-20T23:59:59.000Z",
    "supplierCnpj": "12.345.678/0001-90",
    "supplierName": "Fornecedor ABC Ltda",
    "clientCnpj": "98.765.432/0001-10",
    "clientName": "Cliente XYZ S/A",
    "internalObservation": "Cotação urgente",
    "sellerId": 1,
    "createdAt": "2025-01-15T10:00:00.000Z"
  }
]
```

### 2. Buscar Cotação por ID (GET)
```http
GET {{base_url}}/api/quotations/1
```

### 3. Criar Cotação (POST)
```http
POST {{base_url}}/api/quotations
Content-Type: application/json

{
  "number": "COT-2025-006",
  "deadline": "2025-01-25T23:59:59.000Z",
  "supplierCnpj": "11.222.333/0001-44",
  "supplierName": "Novo Fornecedor Ltda",
  "clientCnpj": "55.666.777/0001-88",
  "clientName": "Novo Cliente S/A",
  "internalObservation": "Primeira cotação deste cliente",
  "sellerId": 1
}
```

**Resposta (201):**
```json
{
  "id": 12,
  "number": "COT-2025-006",
  "date": "2025-01-15T18:30:00.000Z",
  "status": "Aguardando digitação",
  "deadline": "2025-01-25T23:59:59.000Z",
  "supplierCnpj": "11.222.333/0001-44",
  "supplierName": "Novo Fornecedor Ltda",
  "clientCnpj": "55.666.777/0001-88",
  "clientName": "Novo Cliente S/A",
  "internalObservation": "Primeira cotação deste cliente",
  "sellerId": 1,
  "createdAt": "2025-01-15T18:30:00.000Z"
}
```

### 4. Atualizar Cotação (PUT)
```http
PUT {{base_url}}/api/quotations/12
Content-Type: application/json

{
  "status": "Enviada",
  "internalObservation": "Cotação enviada para o cliente"
}
```

### 5. Deletar Cotação (DELETE)
```http
DELETE {{base_url}}/api/quotations/12
```

## Itens de Cotação (Quotation Items)

### 1. Listar Itens de uma Cotação (GET)
```http
GET {{base_url}}/api/quotations/1/items
```

**Resposta (200):**
```json
[
  {
    "id": 1,
    "quotationId": 1,
    "barcode": "7891234567890",
    "productName": "Produto A - Modelo 123",
    "quotedQuantity": 100,
    "availableQuantity": 80,
    "unitPrice": "15.50",
    "validity": "2025-02-15T00:00:00.000Z",
    "situation": "Parcial"
  },
  {
    "id": 2,
    "quotationId": 1,
    "barcode": "7891234567891",
    "productName": "Produto B - Modelo 456",
    "quotedQuantity": 50,
    "availableQuantity": 50,
    "unitPrice": "25.00",
    "validity": "2025-02-15T00:00:00.000Z",
    "situation": "Disponível"
  }
]
```

### 2. Criar Item de Cotação (POST)
```http
POST {{base_url}}/api/quotations/1/items
Content-Type: application/json

{
  "barcode": "7891234567892",
  "productName": "Produto C - Modelo 789",
  "quotedQuantity": 75,
  "availableQuantity": 60,
  "unitPrice": "12.75",
  "validity": "2025-02-20T00:00:00.000Z",
  "situation": "Parcial"
}
```

**Resposta (201):**
```json
{
  "id": 25,
  "quotationId": 1,
  "barcode": "7891234567892",
  "productName": "Produto C - Modelo 789",
  "quotedQuantity": 75,
  "availableQuantity": 60,
  "unitPrice": "12.75",
  "validity": "2025-02-20T00:00:00.000Z",
  "situation": "Parcial"
}
```

### 3. Atualizar Item de Cotação (PUT)
```http
PUT {{base_url}}/api/quotation-items/25
Content-Type: application/json

{
  "availableQuantity": 75,
  "unitPrice": "12.00",
  "situation": "Disponível"
}
```

### 4. Deletar Item de Cotação (DELETE)
```http
DELETE {{base_url}}/api/quotation-items/25
```

## Dashboard

### 1. Estatísticas do Dashboard (GET)
```http
GET {{base_url}}/api/dashboard/stats
```

**Resposta (200):**
```json
{
  "total": 11,
  "aguardandoDigitacao": 2,
  "enviadas": 6,
  "prazoEncerrado": 3
}
```

### 2. Estatísticas por Vendedor (GET)
```http
GET {{base_url}}/api/dashboard/stats?sellerId=1
```

**Resposta (200):**
```json
{
  "total": 5,
  "aguardandoDigitacao": 1,
  "enviadas": 3,
  "prazoEncerrado": 1
}
```

## Health Check

### 1. Verificar Saúde do Sistema (GET)
```http
GET {{base_url}}/api/health
```

**Resposta (200):**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T18:45:30.000Z",
  "database": "connected",
  "uptime": 3600,
  "version": "1.0.0"
}
```

## Exemplos de Filtros e Paginação

### 1. Cotações com Filtros (GET)
```http
GET {{base_url}}/api/quotations?status=Aguardando digitação&page=1&limit=10
```

### 2. Cotações por Vendedor (GET)
```http
GET {{base_url}}/api/quotations?sellerId=1
```

### 3. Cotações por Período (GET)
```http
GET {{base_url}}/api/quotations?startDate=2025-01-01&endDate=2025-01-31
```

## Códigos de Erro Comuns

### 400 - Bad Request
```json
{
  "message": "Dados inválidos",
  "errors": [
    "Email é obrigatório",
    "CNPJ deve ter formato válido"
  ]
}
```

### 401 - Unauthorized
```json
{
  "message": "Não autorizado"
}
```

### 403 - Forbidden
```json
{
  "message": "Acesso negado. Apenas administradores podem realizar esta ação"
}
```

### 404 - Not Found
```json
{
  "message": "Recurso não encontrado"
}
```

### 500 - Internal Server Error
```json
{
  "message": "Erro interno do servidor"
}
```

## Coleção Postman (JSON)

```json
{
  "info": {
    "name": "Mix Cotação Web API",
    "description": "Coleção completa da API do sistema Mix Cotação Web",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"administrador@softsan.com.br\",\n  \"password\": \"M1xgestao@2025\"\n}"
            },
            "url": {
              "raw": "{{base_url}}/api/auth/login",
              "host": ["{{base_url}}"],
              "path": ["api", "auth", "login"]
            }
          }
        },
        {
          "name": "Get Current User",
          "request": {
            "method": "GET",
            "url": {
              "raw": "{{base_url}}/api/auth/me",
              "host": ["{{base_url}}"],
              "path": ["api", "auth", "me"]
            }
          }
        },
        {
          "name": "Logout",
          "request": {
            "method": "POST",
            "url": {
              "raw": "{{base_url}}/api/auth/logout",
              "host": ["{{base_url}}"],
              "path": ["api", "auth", "logout"]
            }
          }
        }
      ]
    },
    {
      "name": "Sellers",
      "item": [
        {
          "name": "List Sellers",
          "request": {
            "method": "GET",
            "url": {
              "raw": "{{base_url}}/api/sellers",
              "host": ["{{base_url}}"],
              "path": ["api", "sellers"]
            }
          }
        },
        {
          "name": "Create Seller",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"novo@vendedor.com\",\n  \"name\": \"Carlos Oliveira\",\n  \"password\": \"senha123\",\n  \"status\": \"Ativo\"\n}"
            },
            "url": {
              "raw": "{{base_url}}/api/sellers",
              "host": ["{{base_url}}"],
              "path": ["api", "sellers"]
            }
          }
        }
      ]
    },
    {
      "name": "Quotations",
      "item": [
        {
          "name": "List Quotations",
          "request": {
            "method": "GET",
            "url": {
              "raw": "{{base_url}}/api/quotations",
              "host": ["{{base_url}}"],
              "path": ["api", "quotations"]
            }
          }
        },
        {
          "name": "Create Quotation",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"number\": \"COT-2025-006\",\n  \"deadline\": \"2025-01-25T23:59:59.000Z\",\n  \"supplierCnpj\": \"11.222.333/0001-44\",\n  \"supplierName\": \"Novo Fornecedor Ltda\",\n  \"clientCnpj\": \"55.666.777/0001-88\",\n  \"clientName\": \"Novo Cliente S/A\",\n  \"sellerId\": 1\n}"
            },
            "url": {
              "raw": "{{base_url}}/api/quotations",
              "host": ["{{base_url}}"],
              "path": ["api", "quotations"]
            }
          }
        }
      ]
    }
  ]
}
```

## Dicas para Testes

### 1. Sequência Recomendada
1. Fazer login primeiro
2. Testar endpoints de leitura (GET)
3. Testar criação (POST)
4. Testar atualização (PUT)
5. Testar exclusão (DELETE)

### 2. Variáveis Úteis
- Salvar IDs retornados em variáveis do Postman
- Usar timestamps dinâmicos: `{{$timestamp}}`
- Usar GUIDs: `{{$guid}}`

### 3. Scripts de Teste
```javascript
// Salvar ID da resposta
pm.test("Salvar ID da cotação", function () {
    var jsonData = pm.response.json();
    pm.environment.set("quotation_id", jsonData.id);
});

// Verificar status da resposta
pm.test("Status code é 200", function () {
    pm.response.to.have.status(200);
});
```

Para importar no Postman, copie o JSON da coleção e use "Import" → "Raw text" no Postman.