#!/bin/bash
# Mix Cotação Web - Instalação AWS (Versão Corrigida)
# Execute: chmod +x install-aws-fixed.sh && ./install-aws-fixed.sh

set -e

echo "🚀 Mix Cotação Web - Instalação AWS"
echo "=================================="

# Verificar se não é root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Não execute como root. Use um usuário comum com sudo."
   exit 1
fi

# Detectar OS
if [ -f /etc/amazon-linux-release ]; then
    OS="amazon"
elif [ -f /etc/lsb-release ]; then
    OS="ubuntu"
else
    echo "❌ Sistema operacional não suportado"
    exit 1
fi

echo "📋 Sistema detectado: $OS"

# 1. Atualizar sistema
echo "📦 Atualizando sistema..."
if [ "$OS" = "amazon" ]; then
    sudo yum update -y
    sudo yum install -y postgresql postgresql-server postgresql-contrib curl wget git
else
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y postgresql postgresql-contrib curl wget git
fi

# 2. Configurar PostgreSQL
echo "🗄️ Configurando PostgreSQL..."
if [ "$OS" = "amazon" ]; then
    sudo postgresql-setup initdb
fi

sudo systemctl start postgresql
sudo systemctl enable postgresql

# Criar banco e usuário
sudo -u postgres psql << 'EOPSQL'
CREATE DATABASE mixcotacao;
CREATE USER mixadmin WITH ENCRYPTED PASSWORD 'MixGestao2025!Database';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixadmin;
ALTER USER mixadmin CREATEDB;
\q
EOPSQL

# Configurar autenticação
if [ "$OS" = "amazon" ]; then
    PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
else
    PG_HBA="/etc/postgresql/*/main/pg_hba.conf"
    PG_HBA=$(ls $PG_HBA | head -1)
fi

sudo cp $PG_HBA $PG_HBA.backup
sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' $PG_HBA
echo "host    mixcotacao      mixadmin        127.0.0.1/32            md5" | sudo tee -a $PG_HBA > /dev/null

sudo systemctl restart postgresql

# Criar tabelas
echo "🗄️ Criando tabelas do banco..."
PGPASSWORD='MixGestao2025!Database' psql -h localhost -U mixadmin -d mixcotacao << 'EOSQL'
CREATE TABLE IF NOT EXISTS sellers (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  password TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Ativo',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quotations (
  id SERIAL PRIMARY KEY,
  number TEXT NOT NULL UNIQUE,
  date TIMESTAMP NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'Aguardando digitação',
  deadline TIMESTAMP NOT NULL,
  supplier_cnpj TEXT NOT NULL,
  supplier_name TEXT NOT NULL,
  client_cnpj TEXT NOT NULL,
  client_name TEXT NOT NULL,
  internal_observation TEXT,
  seller_id INTEGER REFERENCES sellers(id) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quotation_items (
  id SERIAL PRIMARY KEY,
  quotation_id INTEGER REFERENCES quotations(id) NOT NULL,
  barcode TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quoted_quantity INTEGER NOT NULL,
  available_quantity INTEGER,
  unit_price DECIMAL(10,2),
  validity TIMESTAMP,
  situation TEXT
);
EOSQL

echo "✅ PostgreSQL configurado"

# 3. Instalar Node.js
echo "📦 Instalando Node.js..."
if [ "$OS" = "amazon" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
else
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

sudo npm install -g pm2

# 4. Criar usuário e estrutura
echo "👤 Criando usuário mixapp..."
sudo useradd -m -s /bin/bash mixapp 2>/dev/null || true
sudo mkdir -p /opt/mixcotacao
sudo chown -R mixapp:mixapp /opt/mixcotacao

# 5. Criar arquivos da aplicação em /tmp primeiro
echo "📝 Criando arquivos da aplicação..."
mkdir -p /tmp/mixapp/{server,shared}

# Package.json
cat > /tmp/mixapp/package.json << 'EOF'
{
  "name": "mix-cotacao-web",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "NODE_ENV=production node server/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "bcrypt": "^5.1.1",
    "pg": "^8.11.3"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.0"
  }
}
EOF

# Servidor em JavaScript puro (sem TypeScript para simplificar)
cat > /tmp/mixapp/server/index.js << 'EOF'
import express from 'express';
import session from 'express-session';
import pkg from 'pg';
import bcrypt from 'bcrypt';

const { Pool } = pkg;
const app = express();
const port = process.env.PORT || 3000;

// Database
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://mixadmin:MixGestao2025!Database@localhost:5432/mixcotacao'
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: process.env.SESSION_SECRET || 'mix-cotacao-secret-' + Math.random(),
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: false,
    maxAge: 24 * 60 * 60 * 1000
  }
}));

