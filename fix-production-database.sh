#!/bin/bash

# Script para corrigir configuração do banco de dados em produção
# Mix Cotação Web - Correção DATABASE_URL

set -e

# Cores para output
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
log "  Correção Database URL - Produção"
log "========================================"

# Verificar se estamos no diretório correto
if [[ ! -f ".env" ]]; then
    error "Arquivo .env não encontrado. Execute este script no diretório da aplicação."
fi

# Fazer backup do .env atual
log "Fazendo backup do arquivo .env..."
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Detectar o problema atual
current_url=$(grep "^DATABASE_URL=" .env | cut -d'=' -f2- | tr -d '"')
log "URL atual do banco: $current_url"

# Verificar se há problema de localhost no URL
if [[ "$current_url" == *"localhost"* ]]; then
    warn "Detectado 'localhost' na DATABASE_URL, mas estamos em produção!"
    
    # Solicitar a URL correta
    echo
    read -p "Digite a DATABASE_URL correta (do painel Neon): " new_database_url
    
    if [[ -z "$new_database_url" ]]; then
        error "DATABASE_URL não pode estar vazia"
    fi
    
    # Atualizar o arquivo .env
    log "Atualizando DATABASE_URL no arquivo .env..."
    sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"$new_database_url\"|" .env
    
    # Atualizar outras variáveis relacionadas se necessário
    if grep -q "^PGHOST=localhost" .env; then
        log "Atualizando PGHOST..."
        # Extrair host da nova URL
        new_host=$(echo "$new_database_url" | sed -n 's|.*@\([^:]*\):.*|\1|p')
        sed -i "s|^PGHOST=.*|PGHOST=$new_host|" .env
    fi
    
elif [[ "$current_url" == *"neon.tech"* ]] || [[ "$current_url" == *"aws"* ]]; then
    log "DATABASE_URL parece estar correta para produção"
    echo "URL atual: $current_url"
    
    # Verificar se a conexão está funcionando
    log "Testando conexão com banco..."
    if command -v psql &> /dev/null; then
        if psql "$current_url" -c "SELECT version();" &> /dev/null; then
            log "✅ Conexão com banco funcionando!"
        else
            warn "❌ Falha na conexão com banco. Verifique a URL."
        fi
    else
        warn "psql não encontrado, não foi possível testar a conexão"
    fi
else
    warn "Formato da DATABASE_URL não reconhecido"
    echo "URL atual: $current_url"
    echo
    read -p "Deseja atualizar mesmo assim? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Digite a nova DATABASE_URL: " new_database_url
        sed -i "s|^DATABASE_URL=.*|DATABASE_URL=\"$new_database_url\"|" .env
    fi
fi

# Mostrar configurações atualizadas
log "Configurações atuais:"
echo "DATABASE_URL: $(grep "^DATABASE_URL=" .env | cut -d'=' -f2-)"
echo "PGHOST: $(grep "^PGHOST=" .env | cut -d'=' -f2- || echo 'não definido')"
echo "PGDATABASE: $(grep "^PGDATABASE=" .env | cut -d'=' -f2- || echo 'não definido')"

# Reiniciar aplicação
log "Reiniciando aplicação..."
if command -v pm2 &> /dev/null; then
    pm2 restart mix-cotacao-web || pm2 restart all
    log "Aplicação reiniciada com PM2"
else
    warn "PM2 não encontrado. Reinicie a aplicação manualmente."
fi

# Testar se aplicação está funcionando
sleep 3
log "Testando aplicação..."
if curl -s http://localhost:5000/api/health &> /dev/null; then
    log "✅ Aplicação respondendo na porta 5000"
else
    warn "❌ Aplicação não está respondendo. Verifique os logs:"
    echo "pm2 logs mix-cotacao-web"
fi

log "========================================"
log "Correção concluída!"
log "========================================"
echo
log "Próximos passos:"
echo "1. Verifique os logs: pm2 logs mix-cotacao-web"
echo "2. Teste o login no navegador"
echo "3. Se ainda houver erro, verifique a DATABASE_URL no painel Neon"
echo
log "Backup do .env criado em: .env.backup.*"