# Mix Cotação Web - API Documentation

## Overview
REST API para integração com sistemas de terceiros. Todas as rotas utilizam autenticação baseada em sessão e retornam dados em formato JSON.

**Base URL:** `http://your-domain.com/api`

## Authentication

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "usuario@empresa.com",
  "password": "senha123"
}
```

**Response:**
```json
{
  "id": 1,
  "name": "Nome do Usuário",
  "email": "usuario@empresa.com",
  "isAdmin": false
}
```

### Logout
```http
POST /api/auth/logout
```

### Verificar Sessão Atual
```http
GET /api/auth/me
```

## Sellers API (Somente Administradores)

### Listar Vendedores
```http
GET /api/sellers
```

**Response:**
```json
[
  {
    "id": 1,
    "email": "vendedor@empresa.com",
    "name": "João Silva",
    "status": "Ativo",
    "createdAt": "2025-01-01T10:00:00Z"
  }
]
```

### Criar Vendedor
```http
POST /api/sellers
Content-Type: application/json

{
  "email": "novo@empresa.com",
  "name": "Maria Santos",
  "password": "senha123",
  "status": "Ativo"
}
```

### Atualizar Vendedor
```http
PUT /api/sellers/1
Content-Type: application/json

{
  "name": "Maria Santos Silva",
  "status": "Inativo"
}
```

### Deletar Vendedor
```http
DELETE /api/sellers/1
```

## Quotations API

### Listar Cotações
```http
GET /api/quotations
```

**Response:**
```json
[
  {
    "id": 1,
    "number": "COT-2025-001",
    "date": "2025-01-10",
    "status": "Aguardando digitação",
    "deadline": "2025-01-15",
    "supplierCnpj": "12.345.678/0001-90",
    "supplierName": "Fornecedor ABC",
    "clientCnpj": "98.765.432/0001-10",
    "clientName": "Cliente XYZ",
    "internalObservation": "Observação interna",
    "sellerId": 1,
    "createdAt": "2025-01-10T08:00:00Z"
  }
]
```

### Obter Cotação Específica
```http
GET /api/quotations/1
```

### Criar Nova Cotação
```http
POST /api/quotations
Content-Type: application/json

{
  "date": "2025-01-10",
  "deadline": "2025-01-15",
  "supplierCnpj": "12.345.678/0001-90",
  "supplierName": "Fornecedor ABC",
  "clientCnpj": "98.765.432/0001-10",
  "clientName": "Cliente XYZ",
  "internalObservation": "Observação interna",
  "sellerId": 1
}
```

### Atualizar Cotação
```http
PUT /api/quotations/1
Content-Type: application/json

{
  "status": "Enviada",
  "internalObservation": "Cotação finalizada"
}
```

### Deletar Cotação
```http
DELETE /api/quotations/1
```

## Quotation Items API

### Listar Itens de uma Cotação
```http
GET /api/quotations/1/items
```

**Response:**
```json
[
  {
    "id": 1,
    "quotationId": 1,
    "barcode": "7891234567890",
    "productName": "Produto ABC",
    "quotedQuantity": 10,
    "availableQuantity": 8,
    "unitPrice": "25.50",
    "validity": "2025-02-01",
    "situation": "Disponível"
  }
]
```

### Criar Item
```http
POST /api/quotation-items
Content-Type: application/json

{
  "quotationId": 1,
  "barcode": "7891234567890",
  "productName": "Produto ABC",
  "quotedQuantity": 10
}
```

### Atualizar Item
```http
PATCH /api/quotation-items/1
Content-Type: application/json

{
  "availableQuantity": 8,
  "unitPrice": "25.50",
  "validity": "2025-02-01",
  "situation": "Disponível"
}
```

### Deletar Item
```http
DELETE /api/quotation-items/1
```

## Dashboard API

### Estatísticas
```http
GET /api/dashboard/stats
```

**Response:**
```json
{
  "total": 15,
  "aguardandoDigitacao": 3,
  "enviadas": 10,
  "prazoEncerrado": 2
}
```

## Códigos de Status HTTP

- `200` - Sucesso
- `201` - Criado com sucesso
- `400` - Dados inválidos
- `401` - Não autorizado (login necessário)
- `403` - Acesso negado (permissão insuficiente)
- `404` - Recurso não encontrado
- `500` - Erro interno do servidor

## Exemplos de Integração

### Python
```python
import requests

