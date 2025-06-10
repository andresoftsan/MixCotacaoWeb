# Mix Cotação Web - Instalação Windows
# Execute no PowerShell como Administrador: Set-ExecutionPolicy Bypass -Scope Process -Force; .\install-windows.ps1

Write-Host "🚀 Mix Cotação Web - Instalação Windows" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Verificar se está executando como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Execute como Administrador" -ForegroundColor Red
    Write-Host "Clique com botão direito no PowerShell e escolha 'Executar como administrador'" -ForegroundColor Yellow
    exit 1
}

# 1. Instalar Chocolatey se não existir
Write-Host "📦 Verificando Chocolatey..." -ForegroundColor Blue
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Instalando Chocolatey..." -ForegroundColor Blue
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}

# 2. Instalar PostgreSQL
Write-Host "🗄️ Instalando PostgreSQL..." -ForegroundColor Blue
choco install postgresql --params '/Password:MixGestao2025Database' -y
refreshenv

# Aguardar PostgreSQL inicializar
Write-Host "⏳ Aguardando PostgreSQL inicializar..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 3. Configurar PostgreSQL
Write-Host "⚙️ Configurando PostgreSQL..." -ForegroundColor Blue
$env:PGPASSWORD = "MixGestao2025Database"

# Criar banco e usuário
$createDbScript = @"
CREATE DATABASE mixcotacao;
CREATE USER mixadmin WITH ENCRYPTED PASSWORD 'MixGestao2025!Database';
GRANT ALL PRIVILEGES ON DATABASE mixcotacao TO mixadmin;
ALTER USER mixadmin CREATEDB;
"@

$createDbScript | & "C:\Program Files\PostgreSQL\*\bin\psql.exe" -U postgres -h localhost

# Criar tabelas
Write-Host "🗄️ Criando tabelas..." -ForegroundColor Blue
$env:PGPASSWORD = "MixGestao2025!Database"
$createTablesScript = @"
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
"@

$createTablesScript | & "C:\Program Files\PostgreSQL\*\bin\psql.exe" -U mixadmin -h localhost -d mixcotacao

Write-Host "✅ PostgreSQL configurado" -ForegroundColor Green

# 4. Instalar Node.js
Write-Host "📦 Instalando Node.js..." -ForegroundColor Blue
choco install nodejs -y
refreshenv

# 5. Instalar PM2
Write-Host "📦 Instalando PM2..." -ForegroundColor Blue
npm install -g pm2
npm install -g pm2-windows-startup
pm2-startup install

# 6. Criar diretório da aplicação
Write-Host "📁 Criando diretório da aplicação..." -ForegroundColor Blue
$appDir = "C:\MixCotacao"
if (Test-Path $appDir) {
    Remove-Item -Recurse -Force $appDir
}
New-Item -ItemType Directory -Path $appDir -Force
New-Item -ItemType Directory -Path "$appDir\server" -Force
Set-Location $appDir

# 7. Criar arquivos da aplicação
Write-Host "📝 Criando arquivos da aplicação..." -ForegroundColor Blue

# Package.json
@"
{
  "name": "mix-cotacao-web",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node server/index.js",
    "dev": "node server/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "bcrypt": "^5.1.1",
    "pg": "^8.11.3"
  }
}
"@ | Out-File -FilePath "package.json" -Encoding UTF8

# Servidor
@"
import express from 'express';
import session from 'express-session';
import pkg from 'pg';
import bcrypt from 'bcrypt';

const { Pool } = pkg;
const app = express();
const port = process.env.PORT || 3000;

