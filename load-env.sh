#!/bin/bash

# Script para garantir carregamento de variáveis de ambiente
# Execute no servidor antes de iniciar a aplicação

# Exportar variáveis do .env para o ambiente atual
if [ -f .env ]; then
    echo "Carregando variáveis do arquivo .env..."
    export $(grep -v '^#' .env | xargs)
    echo "Variáveis carregadas:"
    echo "NODE_ENV: $NODE_ENV"
    echo "PORT: $PORT"
    echo "DATABASE_URL: ${DATABASE_URL:0:30}..."
    echo "SESSION_SECRET: ${SESSION_SECRET:0:10}..."
else
    echo "Arquivo .env não encontrado!"
    exit 1
fi