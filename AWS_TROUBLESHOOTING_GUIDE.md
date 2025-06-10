# Mix Cotação Web - Guia de Solução de Problemas AWS

## Erro 500 no Login - Diagnóstico e Soluções

### Causas Mais Comuns

**1. Problema na Conexão com Banco de Dados**
```bash
# Verificar se o RDS está acessível
psql -h seu-endpoint-rds.amazonaws.com -U mixadmin -d mixcotacao -c "SELECT 1;"
```

**2. Tabelas Não Criadas**
```bash
# Executar o script de setup
psql -h seu-endpoint-rds.amazonaws.com -U mixadmin -d mixcotacao -f database_setup.sql
```

**3. Security Groups Incorretos**
- RDS deve permitir porta 5432 do Security Group da aplicação
- EC2 deve ter acesso de saída para porta 5432

**4. Variáveis de Ambiente Não Configuradas**
```bash
# Verificar no servidor EC2
echo $DATABASE_URL
echo $SESSION_SECRET
```

### Passo a Passo para Diagnóstico

**Acesse seu servidor EC2 via SSH:**
```bash
ssh -i sua-chave.pem ec2-user@seu-ip-ec2
```

**Execute o diagnóstico:**
```bash
# No servidor EC2
cd /opt/mixcotacao
node aws-debug.js
```

**Verifique os logs da aplicação:**
```bash
# Logs PM2
tail -f /home/mixapp/.pm2/logs/mix-cotacao-error.log
tail -f /home/mixapp/.pm2/logs/mix-cotacao-out.log

# Logs nginx
tail -f /var/log/nginx/mixcotacao.error.log
```

**Teste o endpoint de saúde:**
```bash
curl http://localhost:3000/api/health
```

### Soluções Específicas

**Se DATABASE_URL não estiver configurado:**
```bash
# Editar variáveis de ambiente
sudo nano /opt/mixcotacao/.env

# Adicionar:
DATABASE_URL=postgresql://mixadmin:senha@endpoint:5432/mixcotacao
SESSION_SECRET=sua-chave-secreta

# Reiniciar aplicação
sudo -u mixapp pm2 restart mix-cotacao
```

**Se o banco não tiver tabelas:**
```bash
# Conectar ao RDS
psql -h seu-endpoint.rds.amazonaws.com -U mixadmin -d mixcotacao

# Executar script de setup
\i database_setup.sql
\q
```

**Se Security Groups estiverem bloqueando:**
```bash
# Via AWS CLI - permitir acesso do EC2 ao RDS
aws ec2 authorize-security-group-ingress \
    --group-id sg-rds-id \
    --protocol tcp \
    --port 5432 \
    --source-group sg-ec2-id
```

**Se o usuário administrador não existir:**
```bash
# No servidor EC2
cd /opt/mixcotacao
node -e "
import bcrypt from 'bcrypt';
import { Pool } from '@neondatabase/serverless';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const hash = await bcrypt.hash('M1xgestao@2025', 10);

await pool.query(
  'INSERT INTO sellers (email, name, password, status) VALUES ($1, $2, $3, $4)',
  ['administrador@softsan.com.br', 'Administrador', hash, 'Ativo']
);

console.log('Admin criado com sucesso');
await pool.end();
"
```

### Comandos de Verificação Rápida

**Status dos serviços:**
```bash
# PM2
sudo -u mixapp pm2 status

# Nginx
sudo systemctl status nginx

# Conectividade do banco
nc -zv seu-endpoint-rds.amazonaws.com 5432
```

**Reiniciar serviços:**
```bash
# Aplicação
sudo -u mixapp pm2 restart mix-cotacao

# Nginx
sudo systemctl restart nginx

# Forçar reload completo
sudo -u mixapp pm2 delete mix-cotacao
sudo -u mixapp pm2 start npm --name "mix-cotacao" -- start
```

**Logs em tempo real:**
```bash
# Todos os logs PM2
sudo -u mixapp pm2 logs mix-cotacao

# Apenas erros
sudo -u mixapp pm2 logs mix-cotacao --err

# Logs nginx
sudo tail -f /var/log/nginx/mixcotacao.error.log
```

### Checklist de Verificação

- [ ] DATABASE_URL configurado corretamente
- [ ] RDS acessível pela aplicação
- [ ] Tabelas criadas no banco de dados
- [ ] Usuário administrador existe
- [ ] Security Groups permitem comunicação
- [ ] PM2 executando a aplicação
- [ ] Nginx redirecionando corretamente
- [ ] Endpoint /api/health retorna status 200
- [ ] Logs não mostram erros críticos

### URLs para Teste

```bash
# Health check
curl http://seu-ip-ec2/api/health

# Teste de login
curl -X POST http://seu-ip-ec2/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"administrador@softsan.com.br","password":"M1xgestao@2025"}'

# Lista de vendedores (após login)
curl http://seu-ip-ec2/api/sellers \
  -H "Cookie: connect.sid=valor-do-cookie"
```

### Problemas Específicos e Soluções

**Erro: "Connection refused"**
- Security Group não permite conexão
- RDS não está rodando
- Endpoint incorreto

**Erro: "Authentication failed"**
- Credenciais do banco incorretas
- Usuário não tem permissões
- Senha foi alterada

**Erro: "Relation does not exist"**
- Tabelas não foram criadas
- Banco de dados incorreto
- Schema não encontrado

**Erro: "Session store not available"**
- SESSION_SECRET não configurado
- Problema com store de sessão
- Memória insuficiente

### Monitoramento Contínuo

**CloudWatch Logs:**
```bash
# Instalar agente se não instalado
sudo yum install -y amazon-cloudwatch-agent

# Configurar logs
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s -c file:///opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

**Alertas automáticos:**
```bash
# Criar alarme para CPU alta
aws cloudwatch put-metric-alarm \
    --alarm-name "EC2-HighCPU" \
    --alarm-description "EC2 high CPU" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0
```

**Script de monitoramento:**
```bash
#!/bin/bash
# Salvar como /opt/mixcotacao/monitor.sh

while true; do
    if ! curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "$(date): Health check failed, restarting application"
        sudo -u mixapp pm2 restart mix-cotacao
        sleep 30
    fi
    sleep 60
done
```

### Contato e Suporte

Se os problemas persistirem após seguir este guia:

1. Colete os logs completos
2. Execute o diagnóstico aws-debug.js
3. Verifique a configuração de rede AWS
4. Confirme que o RDS está funcionando independentemente

O sistema está configurado para log detalhado, então a causa específica do erro 500 aparecerá nos logs da aplicação.