// Database
const pool = new Pool({
  connectionString: 'postgresql://mixadmin:MixGestao2025!Database@localhost:5432/mixcotacao'
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: 'mix-cotacao-windows-' + Math.random(),
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
    const result = await pool.query('SELECT id FROM sellers WHERE email = `$1', ['administrador@softsan.com.br']);
    
    if (result.rows.length === 0) {
      const hashedPassword = await bcrypt.hash('M1xgestao@2025', 10);
      await pool.query(
        'INSERT INTO sellers (email, name, password, status) VALUES (`$1, `$2, `$3, `$4)',
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
      database: 'connected',
      platform: 'Windows'
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
    
    const result = await pool.query('SELECT * FROM sellers WHERE email = `$1', [email]);
    
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

// Interface web
app.get('*', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Mix Cotação Web - Windows</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
          .container { max-width: 900px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.1); }
          .header { text-align: center; margin-bottom: 30px; }
          .status { color: #28a745; font-weight: bold; font-size: 20px; margin: 20px 0; }
          .login-form { max-width: 400px; margin: 30px auto; padding: 25px; border: 1px solid #e0e0e0; border-radius: 8px; background: #f8f9fa; }
          .login-form input { width: 100%; padding: 12px; margin: 8px 0; border: 1px solid #ced4da; border-radius: 6px; box-sizing: border-box; font-size: 14px; }
          .login-form button { width: 100%; padding: 12px; background: #007bff; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 16px; font-weight: 500; }
          .login-form button:hover { background: #0056b3; }
          .links { text-align: center; margin: 30px 0; }
          .links a { color: #007bff; text-decoration: none; margin: 0 15px; padding: 8px 16px; border: 1px solid #007bff; border-radius: 4px; display: inline-block; }
          .links a:hover { background: #007bff; color: white; }
          .info { background: #e9ecef; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
          h1 { color: #333; margin: 0; }
          h3 { color: #666; margin-bottom: 15px; }
          .platform { background: #0078d4; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚀 Mix Cotação Web</h1>
            <span class="platform">Windows</span>
            <p class="status">✅ Sistema rodando no Windows!</p>
          </div>
          
          <div class="info">
            <h3>Informações do Sistema:</h3>
            <div class="info-grid">
              <div><strong>Plataforma:</strong> Windows</div>
              <div><strong>Porta:</strong> ${port}</div>
              <div><strong>Banco:</strong> PostgreSQL</div>
              <div><strong>Versão:</strong> 1.0.0</div>
            </div>
          </div>
          
          <div class="login-form">
            <h3>Acesso ao Sistema</h3>
            <input type="email" id="email" placeholder="Email" value="administrador@softsan.com.br">
            <input type="password" id="password" placeholder="Senha" value="M1xgestao@2025">
            <button onclick="login()">Entrar</button>
            <div id="message" style="margin-top: 15px; text-align: center; font-weight: 500;"></div>
          </div>
          
          <div class="links">
            <a href="/api/health">🔍 Status</a>
            <a href="javascript:testLogin()">🔑 Testar Login</a>
            <a href="javascript:openFolder()">📁 Abrir Pasta</a>
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
                showMessage('✅ Login OK! Usuário: ' + data.name);
              } else {
                showMessage('❌ ' + data.message, 'error');
              }
            } catch (error) {
              showMessage('❌ Erro: ' + error.message, 'error');
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
          
          function openFolder() {
            alert('📁 Pasta da aplicação: C:\\MixCotacao');
          }
        </script>
      </body>
    </html>
  `);
});

// Start server
initAdmin().then(() => {
  app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 Mix Cotação Web rodando na porta ${port}`);
    console.log(`🖥️ Plataforma: Windows`);
    console.log(`🌐 Acesse: http://localhost:${port}`);
    console.log(`📁 Diretório: C:\\MixCotacao`);
  });
});
"@ | Out-File -FilePath "server\index.js" -Encoding UTF8

# 8. Instalar dependências
Write-Host "📦 Instalando dependências..." -ForegroundColor Blue
npm install

# 9. Criar arquivo de configuração PM2
@"
{
  "apps": [{
    "name": "mix-cotacao",
    "script": "server/index.js",
    "cwd": "C:/MixCotacao",
    "env": {
      "NODE_ENV": "production",
      "PORT": "3000"
    },
    "log_file": "C:/MixCotacao/logs/app.log",
    "out_file": "C:/MixCotacao/logs/out.log",
    "error_file": "C:/MixCotacao/logs/error.log",
    "restart_delay": 1000
  }]
}
"@ | Out-File -FilePath "ecosystem.config.json" -Encoding UTF8

# Criar diretório de logs
New-Item -ItemType Directory -Path "logs" -Force

# 10. Iniciar aplicação
Write-Host "🚀 Iniciando aplicação..." -ForegroundColor Blue
pm2 start ecosystem.config.json
pm2 save
pm2 startup

# 11. Configurar Windows Firewall
Write-Host "🔥 Configurando firewall..." -ForegroundColor Blue
try {
    New-NetFirewallRule -DisplayName "Mix Cotacao Web" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -ErrorAction SilentlyContinue
    Write-Host "✅ Regra de firewall criada" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Não foi possível configurar firewall automaticamente" -ForegroundColor Yellow
}

# 12. Criar atalhos
Write-Host "🔗 Criando atalhos..." -ForegroundColor Blue

# Atalho na área de trabalho
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Mix Cotacao Web.lnk")
$Shortcut.TargetPath = "http://localhost:3000"
$Shortcut.Save()

# Script para gerenciar a aplicação
@"
@echo off
echo Mix Cotacao Web - Gerenciamento
echo ==============================
echo.
echo 1. Status
echo 2. Iniciar
echo 3. Parar  
echo 4. Reiniciar
echo 5. Logs
echo 6. Abrir no navegador
echo 7. Sair
echo.
set /p choice=Escolha uma opcao (1-7): 

if "%choice%"=="1" pm2 status
if "%choice%"=="2" pm2 start mix-cotacao
if "%choice%"=="3" pm2 stop mix-cotacao
if "%choice%"=="4" pm2 restart mix-cotacao
if "%choice%"=="5" pm2 logs mix-cotacao --lines 50
if "%choice%"=="6" start http://localhost:3000
if "%choice%"=="7" exit

pause
goto :eof
"@ | Out-File -FilePath "gerenciar.bat" -Encoding ASCII

# 13. Teste final
Write-Host "🧪 Testando instalação..." -ForegroundColor Blue
Start-Sleep -Seconds 15

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 10
    $healthStatus = "✅ OK"
} catch {
    $healthStatus = "❌ Erro"
}

# 14. Resultado final
Write-Host ""
Write-Host "🎉 INSTALAÇÃO CONCLUÍDA!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Acesso:" -ForegroundColor White
Write-Host "   URL: http://localhost:3000" -ForegroundColor Cyan
Write-Host "   Status: $healthStatus" -ForegroundColor $(if($healthStatus -eq "✅ OK"){"Green"}else{"Red"})
Write-Host ""
Write-Host "🔑 Login:" -ForegroundColor White
Write-Host "   Email: administrador@softsan.com.br" -ForegroundColor Yellow
Write-Host "   Senha: M1xgestao@2025" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚙️ Gerenciamento:" -ForegroundColor White
Write-Host "   Arquivo: C:\MixCotacao\gerenciar.bat" -ForegroundColor Cyan
Write-Host "   Status: pm2 status" -ForegroundColor Gray
Write-Host "   Logs: pm2 logs mix-cotacao" -ForegroundColor Gray
Write-Host ""
Write-Host "📁 Arquivos:" -ForegroundColor White
Write-Host "   App: C:\MixCotacao" -ForegroundColor Cyan
Write-Host "   Logs: C:\MixCotacao\logs" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔗 Atalhos criados:" -ForegroundColor White
Write-Host "   Desktop: Mix Cotacao Web.lnk" -ForegroundColor Cyan
Write-Host ""

if ($healthStatus -eq "✅ OK") {
    Write-Host "✅ Sistema funcionando!" -ForegroundColor Green
    Write-Host "🌐 Abrindo navegador..." -ForegroundColor Blue
    Start-Process "http://localhost:3000"
} else {
    Write-Host "⚠️ Verificar logs:" -ForegroundColor Yellow
    Write-Host "   pm2 logs mix-cotacao --lines 20" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")