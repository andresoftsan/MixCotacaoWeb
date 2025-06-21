#!/bin/bash

# Script para corrigir DATABASE_URL para PostgreSQL local
# Mix Cotação Web - Correção para banco local

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log "========================================"
log "  Correção DATABASE_URL - PostgreSQL Local"
log "========================================"

# Verificar se estamos no diretório correto
if [[ ! -f ".env" ]]; then
    error "Arquivo .env não encontrado. Execute no diretório da aplicação."
fi

# Fazer backup
log "Fazendo backup do .env..."
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Solicitar credenciais do banco local
echo
log "Configure as credenciais do PostgreSQL local:"
read -p "Usuário do banco (padrão: mixuser): " DB_USER
DB_USER=${DB_USER:-mixuser}

read -p "Nome do banco (padrão: mixcotacao): " DB_NAME
DB_NAME=${DB_NAME:-mixcotacao}

read -p "Senha do banco: " -s DB_PASSWORD
echo
read -p "Porta (padrão: 5432): " DB_PORT
DB_PORT=${DB_PORT:-5432}

if [[ -z "$DB_PASSWORD" ]]; then
    error "Senha é obrigatória"
fi

# Criar nova DATABASE_URL para PostgreSQL local
NEW_DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}"

log "Atualizando configurações no .env..."

# Atualizar .env
sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"$NEW_DATABASE_URL\"|" .env
sed -i "s|^PGUSER=.*|PGUSER=$DB_USER|" .env
sed -i "s|^PGPASSWORD=.*|PGPASSWORD=$DB_PASSWORD|" .env
sed -i "s|^PGDATABASE=.*|PGDATABASE=$DB_NAME|" .env
sed -i "s|^PGHOST=.*|PGHOST=localhost|" .env
sed -i "s|^PGPORT=.*|PGPORT=$DB_PORT|" .env

# Adicionar variáveis se não existirem
if ! grep -q "^PGUSER=" .env; then
    echo "PGUSER=$DB_USER" >> .env
fi
if ! grep -q "^PGPASSWORD=" .env; then
    echo "PGPASSWORD=$DB_PASSWORD" >> .env
fi
if ! grep -q "^PGDATABASE=" .env; then
    echo "PGDATABASE=$DB_NAME" >> .env
fi
if ! grep -q "^PGHOST=" .env; then
    echo "PGHOST=localhost" >> .env
fi
if ! grep -q "^PGPORT=" .env; then
    echo "PGPORT=$DB_PORT" >> .env
fi

log "Configurações atualizadas:"
echo "DATABASE_URL: postgresql://$DB_USER:***@localhost:$DB_PORT/$DB_NAME"
echo "PGHOST: localhost"
echo "PGUSER: $DB_USER"
echo "PGDATABASE: $DB_NAME"
echo "PGPORT: $DB_PORT"

# Testar conexão
log "Testando conexão com banco local..."
if PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h localhost -p $DB_PORT -d $DB_NAME -c "SELECT version();" &> /dev/null; then
    log "✅ Conexão com banco funcionando!"
else
    error "❌ Falha na conexão. Verifique as credenciais e se o PostgreSQL está rodando."
fi

# Executar migração se necessário
if [[ -f "package.json" ]] && grep -q "db:push" package.json; then
    log "Executando migração do banco..."
    npm run db:push
fi

# Reiniciar aplicação
log "Reiniciando aplicação..."
if command -v pm2 &> /dev/null; then
    pm2 restart mix-cotacao-web || pm2 restart all
    log "Aplicação reiniciada com PM2"
    
    # Aguardar um pouco e testar
    sleep 3
    if curl -s http://localhost:5000/api/health &> /dev/null; then
        log "✅ Aplicação respondendo corretamente!"
    else
        warn "⚠️  Aplicação pode não estar respondendo. Verifique os logs:"
        echo "pm2 logs mix-cotacao-web"
    fi
else
    warn "PM2 não encontrado. Reinicie manualmente a aplicação."
fi

log "========================================"
log "Correção concluída!"
log "========================================"
echo
log "Teste o login:"
echo "URL: http://seu-dominio.com"
echo "Email: administrador@softsan.com.br"
echo "Senha: M1xgestao@2025"