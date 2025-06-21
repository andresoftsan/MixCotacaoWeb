#!/bin/bash

# Script para corrigir carregamento de variáveis de ambiente
# Mix Cotação Web - Correção .env

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
log "  Correção Variáveis de Ambiente"
log "========================================"

# Verificar se .env existe
if [[ ! -f ".env" ]]; then
    error "Arquivo .env não encontrado! Crie o arquivo primeiro."
fi

# Mostrar variáveis atuais no .env
log "Variáveis no arquivo .env:"
grep -E "^[A-Z]" .env | head -10

# Verificar se as variáveis estão sendo carregadas
log "Testando carregamento das variáveis..."

# Criar script de teste temporário
cat > test-env.js << 'EOF'
require('dotenv').config();

console.log('=== TESTE DE VARIÁVEIS DE AMBIENTE ===');
console.log('NODE_ENV:', process.env.NODE_ENV || 'não definido');
console.log('PORT:', process.env.PORT || 'não definido');
console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'definido (' + process.env.DATABASE_URL.substring(0, 30) + '...)' : 'não definido');
console.log('SESSION_SECRET:', process.env.SESSION_SECRET ? 'definido (' + process.env.SESSION_SECRET.length + ' caracteres)' : 'não definido');

if (process.env.DATABASE_URL) {
    console.log('✅ DATABASE_URL carregado');
} else {
    console.log('❌ DATABASE_URL não carregado');
}

if (process.env.SESSION_SECRET) {
    console.log('✅ SESSION_SECRET carregado');
} else {
    console.log('❌ SESSION_SECRET não carregado');
}
EOF

# Executar teste
if node test-env.js; then
    log "Teste de carregamento executado"
else
    error "Falha no teste de carregamento"
fi

# Limpar arquivo temporário
rm test-env.js

# Verificar se dotenv está instalado
log "Verificando dependências..."
if npm list dotenv &> /dev/null; then
    log "✅ dotenv instalado"
else
    warn "❌ dotenv não encontrado, instalando..."
    npm install dotenv
fi

# Verificar se o build existe
if [[ ! -f "dist/index.js" ]]; then
    log "Build não encontrado, criando..."
    npm run build
fi

# Opções de carregamento para PM2
log "Configurando PM2 para carregar .env..."

# Atualizar ecosystem.config.js para carregar .env
if [[ -f "ecosystem.config.js" ]]; then
    # Fazer backup
    cp ecosystem.config.js ecosystem.config.js.backup
    
    # Adicionar env_file se não existir
    if ! grep -q "env_file" ecosystem.config.js; then
        log "Adicionando env_file ao ecosystem.config.js..."
        
        # Criar nova configuração com env_file
        cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'mix-cotacao-web',
    script: 'npm',
    args: 'start',
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
    time: true
  }]
};
EOF
        log "ecosystem.config.js atualizado"
    fi
fi

# Alternativa: criar arquivo de inicialização que carrega .env
log "Criando script de inicialização com dotenv..."
cat > start.js << 'EOF'
// Script de inicialização que garante carregamento do .env
require('dotenv').config();

console.log('Carregando variáveis de ambiente...');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('DATABASE_URL configurado:', !!process.env.DATABASE_URL);

// Iniciar a aplicação
require('./dist/index.js');
EOF

# Atualizar package.json para usar o novo script
if grep -q '"start":' package.json; then
    log "Atualizando script start no package.json..."
    sed -i 's/"start": ".*"/"start": "node start.js"/' package.json
fi

log "Reiniciando aplicação com novas configurações..."

# Parar PM2
pm2 stop mix-cotacao-web || true

# Recriar diretório de logs se necessário
mkdir -p logs

# Iniciar com nova configuração
pm2 start ecosystem.config.js

# Aguardar e verificar
sleep 3
pm2 status

log "========================================"
log "Correção concluída!"
log "========================================"
echo
log "Comandos para verificar:"
echo "pm2 logs mix-cotacao-web"
echo "pm2 status"
echo "curl http://localhost:5000/api/health"