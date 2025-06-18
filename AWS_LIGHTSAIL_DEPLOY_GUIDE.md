# Guia de Deploy - AWS Lightsail Ubuntu 24.04

## Visão Geral
Este guia mostra como fazer deploy da aplicação Mix Cotação Web em uma instância AWS Lightsail com Ubuntu 24.04, PostgreSQL local e Nginx como proxy reverso.

## 1. Configuração da Instância AWS Lightsail

### 1.1 Criar Instância
- Escolha "Ubuntu 24.04 LTS"
- Plano recomendado: $10/mês (2GB RAM, 1 vCPU, 60GB SSD)
- Configure chave SSH ou use console do navegador

### 1.2 Configurar Firewall
No painel Lightsail, vá em "Networking":
- Adicione regra: HTTP (80)
- Adicione regra: HTTPS (443)
- Adicione regra: Custom (5000) - temporário para testes

## 2. Configuração Inicial do Servidor

### 2.1 Conectar ao Servidor
```bash
# Via SSH (substitua o IP)
ssh ubuntu@seu-ip-lightsail

# Ou use o console web do Lightsail
```

### 2.2 Atualizar Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### 2.3 Instalar Dependências Base
```bash
# Instalar Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Instalar Nginx
sudo apt install nginx -y

# Instalar PM2 globalmente
sudo npm install -g pm2

# Instalar utilitários
sudo apt install git curl unzip -y
```

## 3. Configuração do PostgreSQL

### 3.1 Configurar PostgreSQL
```bash
# Iniciar serviço
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Configurar usuário postgres
sudo -u postgres psql
```

### 3.2 Criar Banco e Usuário
```sql
-- No prompt do PostgreSQL
CREATE DATABASE mixcotacao;
CREATE USER mixuser WITH ENCRYPTED PASSWORD 'sua_senha_segura_aqui';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixuser;
ALTER USER mixuser CREATEDB;
\q
```

### 3.3 Configurar Acesso Local
```bash
# Editar configuração do PostgreSQL
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Adicionar esta linha antes das outras regras:
# local   all             mixuser                                 md5

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### 3.4 Testar Conexão
```bash
psql -U mixuser -d mixcotacao -h localhost
# Digite a senha quando solicitado
# Se conectar com sucesso, digite \q para sair
```

## 4. Deploy da Aplicação

### 4.1 Clonar Repositório
```bash
cd /home/ubuntu
git clone https://github.com/seu-usuario/mix-cotacao-web.git
cd mix-cotacao-web

# Ou fazer upload dos arquivos via SCP/SFTP
```

### 4.2 Instalar Dependências
```bash
npm install
```

### 4.3 Configurar Variáveis de Ambiente
```bash
nano .env
```

Conteúdo do arquivo `.env`:
```env
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://mixuser:sua_senha_segura_aqui@localhost:5432/mixcotacao
SESSION_SECRET=sua_chave_secreta_muito_longa_e_segura_aqui_123456789

# PostgreSQL específico
PGUSER=mixuser
PGPASSWORD=sua_senha_segura_aqui
PGDATABASE=mixcotacao
PGHOST=localhost
PGPORT=5432
```

### 4.4 Executar Migração do Banco
```bash
# Push schema para o banco
npm run db:push
```

### 4.5 Build da Aplicação
```bash
npm run build
```

### 4.6 Testar Aplicação
```bash
# Teste local
npm start

# Em outro terminal, teste se está funcionando
curl http://localhost:5000

# Se funcionou, pare com Ctrl+C
```

## 5. Configurar PM2 para Produção

### 5.1 Criar Arquivo de Configuração PM2
```bash
nano ecosystem.config.js
```

Conteúdo:
```javascript
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
```

### 5.2 Criar Diretório de Logs
```bash
mkdir -p /home/ubuntu/logs
```

### 5.3 Iniciar Aplicação com PM2
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
# Execute o comando que PM2 mostrar na tela
```

### 5.4 Verificar Status
```bash
pm2 status
pm2 logs mix-cotacao-web
```

## 6. Configurar Nginx como Proxy Reverso

### 6.1 Criar Configuração do Site
```bash
sudo nano /etc/nginx/sites-available/mix-cotacao-web
```

