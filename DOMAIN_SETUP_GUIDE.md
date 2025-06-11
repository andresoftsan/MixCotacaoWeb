# Configuração de Domínio Próprio - Mix Cotação Web

## Opções de Hospedagem com Domínio Próprio

### 1. Servidor VPS/Dedicado (AWS, DigitalOcean, etc.)

#### Pré-requisitos
- Domínio registrado (ex: exemplo.com.br)
- Servidor com IP público fixo
- Sistema já instalado no servidor

#### Configuração DNS
```dns
# Registrar no provedor de DNS (Registro.br, Cloudflare, etc.)
Tipo: A
Nome: mixcotacao (ou @)
Valor: SEU-IP-PUBLICO
TTL: 300

# Para subdominío
Tipo: CNAME  
Nome: sistema
Valor: mixcotacao.exemplo.com.br
```

#### Configurar Nginx (Linux)
```nginx
# /etc/nginx/conf.d/mixcotacao.conf
server {
    listen 80;
    server_name mixcotacao.exemplo.com.br www.mixcotacao.exemplo.com.br;
    
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
```

#### Configurar HTTPS com Certbot
```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d mixcotacao.exemplo.com.br

# Auto-renovação
sudo crontab -e
# Adicionar: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. Cloudflare (Recomendado)

#### Vantagens
- SSL gratuito
- CDN global
- Proteção DDoS
- Cache automático
- Dashboard simples

#### Configuração
1. **Adicionar site no Cloudflare**
   - Acessar dashboard.cloudflare.com
   - Adicionar seu domínio
   - Alterar nameservers no registrador

2. **Configurar DNS**
   ```
   Tipo: A
   Nome: mixcotacao
   Valor: IP-DO-SERVIDOR
   Proxy: Ativado (nuvem laranja)
   ```

3. **Configurar SSL**
   - SSL/TLS → Visão geral
   - Modo: "Full (strict)"

4. **Regras de página (opcional)**
   - Cache: "Cache Everything"
   - Browser TTL: 1 hora

### 3. Windows Server + IIS

#### Instalar IIS
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
```

#### Configurar Proxy Reverso
1. Instalar URL Rewrite e Application Request Routing
2. Criar site no IIS:
   ```
   Nome: Mix Cotacao Web
   Caminho físico: C:\inetpub\wwwroot\mixcotacao
   Binding: HTTP, porta 80, hostname: mixcotacao.exemplo.com.br
   ```

3. Configurar web.config:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <configuration>
     <system.webServer>
       <rewrite>
         <rules>
           <rule name="NodeJS" stopProcessing="true">
             <match url=".*" />
             <action type="Rewrite" url="http://localhost:3000/{R:0}" />
           </rule>
         </rules>
       </rewrite>
     </system.webServer>
   </configuration>
   ```

### 4. Domínio .com.br (Registro.br)

#### Registro do Domínio
1. Acessar registro.br
2. Verificar disponibilidade
3. Registrar domínio
4. Aguardar aprovação (24-48h)

#### Configurar DNS
```dns
# No painel do Registro.br ou provedor DNS
Tipo: A
Nome: mixcotacao
Conteúdo: IP-DO-SERVIDOR
TTL: 300

# Alternativas
sistema.exemplo.com.br → IP-DO-SERVIDOR
cotacao.exemplo.com.br → IP-DO-SERVIDOR
```

## Configuração Específica por Ambiente

### AWS EC2 com Route 53
```bash
# 1. Registrar domínio no Route 53 ou transferir
# 2. Criar Hosted Zone
# 3. Configurar record A
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "mixcotacao.exemplo.com.br",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "SEU-IP-EC2"}]
      }
    }]
  }'
```

### Servidor Local + DDNS
Se o servidor está em casa/escritório:

1. **No-IP ou DynDNS**
   - Criar conta gratuita
   - Configurar hostname: mixcotacao.ddns.net
   - Instalar cliente no servidor

2. **Configurar roteador**
   - Port forwarding: 80 → IP-LOCAL:3000
   - Port forwarding: 443 → IP-LOCAL:3000

### Azure Web Apps
```bash
# Configurar domínio customizado
az webapp config hostname add \
  --webapp-name mix-cotacao \
  --resource-group meu-grupo \
  --hostname mixcotacao.exemplo.com.br
```

## Configurações da Aplicação

### Atualizar URLs na Aplicação
```javascript
// No código da aplicação, se necessário
const baseURL = process.env.NODE_ENV === 'production' 
  ? 'https://mixcotacao.exemplo.com.br'
  : 'http://localhost:3000';
```

### Variáveis de Ambiente
```bash
# .env
DOMAIN=mixcotacao.exemplo.com.br
BASE_URL=https://mixcotacao.exemplo.com.br
ALLOWED_ORIGINS=https://mixcotacao.exemplo.com.br,https://www.mixcotacao.exemplo.com.br
```

### Session Configuration
```javascript
// Para HTTPS
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: process.env.NODE_ENV === 'production', // HTTPS em produção
    maxAge: 24 * 60 * 60 * 1000,
    domain: process.env.NODE_ENV === 'production' ? '.exemplo.com.br' : undefined
  }
}));
```

## Verificação e Testes

### Testar DNS
```bash
# Verificar propagação DNS
nslookup mixcotacao.exemplo.com.br
dig mixcotacao.exemplo.com.br

# Testar conectividade
curl -I http://mixcotacao.exemplo.com.br
```

### Testar SSL
```bash
# Verificar certificado
openssl s_client -connect mixcotacao.exemplo.com.br:443

# Teste online
# https://www.ssllabs.com/ssltest/
```

## Custos Estimados

### Domínio .com.br
- Registro: R$ 40/ano
- Renovação: R$ 40/ano

### Cloudflare
- Gratuito: SSL + CDN básico
- Pro ($20/mês): Analytics avançado
- Business ($200/mês): WAF avançado

### Certificado SSL
- Let's Encrypt: Gratuito
- Certificado pago: R$ 200-500/ano

## Exemplo Completo

### Cenário: Empresa com domínio mixcotacao.com.br

1. **DNS Configuration**
   ```
   mixcotacao.com.br → 203.0.113.10
   www.mixcotacao.com.br → 203.0.113.10
   ```

2. **Nginx Configuration**
   ```nginx
   server {
       listen 80;
       server_name mixcotacao.com.br www.mixcotacao.com.br;
       return 301 https://$server_name$request_uri;
   }
   
   server {
       listen 443 ssl http2;
       server_name mixcotacao.com.br www.mixcotacao.com.br;
       
       ssl_certificate /etc/letsencrypt/live/mixcotacao.com.br/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/mixcotacao.com.br/privkey.pem;
       
       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

3. **Application Update**
   ```javascript
   // server/index.js
   const allowedOrigins = [
     'https://mixcotacao.com.br',
     'https://www.mixcotacao.com.br'
   ];
   
   app.use((req, res, next) => {
     const origin = req.headers.origin;
     if (allowedOrigins.includes(origin)) {
       res.setHeader('Access-Control-Allow-Origin', origin);
     }
     next();
   });
   ```

## Checklist Final

- [ ] Domínio registrado e configurado
- [ ] DNS apontando para o servidor
- [ ] Nginx/IIS configurado
- [ ] SSL instalado e funcionando
- [ ] Firewall liberado (portas 80, 443)
- [ ] Aplicação testada no novo domínio
- [ ] Redirecionamento HTTP → HTTPS
- [ ] Backup do sistema funcionando
- [ ] Monitoramento configurado

Após seguir estes passos, o sistema estará acessível através do seu domínio próprio com SSL e performance otimizada.