# Mix Cotação Web - Guia de Hospedagem na AWS

## Opções de Arquitetura

### Opção 1: EC2 + RDS (Recomendada para Produção)

**Componentes:**
- **EC2**: Servidor da aplicação
- **RDS PostgreSQL**: Banco de dados gerenciado
- **Application Load Balancer**: Distribuição de carga
- **Route 53**: DNS personalizado
- **Certificate Manager**: SSL/TLS

**Custos estimados:** $50-150/mês dependendo do tráfego

### Opção 2: Elastic Beanstalk (Mais Simples)

**Componentes:**
- **Elastic Beanstalk**: Plataforma gerenciada para Node.js
- **RDS PostgreSQL**: Banco integrado
- **Load Balancer automático**
- **Auto Scaling configurado**

**Custos estimados:** $40-100/mês

### Opção 3: ECS Fargate (Containerizada)

**Componentes:**
- **ECS Fargate**: Containers serverless
- **RDS PostgreSQL**: Banco gerenciado
- **Application Load Balancer**
- **ECR**: Registry de containers

**Custos estimados:** $30-80/mês

## Implementação Detalhada - Opção 1 (EC2 + RDS)

### Passo 1: Configurar RDS PostgreSQL

1. **Criar instância RDS:**
```bash
# Via AWS CLI
aws rds create-db-instance \
    --db-instance-identifier mix-cotacao-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 15.4 \
    --master-username mixadmin \
    --master-user-password SuaSenhaSegura123! \
    --allocated-storage 20 \
    --vpc-security-group-ids sg-xxxxxxxxx \
    --db-subnet-group-name default-vpc-xxxxxxxx \
    --backup-retention-period 7 \
    --storage-encrypted \
    --publicly-accessible
```

2. **Configurar Security Group para RDS:**
```bash
# Permitir acesso PostgreSQL (porta 5432) apenas do EC2
aws ec2 authorize-security-group-ingress \
    --group-id sg-rds-group \
    --protocol tcp \
    --port 5432 \
    --source-group sg-ec2-group
```

3. **Executar script de setup:**
```bash
# Conectar ao RDS e executar database_setup.sql
psql -h mix-cotacao-db.xxxxxxxxx.us-east-1.rds.amazonaws.com \
     -U mixadmin -d postgres -f database_setup.sql
```

### Passo 2: Configurar EC2

1. **Lançar instância EC2:**
```bash
# Amazon Linux 2023 com Node.js
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --count 1 \
    --instance-type t3.small \
    --key-name sua-chave-ssh \
    --security-group-ids sg-ec2-group \
    --subnet-id subnet-xxxxxxxxx \
    --user-data file://user-data.sh
```

2. **Script de inicialização (user-data.sh):**
```bash
#!/bin/bash
yum update -y
yum install -y nodejs npm git

# Instalar PM2 para gerenciar processos
npm install -g pm2

# Criar usuário para aplicação
useradd -m mixapp
su - mixapp

# Clonar aplicação (substitua pela sua fonte)
git clone https://github.com/seu-usuario/mix-cotacao-web.git
cd mix-cotacao-web

# Instalar dependências
npm install

# Configurar variáveis de ambiente
cat > .env << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://mixadmin:SuaSenhaSegura123!@mix-cotacao-db.xxxxxxxxx.us-east-1.rds.amazonaws.com:5432/postgres
SESSION_SECRET=sua-chave-secreta-super-forte-para-producao
EOF

# Build da aplicação
npm run build

# Iniciar com PM2
pm2 start npm --name "mix-cotacao" -- run start
pm2 startup
pm2 save
```

3. **Security Group para EC2:**
```bash
# HTTP (80)
aws ec2 authorize-security-group-ingress \
    --group-id sg-ec2-group \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# HTTPS (443)  
aws ec2 authorize-security-group-ingress \
    --group-id sg-ec2-group \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# SSH (22)
aws ec2 authorize-security-group-ingress \
    --group-id sg-ec2-group \
    --protocol tcp \
    --port 22 \
    --cidr SEU.IP.PUBLICO/32
```

