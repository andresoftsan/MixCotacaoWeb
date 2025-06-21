# Configuração de Variáveis de Ambiente - AWS

## Problema
O servidor não está carregando as variáveis do arquivo `.env` corretamente.

## Soluções

### Método 1: Script Automatizado
```bash
./fix-env-variables.sh
```

### Método 2: Correção Manual

#### 1. Verificar se .env existe
```bash
ls -la .env
cat .env
```

#### 2. Instalar dotenv se necessário
```bash
npm install dotenv
```

#### 3. Rebuild da aplicação
```bash
npm run build
```

#### 4. Configurar PM2 com env_file
```bash
# Usar configuração que carrega .env
pm2 start production.config.js
```

#### 5. Testar carregamento
```bash
# Criar teste rápido
node -e "require('dotenv').config(); console.log('DATABASE_URL:', !!process.env.DATABASE_URL);"
```

### Método 3: Carregar Manualmente
```bash
# Exportar variáveis para a sessão
source load-env.sh
pm2 start dist/index.js --name mix-cotacao-web
```

## Verificações

### 1. Teste de Variáveis
```bash
pm2 logs mix-cotacao-web | grep "DATABASE_URL\|SESSION_SECRET"
```

### 2. Health Check
```bash
curl http://localhost:5000/api/health
```

### 3. Logs da Aplicação
```bash
pm2 logs mix-cotacao-web --lines 20
```

## Exemplo de .env Correto
```env
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://mixuser:senha@localhost:5432/mixcotacao
SESSION_SECRET=chave_secreta_longa_aqui
PGUSER=mixuser
PGPASSWORD=senha
PGDATABASE=mixcotacao
PGHOST=localhost
PGPORT=5432
```

## Troubleshooting

### Se ainda não funcionar:
1. Verificar permissões do arquivo .env
2. Certificar que não há espaços extras nas variáveis
3. Usar aspas para valores com caracteres especiais
4. Reiniciar completamente o PM2