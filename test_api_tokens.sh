#!/bin/bash

# Script para testar tokens de API
# Mix Cotação Web - Teste de Autenticação API

API_KEY="mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
BASE_URL="http://localhost:5000"

echo "========================================"
echo "  Testando API Tokens - Mix Cotação"
echo "========================================"

# Teste 1: Listar cotações
echo "1. Testando GET /api/quotations"
curl -s -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     "$BASE_URL/api/quotations" | jq '.' 2>/dev/null || echo "Resposta recebida (sem jq)"

echo -e "\n"

# Teste 2: Listar vendedores (apenas admin)
echo "2. Testando GET /api/sellers"
curl -s -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     "$BASE_URL/api/sellers" | jq '.' 2>/dev/null || echo "Resposta recebida (sem jq)"

echo -e "\n"

# Teste 3: Estatísticas do dashboard
echo "3. Testando GET /api/dashboard/stats"
curl -s -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     "$BASE_URL/api/dashboard/stats" | jq '.' 2>/dev/null || echo "Resposta recebida (sem jq)"

echo -e "\n"

# Teste 4: Health check
echo "4. Testando GET /api/health"
curl -s "$BASE_URL/api/health" | jq '.' 2>/dev/null || echo "Resposta recebida (sem jq)"

echo -e "\n"

# Teste 5: Criar cotação via API
echo "5. Testando POST /api/quotations (criar cotação)"
curl -s -X POST \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "number": "API-TEST-001",
       "date": "2025-06-21",
       "deadline": "2025-06-25",
       "supplierCnpj": "12.345.678/0001-90",
       "supplierName": "Fornecedor API Teste",
       "clientCnpj": "98.765.432/0001-10",
       "clientName": "Cliente API Teste",
       "internalObservation": "Cotação criada via API para teste"
     }' \
     "$BASE_URL/api/quotations" | jq '.' 2>/dev/null || echo "Resposta recebida (sem jq)"

echo -e "\n========================================"
echo "Testes de API concluídos!"
echo "========================================"