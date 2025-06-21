#!/bin/bash

# Correção de emergência para AWS - Módulos ESM
# Solução completa para o erro ERR_MODULE_NOT_FOUND

set -e

echo "=== CORREÇÃO EMERGENCIAL AWS ==="

# Parar tudo
pm2 kill

# Limpeza completa
rm -rf node_modules dist

# Reinstalar dependências
npm install

# Build otimizado
npm run build

# Verificar se build funciona
node dist/index.js &
PID=$!
sleep 2
if kill -0 $PID 2>/dev/null; then
    kill $PID
    echo "✅ Build funciona"
else
    echo "❌ Build falhou"
    exit 1
fi

# Configuração PM2 simplificada
cat > pm2.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'mix-cotacao-web',
    script: 'dist/index.js',
    env_file: '.env',
    instances: 1,
    autorestart: true,
    max_restarts: 3
  }]
};
EOF

# Iniciar
pm2 start pm2.config.js
pm2 save

echo "✅ Aplicação iniciada"
pm2 status