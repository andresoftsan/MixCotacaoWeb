# Instalação Completa AWS EC2 - Mix Cotação Web

## Visão Geral
Guia completo para instalação do zero em uma instância AWS EC2 Ubuntu 22.04/24.04 com PostgreSQL local e todas as correções implementadas.

## 1. Configuração da Instância EC2

### 1.1 Criar Instância
- **AMI:** Ubuntu Server 22.04 LTS ou 24.04 LTS
- **Tipo:** t3.medium (2 vCPU, 4GB RAM) ou superior
- **Storage:** 20GB GP3 SSD mínimo
- **Security Group:**
  - SSH (22) - Seu IP
  - HTTP (80) - 0.0.0.0/0
  - HTTPS (443) - 0.0.0.0/0
  - Custom TCP (5000) - 0.0.0.0/0 (temporário para testes)

### 1.2 Configurar Elastic IP (Opcional)
- Associe um IP estático à instância

## 2. Configuração Inicial do Servidor

### 2.1 Conectar e Atualizar
```bash
# Conectar via SSH
ssh -i sua-chave.pem ubuntu@ip-da-instancia

# Atualizar sistema
sudo apt update && sudo apt upgrade -y
```

### 2.2 Instalar Dependências Base
```bash
# Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# PostgreSQL 15/16
sudo apt install postgresql postgresql-contrib -y

# Nginx
sudo apt install nginx -y

# Utilitários
sudo apt install git curl unzip htop -y

# PM2 globalmente
sudo npm install -g pm2

# Verificar versões
node --version
npm --version
psql --version
```

## 3. Configuração PostgreSQL Local

### 3.1 Configurar PostgreSQL
```bash
# Iniciar e habilitar serviço
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configurar usuário postgres
sudo -u postgres psql
```

### 3.2 Criar Banco e Usuário
```sql
-- No prompt PostgreSQL
CREATE DATABASE mixcotacao;
CREATE USER mixuser WITH ENCRYPTED PASSWORD 'senha_forte_aqui';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixuser;
ALTER USER mixuser CREATEDB;
\q
```

### 3.3 Configurar Acesso Local
```bash
# Editar pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf
# Para PostgreSQL 16: /etc/postgresql/16/main/pg_hba.conf

# Adicionar ANTES das outras regras:
# local   all             mixuser                                 md5

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### 3.4 Testar Conexão
```bash
psql -U mixuser -d mixcotacao -h localhost
# Digite a senha e teste: \q para sair
```

## 4. Deploy da Aplicação

### 4.1 Upload dos Arquivos
```bash
# Opção 1: Git clone
cd /home/ubuntu
git clone https://github.com/seu-usuario/mix-cotacao-web.git
cd mix-cotacao-web

# Opção 2: Upload via SCP/SFTP
# scp -i chave.pem -r ./mix-cotacao-web ubuntu@ip:/home/ubuntu/
```

### 4.2 Instalar Dependências Corretas
```bash
# Instalar dependências (já com driver pg correto)
npm install

# Verificar se pg está instalado
npm list pg

# Se não estiver, instalar:
# npm install pg @types/pg dotenv
```

### 4.3 Configurar Variáveis de Ambiente
```bash
# Criar arquivo .env
nano .env
```

Conteúdo do `.env`:
```env
NODE_ENV=production
PORT=5000

# PostgreSQL Local
DATABASE_URL=postgresql://mixuser:senha_forte_aqui@localhost:5432/mixcotacao

# Variáveis PostgreSQL específicas
PGUSER=mixuser
PGPASSWORD=senha_forte_aqui
PGDATABASE=mixcotacao
PGHOST=localhost
PGPORT=5432

# Chave de sessão (gere uma chave de 64+ caracteres)
SESSION_SECRET=chave_muito_longa_e_segura_com_pelo_menos_64_caracteres_aqui_123456789
```

### 4.4 Configurar Banco de Dados
```bash
# Executar migração do schema
npm run db:push

# Ou executar script SQL completo
psql -U mixuser -d mixcotacao -h localhost -f mix_cotacao_schema.sql
```

### 4.5 Build da Aplicação
```bash
# Build com driver pg correto
npm run build

# Verificar se build foi criado
ls -la dist/
```

### 4.6 Testar Aplicação Local
```bash
# Teste rápido
node dist/index.js &
sleep 3
curl http://localhost:5000/api/health
# Parar: kill %1
```

## 5. Configuração PM2 para Produção

### 5.1 Criar Configuração PM2
```bash
nano ecosystem.production.js
```

Conteúdo:
```javascript
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
```

### 5.2 Criar Diretórios e Iniciar
```bash
# Criar diretório de logs
mkdir -p logs

# Iniciar aplicação
pm2 start ecosystem.production.js

