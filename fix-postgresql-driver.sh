#!/bin/bash

# Script para corrigir driver PostgreSQL para local
# Mix Cotação Web - Mudança Neon para PG

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
log "  Correção Driver PostgreSQL Local"
log "========================================"

# Parar aplicação
log "Parando aplicação..."
pm2 stop all || true

# Instalar driver pg se necessário
log "Instalando driver pg..."
npm install pg @types/pg

# Remover dependência Neon se existir
log "Removendo dependência Neon..."
npm uninstall @neondatabase/serverless || true

# Rebuild aplicação
log "Fazendo rebuild..."
npm run build

# Verificar se .env está correto para PostgreSQL local
if [[ -f ".env" ]]; then
    current_url=$(grep "^DATABASE_URL=" .env | cut -d'=' -f2- | tr -d '"')
    if [[ "$current_url" == *"neon.tech"* ]]; then
        warn "DATABASE_URL ainda aponta para Neon!"
        echo "URL atual: $current_url"
        echo
        read -p "Digite a DATABASE_URL local (postgresql://user:pass@localhost:5432/db): " new_url
        sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"$new_url\"|" .env
        log "DATABASE_URL atualizada"
    fi
fi

# Testar conexão
log "Testando conexão com PostgreSQL local..."
if node -e "
const { Pool } = require('pg');
require('dotenv').config();
const pool = new Pool({ 
  connectionString: process.env.DATABASE_URL,
  ssl: false 
});
pool.query('SELECT version()').then(() => {
  console.log('✅ Conexão OK');
  process.exit(0);
}).catch(err => {
  console.log('❌ Erro:', err.message);
  process.exit(1);
});
"; then
    log "Conexão com banco funcionando"
else
    error "Falha na conexão. Verifique DATABASE_URL e se PostgreSQL está rodando"
fi

# Iniciar aplicação
log "Iniciando aplicação..."
pm2 start production.config.js || pm2 start dist/index.js --name mix-cotacao-web

sleep 3

# Verificar se funcionou
if curl -s http://localhost:5000/api/health &> /dev/null; then
    log "✅ Aplicação funcionando com driver pg!"
else
    warn "⚠️  Aplicação pode não estar respondendo. Verifique logs:"
    echo "pm2 logs mix-cotacao-web"
fi

log "========================================"
log "Driver PostgreSQL configurado!"
log "========================================"