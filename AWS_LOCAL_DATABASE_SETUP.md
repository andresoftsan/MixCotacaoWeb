# Mix Cotação Web - Setup AWS com PostgreSQL Local

## Configuração Completa no EC2 com Banco Local

### Pré-requisitos
- Instância EC2 rodando (Amazon Linux 2 ou Ubuntu)
- Acesso SSH à instância
- Security Group permitindo HTTP (80), HTTPS (443) e SSH (22)

### Passo 1: Conectar ao Servidor EC2

```bash
# Conectar via SSH
ssh -i sua-chave.pem ec2-user@seu-ip-publico-ec2

# Se usar Ubuntu, use:
ssh -i sua-chave.pem ubuntu@seu-ip-publico-ec2
```

### Passo 2: Instalar PostgreSQL

**Para Amazon Linux 2:**
```bash
# Atualizar sistema
sudo yum update -y

# Instalar PostgreSQL
sudo yum install -y postgresql postgresql-server postgresql-contrib

# Inicializar banco
sudo postgresql-setup initdb

# Iniciar e habilitar PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Para Ubuntu:**
```bash
# Atualizar sistema
sudo apt update -y

# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# PostgreSQL já inicia automaticamente no Ubuntu
sudo systemctl status postgresql
```

### Passo 3: Configurar PostgreSQL

```bash
# Mudar para usuário postgres
sudo -u postgres psql

# Dentro do PostgreSQL, executar:
CREATE DATABASE mixcotacao;
CREATE USER mixadmin WITH ENCRYPTED PASSWORD 'MixGestao2025!Database';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixadmin;
ALTER USER mixadmin CREATEDB;
\q
```

**Configurar autenticação:**
```bash
# Editar arquivo de configuração
sudo nano /var/lib/pgsql/data/pg_hba.conf
# OU para Ubuntu:
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Alterar a linha:
# local   all             all                                     peer
# PARA:
local   all             all                                     md5

# E adicionar:
host    mixcotacao      mixadmin        127.0.0.1/32            md5
```

**Reiniciar PostgreSQL:**
```bash
sudo systemctl restart postgresql
```

**Testar conexão:**
```bash
psql -h localhost -U mixadmin -d mixcotacao
# Senha: MixGestao2025!Database
```

### Passo 4: Instalar Node.js

```bash
# Instalar Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# OU para Ubuntu:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalação
node --version
npm --version

# Instalar PM2 globalmente
sudo npm install -g pm2
```

### Passo 5: Preparar Aplicação

```bash
# Criar usuário para aplicação
sudo useradd -m -s /bin/bash mixapp

# Criar diretório da aplicação
sudo mkdir -p /opt/mixcotacao
sudo chown mixapp:mixapp /opt/mixcotacao

# Mudar para usuário da aplicação
sudo su - mixapp
```

### Passo 6: Fazer Upload do Código

**Opção A: Via SCP (do seu computador local):**
```bash
# No seu computador local, comprimir o projeto
tar -czf mixcotacao.tar.gz client/ server/ shared/ package*.json *.ts *.js *.md

# Enviar para o servidor
scp -i sua-chave.pem mixcotacao.tar.gz ec2-user@seu-ip:/tmp/

# No servidor EC2
sudo mv /tmp/mixcotacao.tar.gz /opt/mixcotacao/
sudo chown mixapp:mixapp /opt/mixcotacao/mixcotacao.tar.gz
sudo su - mixapp
cd /opt/mixcotacao
tar -xzf mixcotacao.tar.gz
rm mixcotacao.tar.gz
```

**Opção B: Via Git:**
```bash
# Como usuário mixapp
cd /opt/mixcotacao
git clone https://github.com/seu-usuario/mix-cotacao-web.git .
```

### Passo 7: Configurar Variáveis de Ambiente

```bash
# Como usuário mixapp, no diretório /opt/mixcotacao
cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://mixadmin:MixGestao2025!Database@localhost:5432/mixcotacao
SESSION_SECRET=mix-cotacao-production-$(openssl rand -hex 32)
EOF
```

### Passo 8: Instalar Dependências

```bash
# Como usuário mixapp
cd /opt/mixcotacao
npm install
```

### Passo 9: Configurar Banco de Dados

```bash
# Executar script de setup
psql -h localhost -U mixadmin -d mixcotacao -f database_setup.sql

# Verificar se deu certo
psql -h localhost -U mixadmin -d mixcotacao -c "SELECT COUNT(*) FROM sellers;"
```

### Passo 10: Iniciar Aplicação

```bash
# Como usuário mixapp
cd /opt/mixcotacao

# Testar aplicação primeiro
npm start

# Se funcionar, parar com Ctrl+C e iniciar com PM2
pm2 start npm --name "mix-cotacao" -- start
pm2 startup
pm2 save

