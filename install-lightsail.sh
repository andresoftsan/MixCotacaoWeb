#!/bin/bash

# Script de Instalação Automatizada - Mix Cotação Web
# AWS Lightsail Ubuntu 24.04
# Autor: Sistema Mix Cotação
# Data: $(date +%Y-%m-%d)

set -e

echo "======================================"
echo "  Mix Cotação Web - Deploy Lightsail"
echo "======================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log
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

# Verificar se é root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root"
fi

# Verificar distribuição
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    warn "Este script foi testado apenas no Ubuntu 24.04"
    read -p "Continuar mesmo assim? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Solicitar informações do usuário
log "Configuração inicial..."

read -p "Digite a senha para o banco de dados PostgreSQL: " -s DB_PASSWORD
echo
read -p "Digite uma chave secreta para sessões (mín. 32 caracteres): " -s SESSION_SECRET
echo
read -p "Digite seu domínio (ou deixe vazio para usar IP): " DOMAIN
echo

# Validações
if [[ ${#DB_PASSWORD} -lt 8 ]]; then
    error "Senha do banco deve ter pelo menos 8 caracteres"
fi

if [[ ${#SESSION_SECRET} -lt 32 ]]; then
    error "Chave secreta deve ter pelo menos 32 caracteres"
fi

log "Iniciando instalação..."

# 1. Atualizar sistema
log "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Instalar Node.js 20
log "Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Instalar PostgreSQL
log "Instalando PostgreSQL..."
sudo apt install postgresql postgresql-contrib -y

# 4. Instalar Nginx
log "Instalando Nginx..."
sudo apt install nginx -y

# 5. Instalar outras dependências
log "Instalando dependências adicionais..."
sudo apt install git curl unzip fail2ban -y
sudo npm install -g pm2

# 6. Configurar PostgreSQL
log "Configurando PostgreSQL..."
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
sudo sed -i '/^local.*all.*postgres.*peer/a local   all             mixuser                                 md5' /etc/postgresql/16/main/pg_hba.conf
sudo systemctl restart postgresql

# Testar conexão
log "Testando conexão com banco..."
PGPASSWORD=$DB_PASSWORD psql -U mixuser -d mixcotacao -h localhost -c "SELECT version();" > /dev/null
if [[ $? -eq 0 ]]; then
    log "Conexão com banco configurada com sucesso"
else
    error "Falha na configuração do banco de dados"
fi

# 7. Preparar diretórios
log "Preparando diretórios..."
mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/backup

# 8. Clonar/preparar aplicação (assumindo que os arquivos já estão no servidor)
cd /home/ubuntu

if [[ ! -d "mix-cotacao-web" ]]; then
    warn "Diretório mix-cotacao-web não encontrado"
    warn "Você precisa fazer upload dos arquivos da aplicação para /home/ubuntu/mix-cotacao-web"
    warn "Continue a instalação após fazer o upload dos arquivos"
    read -p "Pressione Enter quando os arquivos estiverem prontos..."
fi

cd mix-cotacao-web

# 9. Instalar dependências da aplicação
log "Instalando dependências da aplicação..."
npm install

# 10. Configurar variáveis de ambiente
log "Configurando variáveis de ambiente..."
cat > .env << EOF
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://mixuser:$DB_PASSWORD@localhost:5432/mixcotacao
SESSION_SECRET=$SESSION_SECRET

# PostgreSQL específico
PGUSER=mixuser
PGPASSWORD=$DB_PASSWORD
PGDATABASE=mixcotacao
PGHOST=localhost
PGPORT=5432
EOF

# 11. Executar migração do banco
log "Executando migração do banco..."
npm run db:push

# 12. Build da aplicação
log "Fazendo build da aplicação..."
npm run build

# 13. Configurar PM2
log "Configurando PM2..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'mix-cotacao-web',
    script: 'npm',
    args: 'start',
    cwd: '/home/ubuntu/mix-cotacao-web',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    log_file: '/home/ubuntu/logs/mix-cotacao.log',
    error_file: '/home/ubuntu/logs/mix-cotacao-error.log',
    out_file: '/home/ubuntu/logs/mix-cotacao-out.log',
    time: true
  }]
};
EOF

# 14. Configurar Nginx
log "Configurando Nginx..."
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

# 15. Configurar firewall
log "Configurando firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# 16. Configurar Fail2Ban
log "Configurando Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 17. Iniciar aplicação
log "Iniciando aplicação..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup ubuntu -u ubuntu --hp /home/ubuntu
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup ubuntu -u ubuntu --hp /home/ubuntu

# 18. Criar scripts de manutenção
log "Criando scripts de manutenção..."

# Script de backup
cat > /home/ubuntu/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backup"
DATE=$(date +%Y%m%d_%H%M%S)
PGPASSWORD=$PGPASSWORD pg_dump -U mixuser -h localhost mixcotacao > $BACKUP_DIR/backup_$DATE.sql
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete
echo "Backup criado: backup_$DATE.sql"
EOF

chmod +x /home/ubuntu/backup.sh

# Script de deploy
cat > /home/ubuntu/deploy.sh << 'EOF'
#!/bin/bash
cd /home/ubuntu/mix-cotacao-web

echo "Criando backup pré-atualização..."
/home/ubuntu/backup.sh

echo "Atualizando código..."
# git pull origin main # descomente se usar git

echo "Instalando dependências..."
npm install

echo "Executando migrações..."
npm run db:push

echo "Fazendo build..."
npm run build

echo "Reiniciando aplicação..."
pm2 restart mix-cotacao-web

echo "Deploy concluído!"
EOF

chmod +x /home/ubuntu/deploy.sh

# Script de monitoramento
cat > /home/ubuntu/healthcheck.sh << 'EOF'
#!/bin/bash
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/)
if [ $response != "200" ]; then
    pm2 restart mix-cotacao-web
    echo "$(date): Aplicação reiniciada devido a falha na verificação" >> /home/ubuntu/logs/healthcheck.log
fi
EOF

chmod +x /home/ubuntu/healthcheck.sh

# 19. Configurar cron jobs
log "Configurando tarefas automáticas..."
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/healthcheck.sh") | crontab -

# 20. Instalar Certbot (se domínio foi fornecido)
if [[ ! -z "$DOMAIN" ]]; then
    log "Instalando Certbot para SSL..."
    sudo apt install certbot python3-certbot-nginx -y
    warn "Execute manualmente: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    (crontab -l 2>/dev/null; echo "0 12 * * * certbot renew --quiet") | crontab -
fi

# 21. Verificações finais
log "Executando verificações finais..."

# Verificar serviços
sleep 5
if ! systemctl is-active --quiet nginx; then
    error "Nginx não está rodando"
fi

if ! systemctl is-active --quiet postgresql; then
    error "PostgreSQL não está rodando"
fi

if ! pm2 list | grep -q "mix-cotacao-web.*online"; then
    error "Aplicação não está rodando"
fi

# Teste de conectividade
if curl -s http://localhost:5000/ | grep -q "<!DOCTYPE html>"; then
    log "Aplicação respondendo corretamente"
else
    warn "Aplicação pode não estar respondendo corretamente"
fi

# 22. Informações finais
log "======================================"
log "  INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
log "======================================"
echo
log "Informações importantes:"
echo "• URL da aplicação: http://$SERVER_NAME"
echo "• Logs da aplicação: pm2 logs mix-cotacao-web"
echo "• Status dos serviços: pm2 status"
echo "• Backup manual: /home/ubuntu/backup.sh"
echo "• Deploy: /home/ubuntu/deploy.sh"
echo
log "Credenciais padrão do administrador:"
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
echo "• Backup: /home/ubuntu/backup.sh"
echo
log "Instalação finalizada!"