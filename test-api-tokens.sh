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

# Test seller search by email
echo ""
echo "=== TESTANDO BUSCA DE VENDEDORES POR EMAIL ==="
echo "GET /api/sellers?email=administrador@softsan.com.br"
curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:5000/api/sellers?email=administrador@softsan.com.br" | jq .

echo ""
echo "--- Testando email não existente ---"
echo "GET /api/sellers?email=nonexistent@email.com"
curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:5000/api/sellers?email=nonexistent@email.com" | jq .

# Test quotation search by client CNPJ and number
echo ""
echo "=== TESTANDO BUSCA DE COTAÇÕES POR CNPJ E NÚMERO ==="
echo "GET /api/quotations?clientCnpj=98.765.432/0001-10&number=COT-2024-001"
curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:5000/api/quotations?clientCnpj=98.765.432/0001-10&number=COT-2024-001" | jq .

echo ""
echo "--- Testando cotação não existente ---"
echo "GET /api/quotations?clientCnpj=nonexistent&number=invalid"
curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:5000/api/quotations?clientCnpj=nonexistent&number=invalid" | jq .

# Test seller search by name
echo ""
echo "=== TESTANDO BUSCA DE VENDEDORES POR NOME ==="
echo "GET /api/sellers?name=Adm"
curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:5000/api/sellers?name=Adm" | jq .

echo ""
echo "--- Testando nome não existente ---"
echo "GET /api/sellers?name=inexistente"
curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:5000/api/sellers?name=inexistente" | jq .

# Test password change functionality
echo ""
echo "=== TESTANDO ALTERAÇÃO DE SENHA ==="
echo "PATCH /api/change-password"
echo "Testando alteração de senha com dados válidos..."
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"currentPassword": "NovaSenh@123", "newPassword": "M1xgestao@2025"}' \
  http://localhost:5000/api/change-password | jq .

echo ""
echo "--- Testando senha atual incorreta ---"
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"currentPassword": "senhaerrada", "newPassword": "NovaSenha123"}' \
  http://localhost:5000/api/change-password | jq .

echo ""
echo "========================================="
echo "TESTE CONCLUÍDO"
echo "========================================="
echo ""
echo "📋 RESUMO DOS ENDPOINTS IMPLEMENTADOS:"
echo "✅ GET /api/sellers (admin)"
echo "✅ GET /api/sellers?email=<email> (busca por email)"
echo "✅ GET /api/sellers?name=<nome> (busca por nome)"
echo "✅ POST /api/sellers (admin)" 
echo "✅ PUT /api/sellers/:id (admin)"
echo "✅ DELETE /api/sellers/:id (admin)"
echo "✅ GET /api/quotations"
echo "✅ GET /api/quotations?clientCnpj=<cnpj>&number=<numero> (busca específica)"
echo "✅ GET /api/quotations/:id"
echo "✅ POST /api/quotations"
echo "✅ PUT /api/quotations/:id"
echo "✅ GET /api/quotations/:id/items"
echo "✅ POST /api/quotations/:id/items"
echo "✅ PATCH /api/quotation-items/:id"
echo "✅ GET /api/dashboard/stats"
echo "✅ GET /api/api-keys"
echo "✅ PATCH /api/change-password (alteração de senha)"
echo ""
echo "🔐 TOKEN ATIVO: mxc_test123456789012345678901234567890"
echo "👤 USUÁRIO: Administrador (acesso total)"
echo ""
echo "Para criar seu próprio token:"
echo "psql -d mixcotacao -c \"INSERT INTO api_keys (name, key, seller_id) VALUES ('Meu Token', 'mxc_SEU_TOKEN_AQUI', 2);\""