# Sair do usuário mixapp
exit
```

### Passo 11: Configurar Nginx

```bash
# Voltar como ec2-user/ubuntu
# Instalar nginx
sudo yum install -y nginx
# OU para Ubuntu:
sudo apt install -y nginx

# Criar configuração
sudo cat > /etc/nginx/conf.d/mixcotacao.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 10M;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
        proxy_connect_timeout 30;
        proxy_send_timeout 30;
    }
    
    location /api/health {
        proxy_pass http://127.0.0.1:3000/api/health;
        access_log off;
    }
}
EOF

# Remover configuração padrão
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

# Testar configuração
sudo nginx -t

# Iniciar nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Passo 12: Configurar Firewall (se necessário)

```bash
# Amazon Linux com firewalld
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# Ubuntu com ufw
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable
```

### Passo 13: Testar Sistema

```bash
# Testar health check
curl http://localhost/api/health

# Testar login
curl -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"administrador@softsan.com.br","password":"M1xgestao@2025"}'

# Acessar pelo navegador
echo "Acesse: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
```

### Passo 14: Configurar Auto-start

```bash
# Script de inicialização
sudo cat > /etc/systemd/system/mixcotacao.service << 'EOF'
[Unit]
Description=Mix Cotacao Web Application
After=network.target postgresql.service

[Service]
Type=simple
User=mixapp
WorkingDirectory=/opt/mixcotacao
Environment=NODE_ENV=production
ExecStart=/usr/bin/pm2 start npm --name "mix-cotacao" -- start
ExecReload=/usr/bin/pm2 reload mix-cotacao
ExecStop=/usr/bin/pm2 stop mix-cotacao
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mixcotacao
```

### Passo 15: Configurar Logs

```bash
# Configurar logrotate
sudo cat > /etc/logrotate.d/mixcotacao << 'EOF'
/home/mixapp/.pm2/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 644 mixapp mixapp
    postrotate
        sudo -u mixapp pm2 reloadLogs
    endscript
}

/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 nginx nginx
    postrotate
        systemctl reload nginx
    endscript
}
EOF
```

### Passo 16: Script de Backup

```bash
# Criar script de backup
sudo cat > /opt/mixcotacao/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/mixcotacao/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup do banco
pg_dump -h localhost -U mixadmin -d mixcotacao > $BACKUP_DIR/db_backup_$DATE.sql

# Manter apenas 7 backups
find $BACKUP_DIR -name "db_backup_*.sql" -type f -mtime +7 -delete

echo "Backup criado: $BACKUP_DIR/db_backup_$DATE.sql"
EOF

chmod +x /opt/mixcotacao/backup.sh
sudo chown mixapp:mixapp /opt/mixcotacao/backup.sh

# Configurar cron para backup diário
sudo -u mixapp crontab -e
# Adicionar linha:
# 2 0 * * * /opt/mixcotacao/backup.sh
```

### Comandos Úteis para Manutenção

**Status dos serviços:**
```bash
sudo systemctl status postgresql
sudo systemctl status nginx
sudo -u mixapp pm2 status
```

**Logs:**
```bash
# Logs da aplicação
sudo -u mixapp pm2 logs mix-cotacao

# Logs nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

**Reiniciar serviços:**
```bash
sudo systemctl restart postgresql
sudo systemctl restart nginx
sudo -u mixapp pm2 restart mix-cotacao
```

**Monitoramento:**
```bash
# Espaço em disco
df -h

# Memória
free -m

# CPU
top

# Conexões banco
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
```

### Resolução de Problemas

**Se PostgreSQL não iniciar:**
```bash
sudo journalctl -u postgresql -f
sudo -u postgres /usr/bin/postgres -D /var/lib/pgsql/data
```

**Se aplicação não conectar no banco:**
```bash
# Testar conexão
psql -h localhost -U mixadmin -d mixcotacao -c "SELECT 1;"

# Verificar se PostgreSQL está ouvindo
sudo netstat -tlnp | grep 5432
```

**Se nginx retornar 502:**
```bash
# Verificar se aplicação está rodando
curl http://localhost:3000/api/health

# Logs nginx
sudo tail -f /var/log/nginx/error.log
```

### URLs de Acesso

Após a configuração completa:

- **Aplicação:** `http://SEU-IP-PUBLICO-EC2`
- **Health Check:** `http://SEU-IP-PUBLICO-EC2/api/health`
- **Login:** administrador@softsan.com.br / M1xgestao@2025

### Sistema Configurado com Sucesso!

O sistema estará rodando com:
- PostgreSQL local na porta 5432
- Aplicação Node.js na porta 3000 (via PM2)
- Nginx como proxy reverso na porta 80
- Backup automático diário
- Logs configurados e rotacionados
- Auto-start em caso de reinicialização