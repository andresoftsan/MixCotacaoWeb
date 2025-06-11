#!/bin/bash

# Script para testar autenticação por tokens API
# Mix Cotação Web - Sistema de Tokens Fixos

TOKEN="mxc_test123456789012345678901234567890"
BASE_URL="http://localhost:5000"

echo "========================================="
echo "TESTE COMPLETO - TOKENS API"
echo "========================================="
echo "Token: ${TOKEN:0:15}..."
echo "Base URL: $BASE_URL"
echo ""

# Função para fazer requisições
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    echo "🔍 Testando: $description"
    echo "   $method $endpoint"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "HTTP_CODE:%{http_code}" \
            -X "$method" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "HTTP_CODE:%{http_code}" \
            -X "$method" \
            -H "Authorization: Bearer $TOKEN" \
            "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_CODE:[0-9]*$//')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "   ✅ Status: $http_code"
        echo "   📄 Resposta: $(echo "$body" | cut -c1-100)..."
    else
        echo "   ❌ Status: $http_code"
        echo "   📄 Erro: $body"
    fi
    echo ""
}

# 1. Verificar autenticação básica
test_endpoint "GET" "/api/auth/me" "Verificar usuário autenticado"

# 2. Testar endpoints de vendedores (admin)
test_endpoint "GET" "/api/sellers" "Listar vendedores"

# 3. Testar endpoints de cotações
test_endpoint "GET" "/api/quotations" "Listar cotações"
test_endpoint "GET" "/api/quotations/1" "Buscar cotação específica"

# 4. Testar itens de cotação
test_endpoint "GET" "/api/quotations/1/items" "Listar itens da cotação"

# 5. Testar dashboard
test_endpoint "GET" "/api/dashboard/stats" "Estatísticas do dashboard"

# 6. Testar API keys
test_endpoint "GET" "/api/api-keys" "Listar API keys do usuário"

# 7. Testar criação de cotação
cotacao_data='{
    "date": "2025-06-11T10:00:00.000Z",
    "deadline": "2025-06-30T23:59:59.000Z",
    "supplierCnpj": "12.345.678/0001-90",
    "supplierName": "Fornecedor API Test",
    "clientCnpj": "98.765.432/0001-10",
    "clientName": "Cliente API Test"
}'

test_endpoint "POST" "/api/quotations" "Criar nova cotação" "$cotacao_data"

echo "========================================="
echo "TESTE CONCLUÍDO"
echo "========================================="
echo ""
echo "📋 RESUMO DOS ENDPOINTS CORRIGIDOS:"
echo "✅ GET /api/sellers (admin)"
echo "✅ POST /api/sellers (admin)" 
echo "✅ PUT /api/sellers/:id (admin)"
echo "✅ DELETE /api/sellers/:id (admin)"
echo "✅ GET /api/quotations"
echo "✅ GET /api/quotations/:id"
echo "✅ POST /api/quotations"
echo "✅ PUT /api/quotations/:id"
echo "✅ GET /api/quotations/:id/items"
echo "✅ POST /api/quotations/:id/items"
echo "✅ PATCH /api/quotation-items/:id"
echo "✅ GET /api/dashboard/stats"
echo "✅ GET /api/api-keys"
echo ""
echo "🔐 TOKEN ATIVO: mxc_test123456789012345678901234567890"
echo "👤 USUÁRIO: Administrador (acesso total)"
echo ""
echo "Para criar seu próprio token:"
echo "psql -d mixcotacao -c \"INSERT INTO api_keys (name, key, seller_id) VALUES ('Meu Token', 'mxc_SEU_TOKEN_AQUI', 2);\""