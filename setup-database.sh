#!/bin/bash

# Script para configurar banco de dados inicial
# Mix Cotação Web - Setup do Administrador
# Uso: ./setup-database.sh

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

log "================================="
log "  Mix Cotação Web - Setup DB"
log "================================="

# Verificar se arquivo SQL existe
if [[ ! -f "database_setup.sql" ]]; then
    error "Arquivo database_setup.sql não encontrado"
fi

# Obter credenciais do banco
if [[ -f ".env" ]]; then
    log "Carregando configurações do .env..."
    source .env
    DB_USER=$PGUSER
    DB_PASSWORD=$PGPASSWORD
    DB_NAME=$PGDATABASE
    DB_HOST=${PGHOST:-localhost}
    DB_PORT=${PGPORT:-5432}
else
    log "Arquivo .env não encontrado, solicitando credenciais..."
    read -p "Digite o usuário do banco (padrão: mixuser): " DB_USER
    DB_USER=${DB_USER:-mixuser}
    
    read -p "Digite o nome do banco (padrão: mixcotacao): " DB_NAME
    DB_NAME=${DB_NAME:-mixcotacao}
    
    read -p "Digite o host do banco (padrão: localhost): " DB_HOST
    DB_HOST=${DB_HOST:-localhost}
    
    read -p "Digite a porta do banco (padrão: 5432): " DB_PORT
    DB_PORT=${DB_PORT:-5432}
    
    read -p "Digite a senha do banco: " -s DB_PASSWORD
    echo
    
    if [[ -z "$DB_PASSWORD" ]]; then
        error "Senha do banco é obrigatória"
    fi
fi

# Testar conexão
log "Testando conexão com banco de dados..."
PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
    error "Falha na conexão com banco de dados. Verifique as credenciais."
fi

log "Conexão estabelecida com sucesso"

# Executar script SQL
log "Executando script de configuração..."
PGPASSWORD=$DB_PASSWORD psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -f database_setup.sql

if [[ $? -eq 0 ]]; then
    log "Script executado com sucesso!"
    echo
    log "Credenciais de acesso:"
    echo "• Email: administrador@softsan.com.br"
    echo "• Senha: M1xgestao@2025"
    echo
    log "Usuário de teste criado:"
    echo "• Email: teste@softsan.com.br"
    echo "• Senha: 123456"
    echo
    log "Configuração do banco concluída!"
else
    error "Falha na execução do script SQL"
fi