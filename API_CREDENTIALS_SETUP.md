# Configuração de Credenciais - Mix Cotação Web

## Token de API Configurado

### Chave Principal
```
mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

**Usuário:** administrador@softsan.com.br  
**Tipo:** Administrador  
**Status:** Ativo  
**Criada em:** 21/06/2025

## Credenciais de Login Web

### Administrador
- **Email:** administrador@softsan.com.br
- **Senha:** M1xgestao@2025
- **Permissões:** Administração completa

### Usuários de Teste
- **Email:** vendedor1@softsan.com.br (José Antonio)
- **Email:** vendedor2@softsan.com.br (Antonio)
- **Senha padrão:** Definida individualmente

## Status da Configuração

✅ **Token de API funcionando**
- Autenticação Bearer token implementada
- Criação de cotações via API testada
- Listagem e busca funcionando
- Adição de itens testada

✅ **Banco PostgreSQL**
- Driver pg configurado corretamente
- Conexão estável com banco local
- Schema completo implementado

✅ **Autenticação Web**
- Login por sessão funcionando
- Permissões de admin/vendedor configuradas
- Logout seguro implementado

## Testes Realizados

### API Endpoints Testados
1. `GET /api/quotations` - ✅ Funcionando
2. `POST /api/quotations` - ✅ Funcionando
3. `GET /api/quotations/:id` - ✅ Funcionando
4. `PUT /api/quotations/:id` - ✅ Funcionando
5. `POST /api/quotations/:id/items` - ✅ Funcionando
6. `GET /api/quotations/:id/items` - ✅ Funcionando
7. `GET /api/sellers` - ✅ Funcionando
8. `GET /api/dashboard/stats` - ✅ Funcionando
9. `GET /api/health` - ✅ Funcionando

### Funcionalidades Validadas
- Numeração automática de cotações (COT-YYYY-NNN)
- Atribuição automática de sellerId via token
- Validação de dados com Zod schemas
- Permissões baseadas em roles
- Busca e filtros funcionando

## Scripts de Teste Disponíveis

- `test_api_tokens.sh` - Teste geral de endpoints
- `test-create-item.sh` - Teste completo de criação
- `fix-postgresql-driver.sh` - Correção de driver DB
- `install-ec2.sh` - Instalação completa AWS

## Para Desenvolvedores

### Usar Token na API
```bash
curl -H "Authorization: Bearer mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456" \
     http://localhost:5000/api/quotations
```

### Criar Novo Token
```sql
INSERT INTO api_keys (name, key, seller_id, is_active) 
VALUES ('Nome do Token', 'mixapi_NOVA_CHAVE_AQUI', 2, true);
```

### Verificar Tokens Ativos
```sql
SELECT ak.name, ak.key, s.email, ak.is_active 
FROM api_keys ak 
JOIN sellers s ON ak.seller_id = s.id 
WHERE ak.is_active = true;
```