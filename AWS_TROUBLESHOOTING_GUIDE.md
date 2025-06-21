# Guia de Solução de Problemas - AWS Lightsail

## Problema: Erro de Certificado SSL
```
Error: Hostname/IP does not match certificate's altnames: Host: localhost. is not in the cert's altnames
```

### Causa
A aplicação está configurada para usar Neon Database (cloud), mas o `DATABASE_URL` está apontando para `localhost`, causando conflito de certificado SSL.

### Soluções

#### Solução 1: PostgreSQL Local (Recomendado para Lightsail)
```bash
# 1. Execute o script de correção
./fix-production-database.sh

# 2. Configure manualmente se necessário
nano .env
# Altere para:
DATABASE_URL=postgresql://mixuser:sua_senha@localhost:5432/mixcotacao
PGHOST=localhost
PGUSER=mixuser
PGPASSWORD=sua_senha
PGDATABASE=mixcotacao
PGPORT=5432

# 3. Reinicie a aplicação
pm2 restart mix-cotacao-web
```

#### Solução 2: Corrigir URL do Neon Database
```bash
# 1. Acesse o painel Neon Database
# 2. Copie a CONNECTION STRING correta
# 3. Execute:
nano .env
# Altere DATABASE_URL para a URL correta do Neon

# 4. Reinicie
pm2 restart mix-cotacao-web
```

### Verificação Rápida
```bash
# Diagnosticar problemas
node diagnose-production.js

# Ver logs
pm2 logs mix-cotacao-web

# Testar conexão
curl http://localhost:5000/api/health
```

## Outros Problemas Comuns

### Aplicação não inicia
```bash
# Verificar status
pm2 status

# Ver logs detalhados
pm2 logs mix-cotacao-web --lines 50

# Reiniciar
pm2 restart mix-cotacao-web
```

### Banco não conecta
```bash
# Testar PostgreSQL local
psql -U mixuser -d mixcotacao -h localhost

# Verificar serviço
sudo systemctl status postgresql

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### Nginx não responde
```bash
# Verificar configuração
sudo nginx -t

# Ver logs
sudo tail -f /var/log/nginx/error.log

# Reiniciar
sudo systemctl restart nginx
```

### Comandos de Emergência
```bash
# Parar tudo
pm2 stop all
sudo systemctl stop nginx

# Iniciar tudo
sudo systemctl start nginx
pm2 start ecosystem.config.js

# Verificar portas
sudo netstat -tlnp | grep :5000
sudo netstat -tlnp | grep :80
```