Conteúdo:
```nginx
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;
    # Para teste inicial, use o IP: server_name 18.xxx.xxx.xxx;

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
# Criar link simbólico
sudo ln -s /etc/nginx/sites-available/mix-cotacao-web /etc/nginx/sites-enabled/

# Remover site padrão
sudo rm /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## 7. Configurar SSL com Certbot (Opcional mas Recomendado)

### 7.1 Instalar Certbot
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 7.2 Obter Certificado SSL
```bash
# Substitua pelo seu domínio
sudo certbot --nginx -d seu-dominio.com -d www.seu-dominio.com
```

### 7.3 Configurar Renovação Automática
```bash
# Testar renovação
sudo certbot renew --dry-run

# Adicionar ao crontab
sudo crontab -e
# Adicione esta linha:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## 8. Configurar Firewall

### 8.1 Configurar UFW
```bash
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

## 9. Comandos de Manutenção

### 9.1 Verificar Status dos Serviços
```bash
# Verificar aplicação
pm2 status
pm2 logs mix-cotacao-web --lines 50

# Verificar Nginx
sudo systemctl status nginx
sudo nginx -t

# Verificar PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"
```

### 9.2 Reiniciar Serviços
```bash
# Reiniciar aplicação
pm2 restart mix-cotacao-web

# Reiniciar Nginx
sudo systemctl restart nginx

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### 9.3 Ver Logs
```bash
# Logs da aplicação
pm2 logs mix-cotacao-web

# Logs do Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs do PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

### 9.4 Backup do Banco
```bash
# Criar backup
pg_dump -U mixuser -h localhost mixcotacao > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar backup
psql -U mixuser -h localhost mixcotacao < backup_20250617_123456.sql
```

## 10. Atualizações da Aplicação

### 10.1 Script de Deploy
Crie um arquivo `deploy.sh`:
```bash
#!/bin/bash
cd /home/ubuntu/mix-cotacao-web

# Fazer backup do banco
pg_dump -U mixuser -h localhost mixcotacao > backup_pre_update_$(date +%Y%m%d_%H%M%S).sql

# Atualizar código
git pull origin main

# Instalar dependências
npm install

# Executar migrações se necessário
npm run db:push

# Build da aplicação
npm run build

# Reiniciar aplicação
pm2 restart mix-cotacao-web

echo "Deploy concluído!"
```

```bash
chmod +x deploy.sh
```

## 11. Monitoramento

### 11.1 Configurar Monitoramento PM2
```bash
# Instalar PM2 web dashboard (opcional)
pm2 install pm2-server-monit
```

### 11.2 Verificações de Saúde
```bash
# Criar script de verificação
nano healthcheck.sh
```

Conteúdo:
```bash
#!/bin/bash
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/health)
if [ $response != "200" ]; then
    pm2 restart mix-cotacao-web
    echo "$(date): Aplicação reiniciada devido a falha na verificação de saúde" >> /home/ubuntu/logs/healthcheck.log
fi
```

```bash
chmod +x healthcheck.sh
# Adicionar ao crontab para executar a cada 5 minutos
crontab -e
# Adicionar: */5 * * * * /home/ubuntu/mix-cotacao-web/healthcheck.sh
```

## 12. Segurança Adicional

### 12.1 Configurar Fail2Ban
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 12.2 Configurações de Segurança PostgreSQL
```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
# Definir: listen_addresses = 'localhost'
sudo systemctl restart postgresql
```

## 13. Testes Finais

### 13.1 Verificar Aplicação
```bash
# Testar login de administrador
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"administrador@softsan.com.br","password":"M1xgestao@2025"}'

# Verificar se a aplicação está respondendo
curl http://seu-ip-ou-dominio/
```

### 13.2 Testar Funcionalidades
- Acesse a aplicação pelo navegador
- Faça login com as credenciais de administrador
- Teste criação de vendedores
- Teste criação de cotações
- Verifique se a API está funcionando

## Comandos de Emergência

```bash
# Parar tudo
pm2 stop all
sudo systemctl stop nginx

# Iniciar tudo
sudo systemctl start nginx
pm2 start all

# Ver uso de recursos
htop
df -h
free -h
```

## Notas Importantes

1. **Backup Regular**: Configure backups automáticos do banco de dados
2. **Monitoramento**: Use PM2 monit ou ferramentas como New Relic
3. **Atualizações**: Mantenha o sistema e dependências atualizados
4. **Logs**: Configure rotação de logs para economizar espaço
5. **Domínio**: Configure um domínio próprio para produção
6. **SSL**: Sempre use HTTPS em produção

## Custos Estimados (AWS Lightsail)
- Instância $10/mês: 2GB RAM, 1 vCPU, 60GB SSD
- Backup automático: +$2/mês
- IP estático: incluído
- Transferência: 3TB incluído

Total aproximado: $12-15/mês