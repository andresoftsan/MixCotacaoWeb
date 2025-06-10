#!/bin/bash
# Mix Cotação Web - Instalação Automatizada AWS
# Execute: curl -fsSL https://raw.githubusercontent.com/seu-repo/install-aws.sh | bash

set -e

echo "🚀 Instalação Mix Cotação Web - AWS"
echo "=================================="

# Verificar se é root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Não execute como root. Use um usuário comum com sudo."
   exit 1
fi

# Detectar sistema operacional
if [ -f /etc/amazon-linux-release ]; then
    OS="amazon"
    PKG_MANAGER="yum"
elif [ -f /etc/lsb-release ]; then
    OS="ubuntu"
    PKG_MANAGER="apt"
else
    echo "❌ Sistema operacional não suportado"
    exit 1
fi

echo "📋 Detectado: $OS"

# Função para instalar pacotes
install_package() {
    if [ "$PKG_MANAGER" = "yum" ]; then
        sudo yum install -y $1
    else
        sudo apt update && sudo apt install -y $1
    fi
}

# 1. Atualizar sistema
echo "📦 Atualizando sistema..."
if [ "$PKG_MANAGER" = "yum" ]; then
    sudo yum update -y
else
    sudo apt update && sudo apt upgrade -y
fi

# 2. Instalar PostgreSQL
echo "🗄️  Instalando PostgreSQL..."
if [ "$OS" = "amazon" ]; then
    install_package "postgresql postgresql-server postgresql-contrib"
    sudo postgresql-setup initdb
else
    install_package "postgresql postgresql-contrib"
fi

sudo systemctl start postgresql
sudo systemctl enable postgresql

# 3. Configurar PostgreSQL
echo "⚙️  Configurando PostgreSQL..."
sudo -u postgres psql << 'EOSQL'
CREATE DATABASE mixcotacao;
CREATE USER mixadmin WITH ENCRYPTED PASSWORD 'MixGestao2025!Database';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixadmin;
ALTER USER mixadmin CREATEDB;
\q
EOSQL

# Configurar autenticação
if [ "$OS" = "amazon" ]; then
    PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
else
    PG_HBA=$(sudo -u postgres psql -t -P format=unaligned -c 'show hba_file;')
fi

sudo cp $PG_HBA $PG_HBA.backup
sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' $PG_HBA
echo "host    mixcotacao      mixadmin        127.0.0.1/32            md5" | sudo tee -a $PG_HBA

sudo systemctl restart postgresql

# Testar conexão
echo "🔍 Testando conexão PostgreSQL..."
PGPASSWORD='MixGestao2025!Database' psql -h localhost -U mixadmin -d mixcotacao -c "SELECT 1;" > /dev/null
echo "✅ PostgreSQL configurado com sucesso"

# 4. Instalar Node.js
echo "📦 Instalando Node.js..."
if [ "$OS" = "amazon" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    install_package "nodejs"
else
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    install_package "nodejs"
fi

sudo npm install -g pm2

# 5. Criar usuário e diretórios
echo "👤 Criando usuário da aplicação..."
sudo useradd -m -s /bin/bash mixapp || true
sudo mkdir -p /opt/mixcotacao
sudo chown -R mixapp:mixapp /opt/mixcotacao

# 6. Baixar código da aplicação
echo "📥 Baixando código da aplicação..."
cd /tmp

# Criar estrutura básica da aplicação
sudo -u mixapp mkdir -p /opt/mixcotacao/{server,client/src,shared}

# Package.json
sudo -u mixapp bash -c 'cat > /opt/mixcotacao/package.json << '"'"'EOF'"'"'
{
  "name": "mix-cotacao-web",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "NODE_ENV=production tsx server/index.ts",
    "dev": "NODE_ENV=development tsx server/index.ts"
  },
  "dependencies": {
    "@neondatabase/serverless": "^0.9.0",
    "bcrypt": "^5.1.1",
    "connect-pg-simple": "^9.0.1",
    "drizzle-orm": "^0.29.0",
    "drizzle-zod": "^0.5.1",
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "tsx": "^4.6.0",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/bcrypt": "^5.0.2",
    "@types/express": "^4.17.21",
    "@types/express-session": "^1.17.10",
    "@types/node": "^20.10.0"
  }
}
EOF

# Configurar variáveis de ambiente
sudo -u mixapp bash -c 'cat > /opt/mixcotacao/.env << '"'"'EOF'"'"'
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://mixadmin:MixGestao2025!Database@localhost:5432/mixcotacao
SESSION_SECRET=mix-cotacao-production-$(openssl rand -hex 32)
EOF

