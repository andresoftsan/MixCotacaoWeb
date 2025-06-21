# Exemplos de Uso da API - Mix Cotação Web

## Token Configurado
```
mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

## Exemplos Práticos

### 1. Listar Todas as Cotações
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     http://localhost:5000/api/quotations
```

### 2. Buscar Cotações por Cliente
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     "http://localhost:5000/api/quotations?search=PAULO%20FERNANDO"
```

### 3. Criar Nova Cotação
```bash
curl -X POST \
     -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     -H "Content-Type: application/json" \
     -d '{
       "date": "2025-06-21",
       "deadline": "2025-06-28",
       "supplierCnpj": "12.345.678/0001-90",
       "supplierName": "Distribuidora Exemplo Ltda",
       "clientCnpj": "98.765.432/0001-10",
       "clientName": "Supermercado Cliente SA",
       "internalObservation": "Solicitação de produtos básicos"
     }' \
     http://localhost:5000/api/quotations
```

### 4. Buscar Cotação Específica
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     http://localhost:5000/api/quotations/1
```

### 5. Atualizar Cotação
```bash
curl -X PUT \
     -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     -H "Content-Type: application/json" \
     -d '{
       "status": "Enviada",
       "internalObservation": "Cotação enviada para o cliente"
     }' \
     http://localhost:5000/api/quotations/1
```

### 6. Adicionar Item à Cotação
```bash
curl -X POST \
     -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     -H "Content-Type: application/json" \
     -d '{
       "barcode": "7891234567890",
       "productName": "Produto Exemplo 500g",
       "quotedQuantity": 100,
       "availableQuantity": 80,
       "unitPrice": "15.50",
       "validity": "2025-07-01T23:59:59.000Z",
       "situation": "Disponível"
     }' \
     http://localhost:5000/api/quotations/1/items
```

### 7. Listar Itens de uma Cotação
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     http://localhost:5000/api/quotations/1/items
```

### 8. Atualizar Item de Cotação
```bash
curl -X PUT \
     -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     -H "Content-Type: application/json" \
     -d '{
       "availableQuantity": 90,
       "unitPrice": "14.80",
       "situation": "Disponível"
     }' \
     http://localhost:5000/api/quotation-items/1
```

### 9. Estatísticas do Dashboard
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     http://localhost:5000/api/dashboard/stats
```

### 10. Listar Vendedores (Admin apenas)
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     http://localhost:5000/api/sellers
```

## Respostas da API

### Sucesso na Criação de Cotação
```json
{
  "id": 17,
  "number": "COT-2025-019",
  "date": "2025-06-21T00:00:00.000Z",
  "status": "Aguardando digitação",
  "deadline": "2025-06-28T00:00:00.000Z",
  "supplierCnpj": "12.345.678/0001-90",
  "supplierName": "Distribuidora Exemplo Ltda",
  "clientCnpj": "98.765.432/0001-10",
  "clientName": "Supermercado Cliente SA",
  "internalObservation": "Solicitação de produtos básicos",
  "sellerId": 2,
  "createdAt": "2025-06-21T17:45:00.000Z"
}
```

### Erro de Autenticação
```json
{
  "message": "Não autorizado"
}
```

### Erro de Validação
```json
{
  "message": "Erro de validação",
  "errors": [
    {
      "path": ["supplierCnpj"],
      "message": "CNPJ é obrigatório"
    }
  ]
}
```

## Códigos de Status HTTP

- `200` - Sucesso (GET, PUT)
- `201` - Criado com sucesso (POST)
- `400` - Erro de validação
- `401` - Não autorizado
- `403` - Acesso negado
- `404` - Item não encontrado
- `500` - Erro interno do servidor

## Campos Obrigatórios

### Criar Cotação
- `date` (string ISO)
- `deadline` (string ISO)
- `supplierCnpj` (string)
- `supplierName` (string)
- `clientCnpj` (string)
- `clientName` (string)

### Adicionar Item
- `barcode` (string)
- `productName` (string)
- `quotedQuantity` (number)

## Campos Automáticos

- `number` - Gerado automaticamente (COT-YYYY-NNN)
- `sellerId` - Extraído do token de autenticação
- `createdAt` - Timestamp automático
- `status` - Inicia como "Aguardando digitação"