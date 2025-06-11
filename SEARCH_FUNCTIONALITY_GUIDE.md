# Guia de Funcionalidades de Busca - Mix Cotação Web

## Visão Geral

O sistema Mix Cotação Web agora inclui funcionalidades avançadas de busca para vendedores e cotações, permitindo localização rápida e eficiente de dados específicos através da API.

## 1. Busca de Vendedores por E-mail

### Endpoint
```
GET /api/sellers?email={email}
```

### Autenticação
- Token API: `Authorization: Bearer {token}`
- Sessão web autenticada

### Parâmetros
- `email` (query parameter): E-mail do vendedor a ser localizado

### Exemplos de Uso

#### Busca Bem-sucedida
```bash
curl -X GET \
  -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
  "http://localhost:5000/api/sellers?email=administrador@softsan.com.br"
```

**Resposta (200):**
```json
{
  "id": 2,
  "email": "administrador@softsan.com.br",
  "name": "Administrador",
  "status": "Ativo",
  "createdAt": "2025-06-10T14:52:58.120Z"
}
```

#### Vendedor Não Encontrado
```bash
curl -X GET \
  -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
  "http://localhost:5000/api/sellers?email=inexistente@email.com"
```

**Resposta (404):**
```json
{
  "message": "Vendedor não encontrado"
}
```

## 2. Busca de Cotações por CNPJ e Número

### Endpoint
```
GET /api/quotations?clientCnpj={cnpj}&number={numero}
```

### Autenticação
- Token API: `Authorization: Bearer {token}`
- Sessão web autenticada

### Parâmetros
- `clientCnpj` (query parameter): CNPJ do cliente
- `number` (query parameter): Número da cotação

### Controle de Acesso
- **Administradores**: Podem buscar qualquer cotação
- **Vendedores**: Apenas cotações de sua responsabilidade

### Exemplos de Uso

#### Busca Bem-sucedida
```bash
curl -X GET \
  -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
  "http://localhost:5000/api/quotations?clientCnpj=98.765.432/0001-10&number=COT-2024-001"
```

**Resposta (200):**
```json
{
  "id": 1,
  "number": "COT-2024-001",
  "date": "2024-12-10T10:00:00.000Z",
  "status": "Prazo Encerrado",
  "deadline": "2024-12-17T23:59:59.000Z",
  "supplierCnpj": "12.345.678/0001-90",
  "supplierName": "Distribuidora ABC Ltda",
  "clientCnpj": "98.765.432/0001-10",
  "clientName": "Supermercado XYZ",
  "internalObservation": "Cliente premium - prazo estendido",
  "sellerId": 2,
  "createdAt": "2025-06-10T14:56:02.860Z"
}
```

#### Cotação Não Encontrada
```bash
curl -X GET \
  -H "Authorization: Bearer mxc_test123456789012345678901234567890" \
  "http://localhost:5000/api/quotations?clientCnpj=inexistente&number=invalid"
```

**Resposta (404):**
```json
{
  "message": "Cotação não encontrada"
}
```

#### Acesso Negado (Vendedor sem Permissão)
**Resposta (403):**
```json
{
  "message": "Acesso negado"
}
```

## 3. Implementação Técnica

### Método de Busca no Banco de Dados
```typescript
async getQuotationByClientCnpjAndNumber(clientCnpj: string, number: string): Promise<Quotation | undefined> {
  await this.updateExpiredQuotations();
  
  const [quotation] = await db
    .select()
    .from(quotations)
    .where(and(eq(quotations.clientCnpj, clientCnpj), eq(quotations.number, number)));
  return quotation || undefined;
}
```

### Validação de Acesso
- Verificação automática de permissões por vendedor
- Atualização automática de status de cotações expiradas
- Suporte completo a autenticação híbrida (sessão + token)

## 4. Códigos de Status HTTP

| Código | Descrição |
|--------|-----------|
| 200 | Busca realizada com sucesso |
| 400 | Parâmetros obrigatórios ausentes |
| 401 | Não autorizado (token/sessão inválidos) |
| 403 | Acesso negado (permissões insuficientes) |
| 404 | Recurso não encontrado |
| 500 | Erro interno do servidor |

## 5. Teste das Funcionalidades

Execute o script de teste completo:
```bash
bash test-api-tokens.sh
```

O script inclui testes para:
- Busca de vendedores por e-mail (casos positivo e negativo)
- Busca de cotações por CNPJ e número (casos positivo e negativo)
- Validação de controle de acesso
- Verificação de respostas de erro apropriadas

## 6. Integração com Sistemas Externos

As funcionalidades de busca são totalmente compatíveis com:
- Sistemas ERP
- Plataformas de e-commerce
- Aplicações móveis
- Dashboards personalizados

### Token de Exemplo para Testes
```
mxc_test123456789012345678901234567890
```

*Usuário associado: Administrador (acesso total)*