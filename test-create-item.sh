#!/bin/bash

# Script para testar criação de cotação e item via API
# Mix Cotação Web - Teste completo de API

API_KEY="mixapi_prod_a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
BASE_URL="http://localhost:5000"

echo "========================================"
echo "  Teste Completo de API - Mix Cotação"
echo "========================================"

# 1. Criar cotação
echo "1. Criando nova cotação..."
COTACAO_RESPONSE=$(curl -s -X POST \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "date": "2025-06-21",
       "deadline": "2025-06-30",
       "supplierCnpj": "11.222.333/0001-44",
       "supplierName": "Fornecedor Script Teste Ltda",
       "clientCnpj": "99.888.777/0001-55",
       "clientName": "Cliente Script Teste SA",
       "internalObservation": "Cotação criada via script de teste automático"
     }' \
     "$BASE_URL/api/quotations")

echo "Resposta da criação:"
echo "$COTACAO_RESPONSE"

# Extrair ID da cotação (assumindo que retorna JSON)
COTACAO_ID=$(echo "$COTACAO_RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)

if [[ -z "$COTACAO_ID" ]]; then
    echo "❌ Falha ao criar cotação ou extrair ID"
    exit 1
fi

echo "✅ Cotação criada com ID: $COTACAO_ID"
echo

# 2. Adicionar item à cotação
echo "2. Adicionando item à cotação..."
ITEM_RESPONSE=$(curl -s -X POST \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "barcode": "7891234567890",
       "productName": "Produto Teste API 500ml",
       "quotedQuantity": 50,
       "availableQuantity": 45,
       "unitPrice": "12.90",
       "validity": "2025-07-15T23:59:59.000Z",
       "situation": "Disponível"
     }' \
     "$BASE_URL/api/quotations/$COTACAO_ID/items")

echo "Resposta da adição de item:"
echo "$ITEM_RESPONSE"
echo

# 3. Listar itens da cotação
echo "3. Listando itens da cotação..."
curl -s -H "Authorization: Bearer $API_KEY" \
     "$BASE_URL/api/quotations/$COTACAO_ID/items" | \
     jq '.' 2>/dev/null || echo "Lista de itens retornada"
echo

# 4. Atualizar cotação
echo "4. Atualizando status da cotação..."
curl -s -X PUT \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "status": "Enviada",
       "internalObservation": "Cotação enviada via teste automático da API"
     }' \
     "$BASE_URL/api/quotations/$COTACAO_ID" | \
     jq '.' 2>/dev/null || echo "Cotação atualizada"
echo

# 5. Verificar cotação final
echo "5. Verificando cotação final..."
curl -s -H "Authorization: Bearer $API_KEY" \
     "$BASE_URL/api/quotations/$COTACAO_ID" | \
     jq '.' 2>/dev/null || echo "Dados da cotação retornados"

echo
echo "========================================"
echo "Teste completo finalizado!"
echo "ID da cotação criada: $COTACAO_ID"
echo "========================================"