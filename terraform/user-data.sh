#!/bin/bash
# Script de inicialização para EC2 - Mix Cotação Web

# Atualizar sistema
yum update -y

# Instalar Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git

# Instalar PM2 globalmente
npm install -g pm2

# Criar usuário para aplicação
useradd -m -s /bin/bash mixapp

# Criar diretório da aplicação
mkdir -p /opt/mixcotacao
chown mixapp:mixapp /opt/mixcotacao

# Configurar aplicação como usuário mixapp
su - mixapp << 'EOF'
cd /opt/mixcotacao

# Criar estrutura básica da aplicação (substitua pelo seu repositório)
cat > package.json << 'PKG'
{
  "name": "mix-cotacao-web",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "NODE_ENV=production tsx server/index.ts",
    "dev": "NODE_ENV=development tsx server/index.ts",
    "build": "echo 'Build completed'"
  },
  "dependencies": {
    "@hookform/resolvers": "^3.3.2",
    "@neondatabase/serverless": "^0.9.0",
    "@radix-ui/react-accordion": "^1.1.2",
    "@radix-ui/react-alert-dialog": "^1.0.5",
    "@radix-ui/react-aspect-ratio": "^1.0.3",
    "@radix-ui/react-avatar": "^1.0.4",
    "@radix-ui/react-checkbox": "^1.0.4",
    "@radix-ui/react-collapsible": "^1.0.3",
    "@radix-ui/react-context-menu": "^2.1.5",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-hover-card": "^1.0.7",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-menubar": "^1.0.4",
    "@radix-ui/react-navigation-menu": "^1.1.4",
    "@radix-ui/react-popover": "^1.0.7",
    "@radix-ui/react-progress": "^1.0.3",
    "@radix-ui/react-radio-group": "^1.1.3",
    "@radix-ui/react-scroll-area": "^1.0.5",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-slider": "^1.1.2",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-switch": "^1.0.3",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-toast": "^1.1.5",
    "@radix-ui/react-toggle": "^1.0.3",
    "@radix-ui/react-toggle-group": "^1.0.4",
    "@radix-ui/react-tooltip": "^1.0.7",
    "@tanstack/react-query": "^5.0.0",
    "bcrypt": "^5.1.1",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "cmdk": "^0.2.0",
    "connect-pg-simple": "^9.0.1",
    "date-fns": "^2.30.0",
    "drizzle-kit": "^0.20.0",
    "drizzle-orm": "^0.29.0",
    "drizzle-zod": "^0.5.1",
    "embla-carousel-react": "^8.0.0",
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "framer-motion": "^10.16.0",
    "input-otp": "^1.2.4",
    "lucide-react": "^0.294.0",
    "memorystore": "^1.6.7",
    "nanoid": "^5.0.4",
    "next-themes": "^0.2.1",
    "passport": "^0.7.0",
    "passport-local": "^1.0.0",
    "react": "^18.2.0",
    "react-day-picker": "^8.10.0",
    "react-dom": "^18.2.0",
    "react-hook-form": "^7.48.2",
    "react-icons": "^4.12.0",
    "react-resizable-panels": "^0.0.55",
    "recharts": "^2.8.0",
    "tailwind-merge": "^2.0.0",
    "tailwindcss-animate": "^1.0.7",
    "tsx": "^4.6.0",
    "vaul": "^0.7.9",
    "wouter": "^2.12.1",
    "ws": "^8.14.2",
    "zod": "^3.22.4",
    "zod-validation-error": "^1.5.0"
  },
  "devDependencies": {
    "@types/bcrypt": "^5.0.2",
    "@types/connect-pg-simple": "^7.0.3",
    "@types/express": "^4.17.21",
    "@types/express-session": "^1.17.10",
    "@types/node": "^20.10.0",
    "@types/passport": "^1.0.16",
    "@types/passport-local": "^1.0.38",
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@types/ws": "^8.5.10"
  }
}
PKG

# Configurar variáveis de ambiente
cat > .env << 'ENVFILE'
NODE_ENV=production
PORT=3000
DATABASE_URL=${database_url}
SESSION_SECRET=mix-cotacao-production-secret-$(openssl rand -hex 32)
ENVFILE

# Instalar dependências
npm install

# Criar estrutura de diretórios
mkdir -p server client/src shared

# Criar arquivo principal do servidor (versão simplificada para boot)
cat > server/index.ts << 'SERVERFILE'
import express from 'express';
import { Pool } from '@neondatabase/serverless';

const app = express();
const port = process.env.PORT || 3000;