// Initialize admin user
async function initAdmin() {
  try {
    const result = await pool.query('SELECT id FROM sellers WHERE email = $1', ['administrador@softsan.com.br']);
    
    if (result.rows.length === 0) {
      const hashedPassword = await bcrypt.hash('M1xgestao@2025', 10);
      await pool.query(
        'INSERT INTO sellers (email, name, password, status) VALUES ($1, $2, $3, $4)',
        ['administrador@softsan.com.br', 'Administrador', hashedPassword, 'Ativo']
      );
      console.log('✅ Admin user created');
    }
  } catch (error) {
    console.error('❌ Error initializing admin:', error.message);
  }
}

// Health check
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy', 
      error: error.message 
    });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ message: 'Email e senha são obrigatórios' });
    }
    
    const result = await pool.query('SELECT * FROM sellers WHERE email = $1', [email]);
    
    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Credenciais inválidas' });
    }
    
    const seller = result.rows[0];
    const isValid = await bcrypt.compare(password, seller.password);
    
    if (!isValid) {
      return res.status(401).json({ message: 'Credenciais inválidas' });
    }
    
    if (seller.status === 'Inativo') {
      return res.status(401).json({ message: 'Usuário inativo' });
    }
    
    req.session.userId = seller.id;
    req.session.isAdmin = seller.email === 'administrador@softsan.com.br';
    
    res.json({
      id: seller.id,
      name: seller.name,
      email: seller.email,
      isAdmin: seller.email === 'administrador@softsan.com.br'
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Erro interno do servidor' });
  }
});

// Get current user
app.get('/api/auth/me', async (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ message: 'Não autorizado' });
  }
  
  try {
    const result = await pool.query('SELECT id, name, email, status FROM sellers WHERE id = $1', [req.session.userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Usuário não encontrado' });
    }
    
    const seller = result.rows[0];
    res.json({
      id: seller.id,
      name: seller.name,
      email: seller.email,
      isAdmin: seller.email === 'administrador@softsan.com.br'
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Erro interno do servidor' });
  }
});

// Logout
app.post('/api/auth/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ message: 'Erro ao fazer logout' });
    }
    res.json({ message: 'Logout realizado com sucesso' });
  });
});

// Interface web simples
app.get('*', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Mix Cotação Web</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
          .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .status { color: #28a745; font-weight: bold; font-size: 18px; }
          .login-form { max-width: 400px; margin: 30px auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px; background: #f9f9f9; }
          .login-form input { width: 100%; padding: 12px; margin: 8px 0; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
          .login-form button { width: 100%; padding: 12px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
          .login-form button:hover { background: #0056b3; }
          .links { text-align: center; margin: 20px 0; }
          .links a { color: #007bff; text-decoration: none; margin: 0 10px; }
          .info { background: #e9ecef; padding: 15px; border-radius: 5px; margin: 20px 0; }
          h1 { color: #333; text-align: center; }
          h3 { color: #666; margin-bottom: 15px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Mix Cotação Web</h1>
          <p class="status">✅ Sistema instalado e funcionando!</p>
          
          <div class="info">
            <h3>Informações do Sistema:</h3>
            <p><strong>Ambiente:</strong> ${process.env.NODE_ENV || 'development'}</p>
            <p><strong>Porta:</strong> ${port}</p>
            <p><strong>Banco:</strong> PostgreSQL Local</p>
            <p><strong>Versão:</strong> 1.0.0</p>
          </div>
          
          <div class="login-form">
            <h3>Acesso ao Sistema</h3>
            <input type="email" id="email" placeholder="Email" value="administrador@softsan.com.br">
            <input type="password" id="password" placeholder="Senha" value="M1xgestao@2025">
            <button onclick="login()">Entrar</button>
            <div id="message" style="margin-top: 10px; text-align: center;"></div>
          </div>
          
          <div class="links">
            <a href="/api/health">🔍 Status do Sistema</a>
            <a href="javascript:testLogin()">🔑 Testar Login</a>
            <a href="javascript:getUser()">👤 Info do Usuário</a>
          </div>
        </div>
        
        <script>
          function showMessage(msg, type = 'info') {
            const div = document.getElementById('message');
            div.innerHTML = msg;
            div.style.color = type === 'error' ? '#dc3545' : '#28a745';
          }
          
          async function login() {
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            
            try {
              const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
              });
              
              const data = await response.json();
              
              if (response.ok) {
                showMessage('✅ Login realizado com sucesso! Usuário: ' + data.name);
              } else {
                showMessage('❌ ' + data.message, 'error');
              }
            } catch (error) {
              showMessage('❌ Erro de conexão: ' + error.message, 'error');
            }
          }
          
          async function testLogin() {
            try {
              const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                  email: 'administrador@softsan.com.br', 
                  password: 'M1xgestao@2025' 
                })
              });
              
              const data = await response.json();
              alert(response.ok ? '✅ Teste OK: ' + data.name : '❌ Erro: ' + data.message);
            } catch (error) {
              alert('❌ Erro: ' + error.message);
            }
          }
          
          async function getUser() {
            try {
              const response = await fetch('/api/auth/me');
              const data = await response.json();
              
              if (response.ok) {
                alert('👤 Usuário logado: ' + data.name + ' (' + data.email + ')');
              } else {
                alert('ℹ️ ' + data.message);
              }
            } catch (error) {
              alert('❌ Erro: ' + error.message);
            }
          }
        </script>
      </body>
    </html>
  `);
});

// Inicializar e startar servidor
initAdmin().then(() => {
  app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 Mix Cotação Web rodando na porta ${port}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🗄️ Database: PostgreSQL Local`);
  });
});
EOF