# Configurar para iniciar com sistema
pm2 save
pm2 startup ubuntu -u ubuntu --hp /home/ubuntu
# Execute o comando que PM2 mostrar

# Verificar status
pm2 status
pm2 logs mix-cotacao-web
```

## 6. Configurar Nginx

### 6.1 Criar Configuração do Site
```bash
sudo nano /etc/nginx/sites-available/mix-cotacao-web
```

Conteúdo:
```nginx
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;
    # Para IP: server_name 18.xxx.xxx.xxx;

    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 6.2 Ativar Site
```bash
# Habilitar site
sudo ln -s /etc/nginx/sites-available/mix-cotacao-web /etc/nginx/sites-enabled/

# Remover site padrão
sudo rm /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## 7. Configurar Firewall

```bash
# Configurar UFW
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Verificar status
sudo ufw status
```

## 8. SSL com Let's Encrypt (Opcional)

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obter certificado (substitua o domínio)
sudo certbot --nginx -d seu-dominio.com -d www.seu-dominio.com

# Configurar renovação automática
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 9. Scripts de Manutenção

### 9.1 Script de Backup
```bash
nano backup.sh
```

Conteúdo:
```bash
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup do banco
PGPASSWORD=$PGPASSWORD pg_dump -U mixuser -h localhost mixcotacao > $BACKUP_DIR/backup_$DATE.sql

# Limpar backups antigos (>7 dias)
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete

echo "Backup criado: backup_$DATE.sql"
```

```bash
chmod +x backup.sh
```

### 9.2 Script de Deploy/Atualização
```bash
nano deploy.sh
```

Conteúdo:
```bash
#!/bin/bash
cd /home/ubuntu/mix-cotacao-web

echo "Criando backup..."
./backup.sh

echo "Atualizando código..."
# git pull origin main # Se usar git

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
```

```bash
chmod +x deploy.sh
```

### 9.3 Configurar Tarefas Automáticas
```bash
crontab -e
```

Adicionar:
```bash
# Backup diário às 2h
0 2 * * * /home/ubuntu/mix-cotacao-web/backup.sh

# Health check a cada 5 minutos
*/5 * * * * curl -s http://localhost:5000/api/health || pm2 restart mix-cotacao-web
```

## 10. Verificação Final

### 10.1 Testar Funcionalidades
```bash
# Verificar serviços
sudo systemctl status postgresql
sudo systemctl status nginx
pm2 status

# Testar aplicação
curl http://localhost:5000/api/health
curl http://seu-ip-ou-dominio/

# Verificar logs
pm2 logs mix-cotacao-web --lines 20
sudo tail -f /var/log/nginx/access.log
```

### 10.2 Login na Aplicação
- **URL:** http://seu-ip-ou-dominio
- **Email:** administrador@softsan.com.br
- **Senha:** M1xgestao@2025

## 11. Monitoramento

### 11.1 Comandos Úteis
```bash
# Status geral
pm2 monit

# Logs em tempo real
pm2 logs mix-cotacao-web -f

# Uso de recursos
htop
df -h
free -h

# Verificar conexões
sudo netstat -tlnp | grep :5000
sudo netstat -tlnp | grep :80
```

### 11.2 Troubleshooting
```bash
# Se aplicação não inicia
pm2 restart mix-cotacao-web
pm2 logs mix-cotacao-web --lines 50

# Se banco não conecta
sudo systemctl restart postgresql
psql -U mixuser -d mixcotacao -h localhost

# Se Nginx não responde
sudo nginx -t
sudo systemctl restart nginx
```

## 12. Segurança Adicional

### 12.1 Configurações de Segurança
```bash
# Fail2ban para SSH
sudo apt install fail2ban -y

# Configurar SSH (opcional)
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
# PermitRootLogin no
```

### 12.2 Backup Automático para S3 (Opcional)
```bash
# Instalar AWS CLI
sudo apt install awscli -y

# Configurar e adicionar ao script de backup
aws s3 cp $BACKUP_DIR/backup_$DATE.sql s3://seu-bucket/backups/
```

## Custos Estimados AWS

- **EC2 t3.medium:** ~$30-40/mês
- **EBS 20GB:** ~$2/mês
- **Elastic IP:** Grátis se associado
- **Transferência:** Primeiros 100GB grátis
- **Total:** ~$35-45/mês

## Recursos Criados

### Arquivos de Sistema
- `/home/ubuntu/mix-cotacao-web/` - Aplicação
- `/etc/nginx/sites-available/mix-cotacao-web` - Configuração Nginx
- `/home/ubuntu/backups/` - Backups do banco

### Serviços Configurados
- PostgreSQL na porta 5432
- Aplicação na porta 5000
- Nginx nas portas 80/443
- PM2 gerenciando a aplicação

Esta instalação está otimizada com todas as correções implementadas e usa o driver PostgreSQL correto para conexões locais.