// Middleware básico
app.use(express.json());
app.use(express.static('dist'));

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    if (process.env.DATABASE_URL) {
      const pool = new Pool({ connectionString: process.env.DATABASE_URL });
      await pool.query('SELECT 1');
      await pool.end();
    }
    
    res.json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      database: process.env.DATABASE_URL ? 'connected' : 'not configured'
    });
  } catch (error: any) {
    res.status(503).json({ 
      status: 'unhealthy', 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint básico
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Mix Cotação Web API is running',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

// Servir aplicação React (fallback)
app.get('*', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Mix Cotação Web</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
          .container { max-width: 600px; margin: 0 auto; }
          .status { color: green; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Mix Cotação Web</h1>
          <p class="status">Sistema inicializado com sucesso!</p>
          <p>O servidor está rodando em modo de produção.</p>
          <p>Para acessar a aplicação completa, aguarde o deploy completo.</p>
          <hr>
          <p><a href="/api/health">Verificar Saúde do Sistema</a></p>
          <p><a href="/api/test">Testar API</a></p>
        </div>
      </body>
    </html>
  `);
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Mix Cotação Web servidor rodando na porta ${port}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
  console.log(`🗄️  Database: ${process.env.DATABASE_URL ? 'Conectado' : 'Não configurado'}`);
});
SERVERFILE

# Iniciar aplicação com PM2
pm2 start npm --name "mix-cotacao" -- start
pm2 startup systemd -u mixapp --hp /home/mixapp
pm2 save

EOF

# Configurar nginx como proxy reverso
yum install -y nginx

cat > /etc/nginx/conf.d/mixcotacao.conf << 'NGINXCONF'
server {
    listen 80;
    server_name _;
    
    # Logs
    access_log /var/log/nginx/mixcotacao.access.log;
    error_log /var/log/nginx/mixcotacao.error.log;
    
    # Proxy para aplicação Node.js
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
    }
    
    # Health check específico
    location /health {
        proxy_pass http://127.0.0.1:3000/api/health;
        access_log off;
    }
}
NGINXCONF

# Remover configuração padrão do nginx
rm -f /etc/nginx/conf.d/default.conf

# Iniciar nginx
systemctl enable nginx
systemctl start nginx

# Configurar logrotate para logs da aplicação
cat > /etc/logrotate.d/mixcotacao << 'LOGROTATE'
/home/mixapp/.pm2/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 644 mixapp mixapp
    postrotate
        /usr/bin/pm2 reloadLogs
    endscript
}
LOGROTATE

# Instalar CloudWatch agent (opcional)
if command -v aws &> /dev/null; then
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
    
    # Configuração básica do CloudWatch
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/mixcotacao.access.log",
                        "log_group_name": "/aws/ec2/mix-cotacao",
                        "log_stream_name": "nginx-access"
                    },
                    {
                        "file_path": "/var/log/nginx/mixcotacao.error.log",
                        "log_group_name": "/aws/ec2/mix-cotacao",
                        "log_stream_name": "nginx-error"
                    },
                    {
                        "file_path": "/home/mixapp/.pm2/logs/mix-cotacao-out.log",
                        "log_group_name": "/aws/ec2/mix-cotacao",
                        "log_stream_name": "app-output"
                    },
                    {
                        "file_path": "/home/mixapp/.pm2/logs/mix-cotacao-error.log",
                        "log_group_name": "/aws/ec2/mix-cotacao",
                        "log_stream_name": "app-error"
                    }
                ]
            }
        }
    }
}
CWCONFIG

    # Iniciar CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -s \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
fi

# Configurar firewall básico
if command -v firewall-cmd &> /dev/null; then
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --reload
fi

# Configurar monitoramento básico
echo "*/5 * * * * root curl -f http://localhost/health > /dev/null 2>&1 || echo 'Mix Cotação Web health check failed' | logger" >> /etc/crontab

# Criar script de deploy para atualizações futuras
cat > /opt/mixcotacao/deploy.sh << 'DEPLOYSCRIPT'
#!/bin/bash
# Script de deploy para atualizações

echo "🚀 Iniciando deploy do Mix Cotação Web..."

cd /opt/mixcotacao

# Backup da versão atual
if [ -d "backup" ]; then
    rm -rf backup.old
    mv backup backup.old
fi
mkdir -p backup
cp -r server client shared package.json backup/ 2>/dev/null || true

# Aqui você adicionaria os comandos para:
# 1. git pull (se usando git)
# 2. npm install (para novas dependências)
# 3. npm run build (se necessário)

# Reiniciar aplicação
su - mixapp -c "cd /opt/mixcotacao && pm2 restart mix-cotacao"

# Verificar saúde
sleep 10
if curl -f http://localhost/health; then
    echo "✅ Deploy concluído com sucesso!"
else
    echo "❌ Deploy falhou - restaurando backup..."
    cp -r backup/* . 2>/dev/null || true
    su - mixapp -c "cd /opt/mixcotacao && pm2 restart mix-cotacao"
fi
DEPLOYSCRIPT

chmod +x /opt/mixcotacao/deploy.sh

# Log final
echo "✅ Mix Cotação Web instalado com sucesso!"
echo "🌐 Aplicação disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "📊 Health check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health"
echo "🔧 Logs da aplicação: /home/mixapp/.pm2/logs/"
echo "📝 Logs do nginx: /var/log/nginx/"