# Schema básico
sudo -u mixapp bash -c 'cat > /opt/mixcotacao/shared/schema.ts << '"'"'EOF'"'"'
import { pgTable, text, serial, integer, boolean, timestamp, decimal } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const sellers = pgTable("sellers", {
  id: serial("id").primaryKey(),
  email: text("email").notNull().unique(),
  name: text("name").notNull(),
  password: text("password").notNull(),
  status: text("status").notNull().default("Ativo"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const quotations = pgTable("quotations", {
  id: serial("id").primaryKey(),
  number: text("number").notNull().unique(),
  date: timestamp("date").notNull().defaultNow(),
  status: text("status").notNull().default("Aguardando digitação"),
  deadline: timestamp("deadline").notNull(),
  supplierCnpj: text("supplier_cnpj").notNull(),
  supplierName: text("supplier_name").notNull(),
  clientCnpj: text("client_cnpj").notNull(),
  clientName: text("client_name").notNull(),
  internalObservation: text("internal_observation"),
  sellerId: integer("seller_id").references(() => sellers.id).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});

export const quotationItems = pgTable("quotation_items", {
  id: serial("id").primaryKey(),
  quotationId: integer("quotation_id").references(() => quotations.id).notNull(),
  barcode: text("barcode").notNull(),
  productName: text("product_name").notNull(),
  quotedQuantity: integer("quoted_quantity").notNull(),
  availableQuantity: integer("available_quantity"),
  unitPrice: decimal("unit_price", { precision: 10, scale: 2 }),
  validity: timestamp("validity"),
  situation: text("situation"),
});

export const insertSellerSchema = createInsertSchema(sellers).omit({
  id: true,
  createdAt: true,
});

export type InsertSeller = z.infer<typeof insertSellerSchema>;
export type Seller = typeof sellers.$inferSelect;
EOF

# Servidor básico
sudo -u mixapp bash -c 'cat > /opt/mixcotacao/server/index.ts << '"'"'EOF'"'"'
import express from 'express';
import session from 'express-session';
import { Pool } from '@neondatabase/serverless';
import bcrypt from 'bcrypt';

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Session
app.use(session({
  secret: process.env.SESSION_SECRET || 'fallback-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: false,
    maxAge: 24 * 60 * 60 * 1000
  }
}));

// Database
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Initialize admin user
app.use(async (req, res, next) => {
  try {
    const adminCheck = await pool.query(
      'SELECT id FROM sellers WHERE email = $1',
      ['administrador@softsan.com.br']
    );
    
    if (adminCheck.rows.length === 0) {
      const hashedPassword = await bcrypt.hash('M1xgestao@2025', 10);
      await pool.query(
        'INSERT INTO sellers (email, name, password, status) VALUES ($1, $2, $3, $4)',
        ['administrador@softsan.com.br', 'Administrador', hashedPassword, 'Ativo']
      );
      console.log('Admin user created');
    }
  } catch (error) {
    console.error('Error initializing admin:', error);
  }
  next();
});

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
    
    const result = await pool.query(
      'SELECT * FROM sellers WHERE email = $1',
      [email]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Credenciais inválidas' });
    }
    
    const seller = result.rows[0];
    const isValid = await bcrypt.compare(password, seller.password);
    
    if (!isValid) {
      return res.status(401).json({ message: 'Credenciais inválidas' });
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

// Serve static files
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
          .login-form { max-width: 300px; margin: 20px auto; }
          .login-form input { width: 100%; padding: 10px; margin: 5px 0; }
          .login-form button { width: 100%; padding: 10px; background: #007bff; color: white; border: none; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Mix Cotação Web</h1>
          <p class="status">Sistema instalado com sucesso!</p>
          
          <div class="login-form">
            <h3>Login</h3>
            <input type="email" id="email" placeholder="Email" value="administrador@softsan.com.br">
            <input type="password" id="password" placeholder="Senha" value="M1xgestao@2025">
            <button onclick="login()">Entrar</button>
          </div>
          
          <hr>
          <p><a href="/api/health">Verificar Saúde do Sistema</a></p>
        </div>
        
        <script>
          async function login() {
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            
            try {
              const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
              });
              
              if (response.ok) {
                const user = await response.json();
                alert('Login realizado com sucesso! Usuário: ' + user.name);
              } else {
                const error = await response.json();
                alert('Erro: ' + error.message);
              }
            } catch (error) {
              alert('Erro de conexão: ' + error.message);
            }
          }
        </script>
      </body>
    </html>
  `);
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Mix Cotação Web servidor rodando na porta ${port}`);
});
EOF

# 7. Instalar dependências
echo "📦 Instalando dependências..."
cd /opt/mixcotacao
sudo -u mixapp npm install

# 8. Configurar banco de dados
echo "🗄️  Configurando banco de dados..."
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

# 9. Iniciar aplicação
echo "🚀 Iniciando aplicação..."
sudo -u mixapp pm2 start npm --name "mix-cotacao" -- start
sudo -u mixapp pm2 startup
sudo -u mixapp pm2 save

# 10. Instalar e configurar Nginx
echo "🌐 Configurando Nginx..."
install_package "nginx"

sudo cat > /etc/nginx/conf.d/mixcotacao.conf << 'EOF'
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
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx

# 11. Configurar firewall
echo "🔥 Configurando firewall..."
if command -v firewall-cmd &> /dev/null; then
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload
elif command -v ufw &> /dev/null; then
    sudo ufw allow 22
    sudo ufw allow 80
    sudo ufw allow 443
    echo "y" | sudo ufw enable
fi

# 12. Testar instalação
echo "🧪 Testando instalação..."
sleep 5

if curl -f http://localhost/api/health > /dev/null 2>&1; then
    echo "✅ Health check passou"
else
    echo "❌ Health check falhou"
fi

# 13. Finalização
echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "=================================="
echo ""
echo "📍 URLs de Acesso:"
echo "   Aplicação: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'SEU-IP-PUBLICO')"
echo "   Health Check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'SEU-IP-PUBLICO')/api/health"
echo ""
echo "🔑 Credenciais de Login:"
echo "   Email: administrador@softsan.com.br"
echo "   Senha: M1xgestao@2025"
echo ""
echo "📋 Comandos Úteis:"
echo "   Status: sudo -u mixapp pm2 status"
echo "   Logs: sudo -u mixapp pm2 logs mix-cotacao"
echo "   Reiniciar: sudo -u mixapp pm2 restart mix-cotacao"
echo "   Nginx: sudo systemctl status nginx"
echo "   PostgreSQL: sudo systemctl status postgresql"
echo ""
echo "📁 Diretórios:"
echo "   Aplicação: /opt/mixcotacao"
echo "   Logs: /home/mixapp/.pm2/logs/"
echo "   Config Nginx: /etc/nginx/conf.d/mixcotacao.conf"
echo ""
echo "🎯 Sistema pronto para uso!"