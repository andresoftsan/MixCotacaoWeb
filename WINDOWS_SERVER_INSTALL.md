# Instalação Windows Server - Mix Cotação Web

## Requisitos
- Windows Server 2019/2022
- Node.js 20+
- PostgreSQL 15+
- IIS (opcional)

## Passos de Instalação

### 1. Instalar Node.js
```powershell
# Download e install Node.js 20 LTS
# https://nodejs.org/
```

### 2. Instalar PostgreSQL
```powershell
# Download PostgreSQL 15+
# Configurar usuário e banco como no Linux
```

### 3. Configurar Aplicação
```powershell
# Clone ou copie arquivos
cd C:\inetpub\wwwroot\mix-cotacao-web

# Instalar dependências
npm install

# Configurar .env
copy .env.example .env
# Editar com credenciais corretas

# Build
npm run build
```

### 4. Instalar PM2 Windows
```powershell
npm install -g pm2
npm install -g pm2-windows-startup
pm2-startup install
```

### 5. Iniciar Aplicação
```powershell
pm2 start ecosystem.config.js
pm2 save
```

### 6. Configurar IIS (Opcional)
- Instalar IIS
- Configurar proxy reverso para porta 5000
- Configurar SSL