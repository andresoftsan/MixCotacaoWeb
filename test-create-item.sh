#!/bin/bash

# Teste de criação de item de cotação via API
# Mix Cotação Web - Teste de Item

echo "=== TESTE DE CRIAÇÃO DE ITEM DE COTAÇÃO ==="
echo ""

# Configurações
BASE_URL="http://localhost:5000"
API_TOKEN="mxc_test123456789012345678901234567890"
QUOTATION_ID=1

echo "Base URL: $BASE_URL"
echo "Token: ${API_TOKEN:0:12}..."
echo "ID da Cotação: $QUOTATION_ID"
echo ""

# Teste 1: Verificar se a cotação existe
echo "1. Verificando se a cotação existe..."
QUOTATION_CHECK=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  "$BASE_URL/api/quotations/$QUOTATION_ID")

HTTP_CODE=$(echo "$QUOTATION_CHECK" | tail -n1)
RESPONSE_BODY=$(echo "$QUOTATION_CHECK" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Cotação encontrada: ID $QUOTATION_ID"
    echo "   Número: $(echo $RESPONSE_BODY | grep -o '"number":"[^"]*' | cut -d'"' -f4)"
else
    echo "❌ Erro ao verificar cotação: HTTP $HTTP_CODE"
    echo "   Resposta: $RESPONSE_BODY"
    exit 1
fi
echo ""

# Teste 2: Criar item de cotação
echo "2. Criando item de cotação..."
ITEM_DATA='{
  "barcode": "7891234567893",
  "productName": "Produto Teste Script",
  "quotedQuantity": 25,
  "availableQuantity": 20,
  "unitPrice": "15.75",
  "validity": "2025-02-28T23:59:59.000Z",
  "situation": "Parcial"
}'

echo "   Dados do item:"
echo "   - Código de barras: 7891234567893"
echo "   - Nome: Produto Teste Script"
echo "   - Quantidade cotada: 25"
echo "   - Quantidade disponível: 20"
echo "   - Preço unitário: R$ 15,75"
echo "   - Situação: Parcial"
echo ""

CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$ITEM_DATA" \
  "$BASE_URL/api/quotations/$QUOTATION_ID/items")

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$CREATE_RESPONSE" | head -n -1)

echo "   Status HTTP: $HTTP_CODE"
echo "   Resposta completa:"
echo "   $RESPONSE_BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Item criado com sucesso!"
    ITEM_ID=$(echo $RESPONSE_BODY | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo "   ID do item criado: $ITEM_ID"
else
    echo "❌ Erro ao criar item: HTTP $HTTP_CODE"
    
    # Verificar se retornou HTML (problema relatado)
    if echo "$RESPONSE_BODY" | grep -q "<!DOCTYPE html>"; then
        echo ""
        echo "🚨 PROBLEMA IDENTIFICADO: API retornou HTML em vez de JSON!"
        echo "   Possıveis causas:"
        echo "   - URL incorreta (deve ser: $BASE_URL/api/quotations/$QUOTATION_ID/items)"
        echo "   - Servidor não está respondendo na porta 5000"
        echo "   - Middleware de roteamento com problema"
        echo ""
        echo "   Primeiro caracteres da resposta:"
        echo "   $(echo "$RESPONSE_BODY" | head -c 100)..."
    fi
fi
echo ""

# Teste 3: Listar itens da cotação para verificar
echo "3. Verificando itens da cotação..."
LIST_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  "$BASE_URL/api/quotations/$QUOTATION_ID/items")

HTTP_CODE=$(echo "$LIST_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$LIST_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    ITEM_COUNT=$(echo $RESPONSE_BODY | grep -o '"id":' | wc -l)
    echo "✅ Listagem de itens bem-sucedida"
    echo "   Total de itens na cotação: $ITEM_COUNT"
else
    echo "❌ Erro ao listar itens: HTTP $HTTP_CODE"
    echo "   Resposta: $RESPONSE_BODY"
fi
echo ""

echo "=== INSTRUÇÕES PARA TESTAR MANUALMENTE ==="
echo ""
echo "Se você está usando curl diretamente, use exatamente este formato:"
echo ""
echo "curl -X POST \\"
echo "  -H \"Authorization: Bearer $API_TOKEN\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{
    \"barcode\": \"7891234567894\",
    \"productName\": \"Seu Produto\",
    \"quotedQuantity\": 10,
    \"availableQuantity\": 8,
    \"unitPrice\": \"12.50\",
    \"validity\": \"2025-03-01T23:59:59.000Z\",
    \"situation\": \"Parcial\"
  }' \\"
echo "  \"$BASE_URL/api/quotations/$QUOTATION_ID/items\""
echo ""
echo "Campos obrigatórios:"
echo "- barcode (string)"
echo "- productName (string)"  
echo "- quotedQuantity (number)"
echo ""
echo "Campos opcionais:"
echo "- availableQuantity (number)"
echo "- unitPrice (string)"
echo "- validity (string ISO date)"
echo "- situation (\"Disponível\" | \"Indisponível\" | \"Parcial\")"
echo ""
echo "=== FIM DO TESTE ==="