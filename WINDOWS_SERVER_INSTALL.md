# Mix Cotação Web - Instalação Windows Server Local

## Requisitos Mínimos
- Windows Server 2016+ ou Windows 10/11
- 4GB RAM
- 20GB espaço em disco
- Conexão com internet (para download inicial)

## Opção 1: Instalação Automática (Recomendada)

### 1. Baixar o Script
Baixe o arquivo `install-windows.ps1` para o servidor

### 2. Executar como Administrador
```powershell
# Abrir PowerShell como Administrador
# Permitir execução de scripts
Set-ExecutionPolicy Bypass -Scope Process -Force

# Executar instalação
.\install-windows.ps1
```

O script irá:
- ✅ Instalar PostgreSQL com senha automática
- ✅ Configurar banco de dados e tabelas
- ✅ Instalar Node.js e PM2
- ✅ Criar aplicação em `C:\MixCotacao`
- ✅ Configurar firewall do Windows
- ✅ Criar atalhos na área de trabalho
- ✅ Iniciar sistema automaticamente

## Opção 2: Instalação Manual

### 1. Instalar PostgreSQL

#### Baixar PostgreSQL
1. Acesse: https://www.postgresql.org/download/windows/
2. Baixe a versão mais recente (recomendado: 15+)
3. Execute o instalador
4. Configure senha do postgres: `MixGestao2025Database`
5. Porta padrão: `5432`

#### Configurar Banco
```sql
-- Conectar como postgres no pgAdmin ou psql
CREATE DATABASE mixcotacao;
CREATE USER mixadmin WITH ENCRYPTED PASSWORD 'MixGestao2025!Database';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixadmin;
ALTER USER mixadmin CREATEDB;
```

#### Criar Tabelas
```sql
-- Conectar no banco mixcotacao como mixadmin
CREATE TABLE sellers (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  password TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Ativo',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE quotations (
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

CREATE TABLE quotation_items (
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
```

### 2. Instalar Node.js

#### Baixar Node.js
1. Acesse: https://nodejs.org/
2. Baixe a versão LTS mais recente
3. Execute o instalador (inclui npm automaticamente)
4. Reinicie o computador

#### Verificar Instalação
```cmd
node --version
npm --version
```

### 3. Instalar PM2 (Gerenciador de Processos)
```cmd
npm install -g pm2
npm install -g pm2-windows-startup
pm2-startup install
```

### 4. Criar Aplicação

#### Criar Diretório
```cmd
mkdir C:\MixCotacao
cd C:\MixCotacao
mkdir server
mkdir logs
```

#### Criar package.json
```json
{
  "name": "mix-cotacao-web",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node server/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "bcrypt": "^5.1.1",
    "pg": "^8.11.3"
  }
}
```

#### Instalar Dependências
```cmd
npm install
```

#### Criar Servidor (server/index.js)
```javascript
import express from 'express';
import session from 'express-session';
import pkg from 'pg';
import bcrypt from 'bcrypt';

const { Pool } = pkg;
const app = express();
const port = 3000;

// Configuração do banco
const pool = new Pool({
  connectionString: 'postgresql://mixadmin:MixGestao2025!Database@localhost:5432/mixcotacao'
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: 'mix-cotacao-windows-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 24 * 60 * 60 * 1000 }
}));

// Criar usuário admin se não existir
async function initAdmin() {
  try {
    const result = await pool.query('SELECT id FROM sellers WHERE email = $1', ['administrador@softsan.com.br']);
    
    if (result.rows.length === 0) {
      const hashedPassword = await bcrypt.hash('M1xgestao@2025', 10);
      await pool.query(
        'INSERT INTO sellers (email, name, password) VALUES ($1, $2, $3)',
        ['administrador@softsan.com.br', 'Administrador', hashedPassword]
      );
      console.log('✅ Admin criado');
    }
  } catch (error) {
    console.error('Erro ao criar admin:', error);
  }
}

// Health check
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', platform: 'Windows' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await pool.query('SELECT * FROM sellers WHERE email = $1', [email]);
    
    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Credenciais inválidas' });
    }
    
    const seller = result.rows[0];
    const isValid = await bcrypt.compare(password, seller.password);
    
    if (!isValid) {
      return res.status(401).json({ message: 'Credenciais inválidas' });
    }
    
    req.session.userId = seller.id;
    res.json({
      id: seller.id,
      name: seller.name,
      email: seller.email,
      isAdmin: email === 'administrador@softsan.com.br'
    });
  } catch (error) {
    res.status(500).json({ message: 'Erro interno' });
  }
});

// Interface simples
app.get('*', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Mix Cotação Web - Windows Server</title>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial; margin: 40px; text-align: center; }
          .container { max-width: 600px; margin: 0 auto; }
          input { padding: 10px; margin: 5px; width: 200px; }
          button { padding: 10px 20px; background: #007bff; color: white; border: none; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Mix Cotação Web</h1>
          <h3>Windows Server Local</h3>
          
          <div>
            <input type="email" id="email" placeholder="Email" value="administrador@softsan.com.br"><br>
            <input type="password" id="password" placeholder="Senha" value="M1xgestao@2025"><br>
            <button onclick="login()">Entrar</button>
            <div id="result"></div>
          </div>
          
          <hr>
          <p><a href="/api/health">Status do Sistema</a></p>
        </div>
        
        <script>
          async function login() {
            try {
              const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  email: document.getElementById('email').value,
                  password: document.getElementById('password').value
                })
              });
              
              const data = await response.json();
              document.getElementById('result').innerHTML = 
                response.ok ? 'Login OK: ' + data.name : 'Erro: ' + data.message;
            } catch (error) {
              document.getElementById('result').innerHTML = 'Erro: ' + error.message;
            }
          }
        </script>
      </body>
    </html>
  `);
});

