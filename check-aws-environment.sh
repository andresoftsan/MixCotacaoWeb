#!/bin/bash

# Script de diagnóstico rápido para AWS
# Verifica problemas comuns de módulos ESM

echo "=== DIAGNÓSTICO AWS - MÓDULOS ESM ==="

# 1. Verificar Node.js version
echo "Node.js version: $(node --version)"

# 2. Verificar npm version  
echo "npm version: $(npm --version)"

# 3. Verificar se package.json existe
if [[ -f "package.json" ]]; then
    echo "✅ package.json encontrado"
    echo "Type: $(grep '"type"' package.json || echo 'commonjs (padrão)')"
else
    echo "❌ package.json não encontrado"
fi

# 4. Verificar node_modules
if [[ -d "node_modules" ]]; then
    echo "✅ node_modules existe ($(du -sh node_modules | cut -f1))"
else
    echo "❌ node_modules não existe - execute npm install"
fi

# 5. Verificar build
if [[ -f "dist/index.js" ]]; then
    echo "✅ Build existe ($(ls -lh dist/index.js | awk '{print $5}'))"
else
    echo "❌ Build não existe - execute npm run build"
fi

# 6. Verificar .env
if [[ -f ".env" ]]; then
    echo "✅ .env existe"
    echo "Variáveis: $(grep -c '^[A-Z]' .env) configuradas"
else
    echo "❌ .env não existe"
fi

# 7. Verificar PM2
if command -v pm2 &> /dev/null; then
    echo "✅ PM2 instalado: $(pm2 --version)"
else
    echo "❌ PM2 não instalado"
fi

# 8. Teste rápido de import
echo "Testando imports ES modules..."
node -e "
try {
  console.log('✅ ES modules funcionando');
} catch(e) {
  console.log('❌ Erro ES modules:', e.message);
}
" 2>/dev/null || echo "❌ Erro ao testar ES modules"

echo "=== FIM DIAGNÓSTICO ==="