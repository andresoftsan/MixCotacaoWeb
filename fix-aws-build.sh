#!/bin/bash

# Script para corrigir problemas de build na AWS
# Mix Cotação Web - Correção de módulos ESM

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
log "  Correção Build AWS - Módulos ESM"
log "========================================"

# Verificar diretório atual
if [[ ! -f "package.json" ]]; then
    error "Execute este script no diretório raiz da aplicação"
fi

# Parar PM2 se estiver rodando
log "Parando processos PM2..."
pm2 stop all || true
pm2 delete all || true

# Limpar cache npm e node_modules
log "Limpando cache e dependências..."
rm -rf node_modules
rm -rf dist
npm cache clean --force

# Reinstalar dependências
log "Reinstalando dependências..."
npm install

# Verificar se dotenv está instalado
if ! npm list dotenv &> /dev/null; then
    log "Instalando dotenv..."
    npm install dotenv
fi

# Rebuild completo
log "Fazendo build completo..."
npm run build

# Verificar se build foi criado
if [[ ! -f "dist/index.js" ]]; then
    error "Build falhou - dist/index.js não foi criado"
fi

log "Build criado com sucesso: $(ls -la dist/)"

# Verificar se .env existe
if [[ ! -f ".env" ]]; then
    warn "Arquivo .env não encontrado!"
    log "Criando .env de exemplo..."
    cat > .env << 'EOF'
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://mixuser:senha@localhost:5432/mixcotacao
SESSION_SECRET=chave_secreta_muito_longa_e_segura_com_pelo_menos_32_caracteres
PGUSER=mixuser
PGPASSWORD=senha
PGDATABASE=mixcotacao
PGHOST=localhost
PGPORT=5432
EOF
    warn "Configure as credenciais corretas no arquivo .env!"
fi

# Criar diretório de logs
mkdir -p logs

# Testar aplicação diretamente primeiro
log "Testando aplicação diretamente..."
timeout 10s node dist/index.js &
PID=$!
sleep 3

if kill -0 $PID 2>/dev/null; then
    log "✅ Aplicação inicia corretamente"
    kill $PID 2>/dev/null || true
else
    error "❌ Aplicação falha ao iniciar diretamente"
fi

# Criar configuração PM2 corrigida
log "Criando configuração PM2 corrigida..."
cat > ecosystem.production.js << 'EOF'
module.exports = {
  apps: [{
    name: 'mix-cotacao-web',
    script: './dist/index.js',
    cwd: process.cwd(),
    env_file: '.env',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    time: true,
    max_restarts: 5,
    min_uptime: '10s'
  }]
};
EOF

# Iniciar com nova configuração
log "Iniciando aplicação com PM2..."
pm2 start ecosystem.production.js

# Aguardar inicialização
sleep 5

# Verificar status
log "Verificando status..."
pm2 status

# Testar se aplicação responde
log "Testando aplicação..."
if curl -s http://localhost:5000/ &> /dev/null; then
    log "✅ Aplicação respondendo na porta 5000"
else
    warn "⚠️  Aplicação pode não estar respondendo"
fi

# Mostrar logs
log "Últimas linhas do log:"
pm2 logs mix-cotacao-web --lines 10

# Salvar configuração PM2
pm2 save

log "========================================"
log "Correção concluída!"
log "========================================"
echo
log "Comandos úteis:"
echo "pm2 logs mix-cotacao-web"
echo "pm2 restart mix-cotacao-web" 
echo "pm2 monit"
echo "curl http://localhost:5000/api/health"