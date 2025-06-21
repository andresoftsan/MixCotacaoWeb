# API Token Setup - Mix Cotação Web

## Chave Configurada

**Token de Produção:**
```
mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

**Associada ao usuário:** administrador@softsan.com.br  
**Permissões:** Administrador (acesso total)  
**Status:** Ativa

## Como Usar

### Cabeçalho de Autenticação
```bash
Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### Exemplos de Uso

**1. Listar Cotações**
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     http://localhost:5000/api/quotations
```

**2. Criar Cotação**
```bash
curl -X POST \
     -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     -H "Content-Type: application/json" \
     -d '{
       "date": "2025-06-21",
       "deadline": "2025-06-25",
       "supplierCnpj": "12.345.678/0001-90",
       "supplierName": "Fornecedor Teste",
       "clientCnpj": "98.765.432/0001-10",
       "clientName": "Cliente Teste",
       "internalObservation": "Cotação via API"
     }' \
     http://localhost:5000/api/quotations
```

**Nota:** O `sellerId` é atribuído automaticamente baseado no token de autenticação. O `number` é gerado automaticamente.

**3. Buscar Cotações**
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     "http://localhost:5000/api/quotations?search=cliente"
```

## Endpoints Disponíveis

### Cotações
- `GET /api/quotations` - Listar cotações
- `POST /api/quotations` - Criar cotação
- `GET /api/quotations/:id` - Buscar cotação específica
- `PUT /api/quotations/:id` - Atualizar cotação
- `DELETE /api/quotations/:id` - Deletar cotação

### Itens de Cotação
- `GET /api/quotations/:id/items` - Listar itens
- `POST /api/quotations/:id/items` - Adicionar item
- `PUT /api/quotation-items/:id` - Atualizar item
- `DELETE /api/quotation-items/:id` - Deletar item

### Vendedores (Admin apenas)
- `GET /api/sellers` - Listar vendedores
- `POST /api/sellers` - Criar vendedor
- `PUT /api/sellers/:id` - Atualizar vendedor
- `DELETE /api/sellers/:id` - Deletar vendedor

### Dashboard
- `GET /api/dashboard/stats` - Estatísticas

### Utilitários
- `GET /api/health` - Status da aplicação

## Gerenciamento de Tokens

### Ver Tokens Existentes
```sql
SELECT ak.name, ak.key, s.email, ak.is_active 
FROM api_keys ak 
JOIN sellers s ON ak.seller_id = s.id;
```

### Criar Novo Token
```sql
INSERT INTO api_keys (name, key, seller_id, is_active) 
VALUES ('Nome do Token', 'mixapi_CHAVE_AQUI', seller_id, true);
```

### Desativar Token
```sql
UPDATE api_keys SET is_active = false WHERE key = 'CHAVE_AQUI';
```

## Teste Automatizado

Execute o script de teste:
```bash
./test_api_tokens.sh
```

## Status da Configuração

✅ Token criado e ativo  
✅ Autenticação funcionando  
✅ Endpoints testados  
✅ Permissões configuradas  
✅ Scripts de teste disponíveis