### Passo 3: Configurar Load Balancer

1. **Criar Application Load Balancer:**
```bash
aws elbv2 create-load-balancer \
    --name mix-cotacao-alb \
    --subnets subnet-aaaaa subnet-bbbbb \
    --security-groups sg-alb-group \
    --scheme internet-facing \
    --type application
```

2. **Criar Target Group:**
```bash
aws elbv2 create-target-group \
    --name mix-cotacao-targets \
    --protocol HTTP \
    --port 3000 \
    --vpc-id vpc-xxxxxxxxx \
    --health-check-path /api/health \
    --health-check-interval-seconds 30
```

3. **Registrar instância EC2:**
```bash
aws elbv2 register-targets \
    --target-group-arn arn:aws:elasticloadbalancing:... \
    --targets Id=i-xxxxxxxxx,Port=3000
```

### Passo 4: Configurar HTTPS

1. **Solicitar certificado SSL:**
```bash
aws acm request-certificate \
    --domain-name mixcotacao.seudominio.com.br \
    --subject-alternative-names www.mixcotacao.seudominio.com.br \
    --validation-method DNS
```

2. **Configurar listener HTTPS:**
```bash
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:... \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:... \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...
```

### Passo 5: Configurar DNS

1. **Criar hosted zone (Route 53):**
```bash
aws route53 create-hosted-zone \
    --name seudominio.com.br \
    --caller-reference $(date +%s)
```

2. **Criar registro A para o domínio:**
```json
{
    "Changes": [{
        "Action": "CREATE",
        "ResourceRecordSet": {
            "Name": "mixcotacao.seudominio.com.br",
            "Type": "A",
            "AliasTarget": {
                "DNSName": "alb-xxxxxxxxx.us-east-1.elb.amazonaws.com",
                "EvaluateTargetHealth": false,
                "HostedZoneId": "Z35SXDOTRQ7X7K"
            }
        }
    }]
}
```

## Implementação Simplificada - Elastic Beanstalk

### Passo 1: Preparar Aplicação

1. **Criar arquivo de configuração (.ebextensions/01-environment.config):**
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    NODE_ENV: production
    SESSION_SECRET: sua-chave-secreta-producao
    DATABASE_URL: postgresql://usuario:senha@endpoint:5432/database
  aws:elasticbeanstalk:container:nodejs:
    NodeCommand: "npm start"
    NodeVersion: 18.17.0
```

2. **Atualizar package.json:**
```json
{
  "scripts": {
    "start": "NODE_ENV=production tsx server/index.ts",
    "dev": "NODE_ENV=development tsx server/index.ts"
  }
}
```

### Passo 2: Deploy

1. **Instalar EB CLI:**
```bash
pip install awsebcli
```

2. **Inicializar aplicação:**
```bash
eb init mix-cotacao-web
# Selecionar região: us-east-1
# Selecionar plataforma: Node.js
```

3. **Criar ambiente:**
```bash
eb create production
```

4. **Deploy da aplicação:**
```bash
eb deploy
```

## Implementação com Docker - ECS Fargate

### Passo 1: Criar Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copiar package files
COPY package*.json ./
RUN npm ci --only=production

# Copiar código fonte
COPY . .

# Build da aplicação
RUN npm run build

# Expor porta
EXPOSE 3000

# Comando de inicialização
CMD ["npm", "start"]
```

### Passo 2: Configurar ECS

1. **Criar cluster ECS:**
```bash
aws ecs create-cluster \
    --cluster-name mix-cotacao-cluster \
    --capacity-providers FARGATE
```