# Login
session = requests.Session()
login_response = session.post('http://your-domain.com/api/auth/login', json={
    'email': 'admin@empresa.com',
    'password': 'senha123'
})

if login_response.status_code == 200:
    user = login_response.json()
    print(f"Logado como: {user['name']}")
    
    # Listar cotações
    quotations = session.get('http://your-domain.com/api/quotations')
    print(f"Total de cotações: {len(quotations.json())}")
    
    # Criar nova cotação
    new_quotation = session.post('http://your-domain.com/api/quotations', json={
        'date': '2025-01-15',
        'deadline': '2025-01-20',
        'supplierCnpj': '12.345.678/0001-90',
        'supplierName': 'Fornecedor API',
        'clientCnpj': '98.765.432/0001-10',
        'clientName': 'Cliente API',
        'sellerId': user['id']
    })
    
    if new_quotation.status_code == 201:
        quotation = new_quotation.json()
        print(f"Cotação criada: {quotation['number']}")
```

### JavaScript/Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'http://your-domain.com/api',
  withCredentials: true
});

async function integrationExample() {
  try {
    // Login
    const loginResponse = await api.post('/auth/login', {
      email: 'admin@empresa.com',
      password: 'senha123'
    });
    
    console.log(`Logado como: ${loginResponse.data.name}`);
    
    // Listar vendedores (admin only)
    const sellers = await api.get('/sellers');
    console.log(`Total de vendedores: ${sellers.data.length}`);
    
    // Criar vendedor
    const newSeller = await api.post('/sellers', {
      email: 'novo@empresa.com',
      name: 'Vendedor API',
      password: 'senha123',
      status: 'Ativo'
    });
    
    console.log(`Vendedor criado: ${newSeller.data.name}`);
    
    // Obter estatísticas
    const stats = await api.get('/dashboard/stats');
    console.log(`Estatísticas:`, stats.data);
    
  } catch (error) {
    console.error('Erro na integração:', error.response?.data || error.message);
  }
}

integrationExample();
```

### PHP
```php
<?php
// Iniciar sessão para manter cookies
session_start();

function apiRequest($method, $url, $data = null) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'http://your-domain.com/api' . $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    curl_setopt($ch, CURLOPT_COOKIEJAR, 'cookies.txt');
    curl_setopt($ch, CURLOPT_COOKIEFILE, 'cookies.txt');
    
    if ($data) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return ['code' => $httpCode, 'data' => json_decode($response, true)];
}

// Login
$login = apiRequest('POST', '/auth/login', [
    'email' => 'admin@empresa.com',
    'password' => 'senha123'
]);

if ($login['code'] == 200) {
    echo "Logado como: " . $login['data']['name'] . "\n";
    
    // Listar cotações
    $quotations = apiRequest('GET', '/quotations');
    echo "Total de cotações: " . count($quotations['data']) . "\n";
    
    // Criar item em cotação
    $newItem = apiRequest('POST', '/quotation-items', [
        'quotationId' => 1,
        'barcode' => '7891234567890',
        'productName' => 'Produto via API',
        'quotedQuantity' => 5
    ]);
    
    if ($newItem['code'] == 201) {
        echo "Item criado com ID: " . $newItem['data']['id'] . "\n";
    }
}
?>
```

## Notas Importantes

1. **Autenticação:** Todas as requisições (exceto login) requerem autenticação válida
2. **Permissões:** Administradores têm acesso total; vendedores só acessam seus próprios dados
3. **Formato de Data:** Use formato ISO 8601 (YYYY-MM-DD)
4. **Preços:** Envie como string com ponto decimal (ex: "25.50")
5. **Status da Cotação:** "Aguardando digitação", "Enviada", "Prazo Encerrado"
6. **Status do Vendedor:** "Ativo", "Inativo"

## Suporte

Para dúvidas sobre a integração, consulte os logs do servidor ou entre em contato com o administrador do sistema.