// Iniciar servidor
initAdmin().then(() => {
  app.listen(port, () => {
    console.log(`🚀 Mix Cotação Web rodando na porta ${port}`);
    console.log(`🌐 Acesse: http://localhost:${port}`);
    console.log(`📁 Diretório: C:\\MixCotacao`);
  });
});
```

### 5. Configurar PM2

#### Criar ecosystem.config.json
```json
{
  "apps": [{
    "name": "mix-cotacao",
    "script": "server/index.js",
    "cwd": "C:/MixCotacao",
    "env": {
      "NODE_ENV": "production"
    }
  }]
}
```

#### Iniciar Aplicação
```cmd
pm2 start ecosystem.config.json
pm2 save
pm2 startup
```

### 6. Configurar Firewall Windows

#### Via Interface Gráfica
1. Abrir "Windows Defender Firewall"
2. Clicar em "Configurações Avançadas"
3. Clicar em "Regras de Entrada" → "Nova Regra"
4. Tipo: Porta
5. TCP, porta específica: 3000
6. Permitir conexão
7. Nome: "Mix Cotacao Web"

#### Via PowerShell
```powershell
New-NetFirewallRule -DisplayName "Mix Cotacao Web" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

### 7. Configurar IIS (Opcional - Para Produção)

#### Instalar IIS
1. Painel de Controle → Programas → Recursos do Windows
2. Marcar "Serviços de Informações da Internet (IIS)"
3. Instalar

#### Configurar Proxy Reverso
1. Instalar URL Rewrite e Application Request Routing
2. Criar site no IIS apontando para Node.js na porta 3000

## Comandos Úteis

### Gerenciar Aplicação
```cmd
# Status
pm2 status

# Parar
pm2 stop mix-cotacao

# Iniciar
pm2 start mix-cotacao

# Reiniciar
pm2 restart mix-cotacao

# Logs
pm2 logs mix-cotacao

# Monitorar
pm2 monit
```

### Verificar Serviços
```cmd
# PostgreSQL
net start postgresql-x64-15

# Verificar portas
netstat -an | findstr :3000
netstat -an | findstr :5432
```

## Acesso ao Sistema

### URLs
- **Local**: http://localhost:3000
- **Rede local**: http://IP-DO-SERVIDOR:3000

### Credenciais Padrão
- **Email**: administrador@softsan.com.br
- **Senha**: M1xgestao@2025

## Estrutura de Arquivos
```
C:\MixCotacao\
├── server\
│   └── index.js
├── logs\
├── package.json
├── ecosystem.config.json
└── node_modules\
```

## Backup e Manutenção

### Backup do Banco
```cmd
pg_dump -U mixadmin -h localhost mixcotacao > backup.sql
```

### Restaurar Banco
```cmd
psql -U mixadmin -h localhost mixcotacao < backup.sql
```

### Logs do Sistema
- Aplicação: `C:\MixCotacao\logs\`
- PM2: `%USERPROFILE%\.pm2\logs\`
- PostgreSQL: `C:\Program Files\PostgreSQL\15\data\log\`

## Solução de Problemas

### Aplicação não inicia
```cmd
# Verificar Node.js
node --version

# Verificar dependências
cd C:\MixCotacao
npm install

# Verificar PM2
pm2 status
```

### Banco não conecta
```cmd
# Testar conexão
psql -U mixadmin -h localhost -d mixcotacao

# Verificar serviço PostgreSQL
services.msc
```

### Porta em uso
```cmd
# Verificar o que está usando a porta
netstat -ano | findstr :3000

# Matar processo se necessário
taskkill /PID [NUMERO_DO_PID] /F
```

## Recursos Adicionais

### Monitoramento
- PM2 Monitor: `pm2 monit`
- Task Manager: Verificar processo node.js
- Event Viewer: Logs do sistema Windows

### Performance
- Aumentar RAM se necessário
- SSD recomendado para melhor performance
- Configurar antivírus para excluir pasta C:\MixCotacao

### Segurança
- Configurar Windows Update
- Firewall apenas para IPs necessários
- Backup regular do banco de dados
- Monitorar logs de acesso