2. **Definir task definition:**
```json
{
    "family": "mix-cotacao-task",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "mix-cotacao-container",
            "image": "account.dkr.ecr.region.amazonaws.com/mix-cotacao:latest",
            "portMappings": [
                {
                    "containerPort": 3000,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "name": "NODE_ENV",
                    "value": "production"
                },
                {
                    "name": "DATABASE_URL",
                    "value": "postgresql://..."
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/mix-cotacao",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
```

## Configurações de Segurança

### 1. Security Groups
```bash
# Web tier (ALB)
aws ec2 create-security-group \
    --group-name mix-cotacao-web-sg \
    --description "Security group para web tier"

# App tier (EC2/ECS)
aws ec2 create-security-group \
    --group-name mix-cotacao-app-sg \
    --description "Security group para application tier"

# Database tier (RDS)
aws ec2 create-security-group \
    --group-name mix-cotacao-db-sg \
    --description "Security group para database tier"
```

### 2. IAM Roles
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBInstances",
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. Secrets Manager (Recomendado)
```bash
# Armazenar credenciais do banco
aws secretsmanager create-secret \
    --name mix-cotacao/database \
    --description "Database credentials" \
    --secret-string '{"username":"mixadmin","password":"SuaSenhaSegura123!"}'
```

## Monitoramento e Logs

### 1. CloudWatch
```bash
# Criar grupo de logs
aws logs create-log-group --log-group-name /aws/ec2/mix-cotacao

# Configurar alarmes
aws cloudwatch put-metric-alarm \
    --alarm-name "mix-cotacao-high-cpu" \
    --alarm-description "High CPU utilization" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold
```

### 2. Health Checks
Adicionar endpoint de saúde na aplicação:

```javascript
// server/routes.ts
app.get('/api/health', async (req, res) => {
  try {
    // Verificar conexão com banco
    await db.select().from(sellers).limit(1);
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
```

## Backup e Recuperação

### 1. Backup Automático RDS
```bash
aws rds modify-db-instance \
    --db-instance-identifier mix-cotacao-db \
    --backup-retention-period 30 \
    --backup-window "03:00-04:00" \
    --maintenance-window "sun:04:00-sun:05:00"
```

### 2. Snapshot Manual
```bash
aws rds create-db-snapshot \
    --db-instance-identifier mix-cotacao-db \
    --db-snapshot-identifier mix-cotacao-backup-$(date +%Y%m%d)
```

## Custos Estimados (Mensais)

### Configuração Básica:
- **EC2 t3.small:** $15-20
- **RDS db.t3.micro:** $15-25  
- **Load Balancer:** $16
- **Route 53:** $0.50
- **Data Transfer:** $5-15
- **Total:** ~$50-75/mês

### Configuração Otimizada:
- **EC2 t3.medium:** $30-40
- **RDS db.t3.small:** $25-35
- **Load Balancer:** $16
- **CloudWatch:** $5-10
- **Backup/Storage:** $5-10
- **Total:** ~$80-115/mês

## Scripts de Automação

### Deploy Script
```bash
#!/bin/bash
# deploy.sh

echo "Deploying Mix Cotação Web to AWS..."

# Build da aplicação
npm run build

# Deploy via Elastic Beanstalk
eb deploy production

# Verificar health
sleep 30
curl -f https://mixcotacao.seudominio.com.br/api/health

echo "Deploy completed successfully!"
```

### Backup Script
```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)

# Criar snapshot RDS
aws rds create-db-snapshot \
    --db-instance-identifier mix-cotacao-db \
    --db-snapshot-identifier "mix-cotacao-backup-$DATE"

echo "Backup created: mix-cotacao-backup-$DATE"
```

## Próximos Passos

1. **Escolher arquitetura** baseada no orçamento e requisitos
2. **Configurar RDS** com o script database_setup.sql
3. **Deploy da aplicação** seguindo uma das opções
4. **Configurar domínio** e certificado SSL
5. **Implementar monitoramento** e alertas
6. **Testar backup/recovery** procedures

**Sistema pronto para produção na AWS!**