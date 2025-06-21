# Correção Rápida - PostgreSQL Local

## O Problema
Erro de certificado SSL porque a `DATABASE_URL` está configurada para Neon Database em vez de PostgreSQL local.

## Solução Rápida

### 1. Execute o script automatizado:
```bash
./fix-local-database.sh
```

### 2. Ou corrija manualmente:
```bash
nano .env
```

Substitua a linha `DATABASE_URL` por:
```env
DATABASE_URL=postgresql://mixuser:sua_senha@localhost:5432/mixcotacao
```

### 3. Adicione as variáveis complementares:
```env
PGUSER=mixuser
PGPASSWORD=sua_senha
PGDATABASE=mixcotacao
PGHOST=localhost
PGPORT=5432
```

### 4. Reinicie a aplicação:
```bash
pm2 restart mix-cotacao-web
```

### 5. Verifique os logs:
```bash
pm2 logs mix-cotacao-web
```

## Verificação
Se funcionou, você deve ver nos logs:
- "Database connection successful"
- "Admin exists: true"
- Aplicação respondendo na porta 5000

## Comandos de Teste
```bash
# Testar banco
psql -U mixuser -d mixcotacao -h localhost

# Testar aplicação
curl http://localhost:5000/api/health

# Ver status
pm2 status
```