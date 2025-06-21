#!/bin/bash

# Script de Instalação Completa AWS EC2
# Mix Cotação Web - Com todas as correções implementadas

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

header() {
    echo -e "${BLUE}========================================"
    echo -e "  $1"
    echo -e "========================================${NC}"
}

# Verificar se é Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    error "Este script é para Ubuntu. Sistema detectado: $(lsb_release -d | cut -f2)"
fi

header "Mix Cotação Web - Instalação AWS EC2"

# Solicitar informações do usuário
log "Configuração inicial..."
read -p "Digite a senha para PostgreSQL: " -s DB_PASSWORD
echo
read -p "Digite uma chave secreta para sessões (64+ caracteres): " -s SESSION_SECRET
echo
read -p "Digite seu domínio (ou deixe vazio para usar IP): " DOMAIN
echo

# Validações
if [[ ${#DB_PASSWORD} -lt 8 ]]; then
    error "Senha do PostgreSQL deve ter pelo menos 8 caracteres"
fi

if [[ ${#SESSION_SECRET} -lt 32 ]]; then
    error "Chave secreta deve ter pelo menos 32 caracteres"
fi

# 1. Atualizar sistema
header "1. Atualizando Sistema"
sudo apt update && sudo apt upgrade -y

# 2. Instalar Node.js 20
header "2. Instalando Node.js 20"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Instalar PostgreSQL
header "3. Instalando PostgreSQL"
sudo apt install postgresql postgresql-contrib -y

# 4. Instalar outras dependências
header "4. Instalando Dependências"
sudo apt install nginx git curl unzip htop -y
sudo npm install -g pm2

# 5. Configurar PostgreSQL
header "5. Configurando PostgreSQL"
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Criar banco e usuário
sudo -u postgres psql << EOF
CREATE DATABASE mixcotacao;
CREATE USER mixuser WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixuser;
ALTER USER mixuser CREATEDB;
\q
EOF

# Configurar acesso local
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1 | cut -d. -f1)
sudo sed -i "/^local.*all.*postgres.*peer/a local   all             mixuser                                 md5" /etc/postgresql/$PG_VERSION/main/pg_hba.conf
sudo systemctl restart postgresql

# Testar conexão
log "Testando conexão com PostgreSQL..."
PGPASSWORD=$DB_PASSWORD psql -U mixuser -d mixcotacao -h localhost -c "SELECT version();" > /dev/null
if [[ $? -eq 0 ]]; then
    log "✅ PostgreSQL configurado com sucesso"
else
    error "❌ Falha na configuração do PostgreSQL"
fi

# 6. Preparar aplicação
header "6. Preparando Aplicação"
cd /home/ubuntu

if [[ ! -d "mix-cotacao-web" ]]; then
    warn "Diretório mix-cotacao-web não encontrado"
    warn "Faça upload dos arquivos da aplicação para /home/ubuntu/mix-cotacao-web"
    read -p "Pressione Enter quando os arquivos estiverem prontos..."
fi

cd mix-cotacao-web

# 7. Instalar dependências da aplicação
header "7. Instalando Dependências da Aplicação"
npm install

# Garantir que dependências corretas estão instaladas
npm install pg @types/pg dotenv

# 8. Configurar variáveis de ambiente
header "8. Configurando Variáveis de Ambiente"
cat > .env << EOF
NODE_ENV=production
PORT=5000

# PostgreSQL Local
DATABASE_URL=postgresql://mixuser:$DB_PASSWORD@localhost:5432/mixcotacao

# Variáveis PostgreSQL específicas
PGUSER=mixuser
PGPASSWORD=$DB_PASSWORD
PGDATABASE=mixcotacao
PGHOST=localhost
PGPORT=5432

# Chave de sessão
SESSION_SECRET=$SESSION_SECRET
EOF

# 9. Configurar banco de dados
header "9. Configurando Banco de Dados"
if [[ -f "mix_cotacao_schema.sql" ]]; then
    log "Executando schema completo..."
    PGPASSWORD=$DB_PASSWORD psql -U mixuser -d mixcotacao -h localhost -f mix_cotacao_schema.sql
else
    log "Executando migração via Drizzle..."
    npm run db:push
fi

# 10. Build da aplicação
header "10. Fazendo Build da Aplicação"
npm run build

# Verificar se build foi criado
if [[ ! -f "dist/index.js" ]]; then
    error "❌ Build falhou - dist/index.js não foi criado"
fi

# 11. Configurar PM2
header "11. Configurando PM2"
mkdir -p logs

cat > ecosystem.production.js << 'EOF'
module.exports = {
  apps: [{
    name: 'mix-cotacao-web',
    script: './dist/index.js',
    cwd: '/home/ubuntu/mix-cotacao-web',
    env_file: '.env',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '2G',
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    time: true,
    max_restarts: 5,
    min_uptime: '10s'
  }]
};
EOF

# 12. Configurar Nginx
header "12. Configurando Nginx"
if [[ -z "$DOMAIN" ]]; then
    # Usar IP público
    PUBLIC_IP=$(curl -s ifconfig.me)
    SERVER_NAME=$PUBLIC_IP
else
    SERVER_NAME="$DOMAIN www.$DOMAIN"
fi

sudo tee /etc/nginx/sites-available/mix-cotacao-web > /dev/null << EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Ativar site
sudo ln -sf /etc/nginx/sites-available/mix-cotacao-web /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# 13. Configurar firewall
header "13. Configurando Firewall"
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# 14. Iniciar aplicação
header "14. Iniciando Aplicação"
pm2 start ecosystem.production.js
pm2 save
pm2 startup ubuntu -u ubuntu --hp /home/ubuntu
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup ubuntu -u ubuntu --hp /home/ubuntu

# 15. Criar scripts de manutenção
header "15. Criando Scripts de Manutenção"

# Script de backup
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
source .env
PGPASSWORD=$PGPASSWORD pg_dump -U mixuser -h localhost mixcotacao > $BACKUP_DIR/backup_$DATE.sql
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete
echo "Backup criado: backup_$DATE.sql"
EOF

# Script de deploy
cat > deploy.sh << 'EOF'
#!/bin/bash
cd /home/ubuntu/mix-cotacao-web
echo "Criando backup..."
./backup.sh
echo "Instalando dependências..."
npm install
echo "Executando migrações..."
npm run db:push
echo "Fazendo build..."
npm run build
echo "Reiniciando aplicação..."
pm2 restart mix-cotacao-web
echo "Deploy concluído!"
pm2 status
EOF

chmod +x backup.sh deploy.sh

# 16. Configurar tarefas automáticas
header "16. Configurando Tarefas Automáticas"
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/mix-cotacao-web/backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://localhost:5000/api/health || pm2 restart mix-cotacao-web") | crontab -

# 17. Verificações finais
header "17. Executando Verificações Finais"

# Aguardar inicialização
sleep 5

# Verificar serviços
if ! systemctl is-active --quiet postgresql; then
    error "❌ PostgreSQL não está rodando"
fi

if ! systemctl is-active --quiet nginx; then
    error "❌ Nginx não está rodando"
fi

if ! pm2 list | grep -q "mix-cotacao-web.*online"; then
    error "❌ Aplicação não está rodando"
fi

# Teste de conectividade
if curl -s http://localhost:5000/api/health | grep -q "healthy\|version"; then
    log "✅ Aplicação respondendo corretamente"
else
    warn "⚠️  Aplicação pode não estar respondendo corretamente"
fi

# 18. Informações finais
header "INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo
log "Informações importantes:"
echo "• URL da aplicação: http://$SERVER_NAME"
echo "• Logs da aplicação: pm2 logs mix-cotacao-web"
echo "• Status dos serviços: pm2 status"
echo "• Backup manual: ./backup.sh"
echo "• Deploy: ./deploy.sh"
echo
log "Credenciais de acesso:"
echo "• Email: administrador@softsan.com.br"
echo "• Senha: M1xgestao@2025"
echo
if [[ ! -z "$DOMAIN" ]]; then
    warn "Para SSL, execute: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi
echo
log "Comandos úteis:"
echo "• Ver logs: pm2 logs mix-cotacao-web"
echo "• Reiniciar app: pm2 restart mix-cotacao-web"
echo "• Status completo: pm2 monit"
echo "• Monitoramento: htop"
echo
log "Instalação finalizada com todas as correções aplicadas!"