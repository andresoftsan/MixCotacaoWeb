# Mix Cotação Web - Guia de Implantação em Banco Externo

## Passo a Passo para Configuração

### 1. Preparação do Banco PostgreSQL

Execute o script SQL completo no seu banco PostgreSQL:

```bash
psql -h seu-host -U seu-usuario -d sua-base-de-dados -f database_setup.sql
```

Ou copie e cole o conteúdo do arquivo `database_setup.sql` no seu cliente PostgreSQL (pgAdmin, DBeaver, etc.).

### 2. Configuração da Aplicação

Defina a variável de ambiente `DATABASE_URL` apontando para seu banco:

```bash
export DATABASE_URL="postgresql://usuario:senha@host:porta/database"
```

### 3. Credenciais de Acesso

**Administrador:**
- Email: `administrador@softsan.com.br`
- Senha: `M1xgestao@2025`

**Vendedores de Teste:**
- Email: `joao.silva@empresa.com.br` / Senha: `123456`
- Email: `maria.santos@empresa.com.br` / Senha: `123456`
- Email: `pedro.oliveira@empresa.com.br` / Senha: `123456`
- Email: `ana.costa@empresa.com.br` / Senha: `123456` (Inativo)

### 4. Dados de Teste Incluídos

**8 Cotações de Exemplo:**
- COT-2025-001 até COT-2025-008
- Diferentes status: Aguardando digitação, Enviada, Prazo Encerrado
- 25+ itens distribuídos entre as cotações
- Produtos com códigos de barras realistas

**Estrutura Completa:**
- 5 usuários (1 admin + 4 vendedores)
- 8 cotações com diferentes status
- 25 itens de cotação
- 3 chaves API de exemplo
- Índices para performance otimizada

### 5. Verificação da Instalação

Após executar o script, você verá um resumo similar a:

```
tabela          | total_registros
Sellers         | 5
Quotations      | 8
Quotation Items | 25
API Keys        | 3
```

### 6. Conectar a Aplicação

Configure sua aplicação Mix Cotação Web com:

```bash
DATABASE_URL=postgresql://seu-usuario:sua-senha@seu-host:porta/sua-base
SESSION_SECRET=sua-chave-secreta-producao
NODE_ENV=production
```

### 7. Primeiro Acesso

1. Acesse a aplicação
2. Faça login com `administrador@softsan.com.br` / `M1xgestao@2025`
3. Verifique as cotações de teste no dashboard
4. Teste a funcionalidade de edição
5. Acesse Configurações para gerenciar usuários

### 8. Personalização

**Alterar Credenciais:**
1. Faça login como administrador
2. Vá em Configurações → Vendedores
3. Edite usuários existentes ou crie novos
4. Remova vendedores de teste se necessário

**Limpar Dados de Teste:**
```sql
-- Remover cotações de teste (opcional)
DELETE FROM quotation_items WHERE quotation_id IN (SELECT id FROM quotations WHERE number LIKE 'COT-2025-%');
DELETE FROM quotations WHERE number LIKE 'COT-2025-%';

-- Remover vendedores de teste (opcional) 
DELETE FROM sellers WHERE email LIKE '%@empresa.com.br';
```

### 9. Backup e Manutenção

**Backup Regular:**
```bash
pg_dump -h host -U usuario -d database > backup_mix_cotacao_$(date +%Y%m%d).sql
```

**Limpeza de Cotações Expiradas:**
```sql
-- Sistema já atualiza automaticamente, mas pode executar manualmente:
UPDATE quotations 
SET status = 'Prazo Encerrado' 
WHERE deadline < NOW() AND status = 'Aguardando digitação';
```

## Estrutura das Tabelas

### sellers
- Usuários do sistema (admin/vendedores)
- Autenticação com bcrypt
- Status ativo/inativo

### quotations  
- Cotações principais
- Referência ao vendedor responsável
- Status automático baseado em prazo

### quotation_items
- Itens individuais de cada cotação
- Campos para preço, disponibilidade, validade
- Situação: Disponível/Parcial/Indisponível

### api_keys
- Chaves para integração com terceiros
- Controle de ativação e uso

## Integração com Sistemas Externos

Consulte `API_DOCUMENTATION.md` e `API_CREDENTIALS_SETUP.md` para detalhes completos sobre:

- Endpoints disponíveis
- Autenticação por sessão
- Exemplos de integração
- Códigos de exemplo em Python/JavaScript

## Suporte

- Verifique logs da aplicação para diagnóstico
- Use as consultas SQL de verificação incluídas no script
- Consulte a documentação da API para integrações

**Script executado com sucesso = Sistema pronto para uso!**