# Configuração de ambiente
cat > /tmp/mixapp/.env << 'EOF'
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://mixadmin:MixGestao2025!Database@localhost:5432/mixcotacao
EOF

# 6. Mover arquivos para o destino final
echo "📂 Instalando aplicação..."
sudo cp -r /tmp/mixapp/* /opt/mixcotacao/
sudo chown -R mixapp:mixapp /opt/mixcotacao
rm -rf /tmp/mixapp

# 7. Instalar dependências
echo "📦 Instalando dependências..."
cd /opt/mixcotacao
sudo -u mixapp npm install

# 8. Iniciar aplicação
echo "🚀 Iniciando aplicação..."
sudo -u mixapp pm2 start server/index.js --name "mix-cotacao"
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u mixapp --hp /home/mixapp
sudo -u mixapp pm2 save

# 9. Instalar e configurar Nginx
echo "🌐 Configurando Nginx..."
if [ "$OS" = "amazon" ]; then
    sudo yum install -y nginx
else
    sudo apt install -y nginx
fi

sudo tee /etc/nginx/conf.d/mixcotacao.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    
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
        proxy_connect_timeout 30;
        proxy_send_timeout 30;
        proxy_read_timeout 30;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx

# 10. Configurar firewall básico
echo "🔥 Configurando firewall..."
if command -v firewall-cmd &> /dev/null; then
    sudo systemctl start firewalld 2>/dev/null || true
    sudo systemctl enable firewalld 2>/dev/null || true
    sudo firewall-cmd --permanent --add-service=http 2>/dev/null || true
    sudo firewall-cmd --permanent --add-service=https 2>/dev/null || true
    sudo firewall-cmd --permanent --add-service=ssh 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
elif command -v ufw &> /dev/null; then
    sudo ufw allow 22 2>/dev/null || true
    sudo ufw allow 80 2>/dev/null || true
    sudo ufw allow 443 2>/dev/null || true
    echo "y" | sudo ufw enable 2>/dev/null || true
fi

# 11. Testar instalação
echo "🧪 Testando instalação..."
sleep 10

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "SEU-IP-PUBLICO")

if curl -f http://localhost/api/health > /dev/null 2>&1; then
    HEALTH_STATUS="✅ OK"
else
    HEALTH_STATUS="❌ Falhou"
fi

# 12. Resultado final
echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA!"
echo "======================="
echo ""
echo "📍 Acesso:"
echo "   URL: http://$PUBLIC_IP"
echo "   Health: $HEALTH_STATUS"
echo ""
echo "🔑 Login:"
echo "   Email: administrador@softsan.com.br"
echo "   Senha: M1xgestao@2025"
echo ""
echo "⚙️ Comandos úteis:"
echo "   Status: sudo -u mixapp pm2 status"
echo "   Logs: sudo -u mixapp pm2 logs mix-cotacao"
echo "   Restart: sudo -u mixapp pm2 restart mix-cotacao"
echo ""
echo "📁 Arquivos:"
echo "   App: /opt/mixcotacao"
echo "   Logs: /home/mixapp/.pm2/logs/"
echo ""

if [ "$HEALTH_STATUS" = "✅ OK" ]; then
    echo "✅ Sistema funcionando perfeitamente!"
    echo "🌐 Acesse: http://$PUBLIC_IP"
else
    echo "⚠️ Verificar logs se houver problemas:"
    echo "   sudo -u mixapp pm2 logs mix-cotacao --lines 50"
fi