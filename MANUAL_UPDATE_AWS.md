# Manual de Atualização AWS - Sistema Mix Cotação Web

## Resumo das Mudanças a Serem Aplicadas

Esta atualização implementa o **bloqueio de edição para cotações com status "Prazo Encerrado"**, fazendo com que comportem-se igual às cotações "Enviadas" - sem possibilidade de edição.

### Arquivos Modificados:
- `client/src/pages/quotation-edit.tsx`
- `client/src/components/quotation-detail-modal.tsx`
- `replit.md` (documentação)
- `BLOQUEIO_EDICAO_IMPLEMENTADO.md` (novo arquivo de documentação)

## Processo de Atualização Manual no AWS

### 1. Fazer Backup do Sistema Atual

```bash
# Conectar ao servidor AWS
ssh ubuntu@SEU-IP-AWS

# Fazer backup da aplicação atual
sudo cp -r /home/ubuntu/mix-cotacao-web /home/ubuntu/mix-cotacao-web-backup-$(date +%Y%m%d)

# Fazer backup do banco de dados
sudo -u postgres pg_dump mix_cotacao > /home/ubuntu/backup-db-$(date +%Y%m%d).sql
```

### 2. Parar a Aplicação

```bash
# Parar o PM2
pm2 stop mix-cotacao-web

# Verificar se parou
pm2 list
```

### 3. Atualizar os Arquivos da Aplicação

Você tem duas opções:

#### Opção A: Upload Manual dos Arquivos (Recomendado)

1. **No seu computador local**, salve os arquivos modificados:

**Arquivo: `client/src/pages/quotation-edit.tsx`**
```typescript
// Na linha 368-369, certifique-se que tem o comentário:
// Bloquear edição quando status for "Enviada" ou "Prazo Encerrado"
const isEditable = quotation?.status === "Aguardando digitação";
```

**Arquivo: `client/src/components/quotation-detail-modal.tsx`**
- Todas as linhas com `disabled={quotation.status === "Enviada"}` 
- Devem ser alteradas para `disabled={quotation.status === "Enviada" || quotation.status === "Prazo Encerrado"}`

2. **Transferir para o servidor:**

```bash
# No seu computador, copie os arquivos via SCP
scp client/src/pages/quotation-edit.tsx ubuntu@SEU-IP-AWS:/home/ubuntu/mix-cotacao-web/client/src/pages/
scp client/src/components/quotation-detail-modal.tsx ubuntu@SEU-IP-AWS:/home/ubuntu/mix-cotacao-web/client/src/components/
```

#### Opção B: Editar Diretamente no Servidor

```bash
# Conectar ao servidor
ssh ubuntu@SEU-IP-AWS

# Navegar para o diretório da aplicação  
cd /home/ubuntu/mix-cotacao-web

# Editar o arquivo quotation-edit.tsx
nano client/src/pages/quotation-edit.tsx
# Localize a linha ~368 e certifique-se que está:
# const isEditable = quotation?.status === "Aguardando digitação";

# Editar o arquivo quotation-detail-modal.tsx
nano client/src/components/quotation-detail-modal.tsx
# Substitua todas as ocorrências de:
# disabled={quotation.status === "Enviada"}
# Por:
# disabled={quotation.status === "Enviada" || quotation.status === "Prazo Encerrado"}
```

### 4. Reconstruir a Aplicação

```bash
# No servidor AWS, dentro da pasta da aplicação
cd /home/ubuntu/mix-cotacao-web

# Reinstalar dependências (caso necessário)
npm install

# Fazer build da aplicação
npm run build

# Verificar se o build foi bem-sucedido
ls -la dist/
```

### 5. Reiniciar a Aplicação

```bash
# Reiniciar com PM2
pm2 start ecosystem.config.js --env production

# Ou se não tiver ecosystem.config.js:
pm2 start dist/index.js --name "mix-cotacao-web"

# Verificar se está rodando
pm2 list
pm2 logs mix-cotacao-web

# Salvar configuração PM2
pm2 save
```

### 6. Verificar Funcionamento

```bash
# Testar se a aplicação está respondendo
curl http://localhost:5000

# Verificar logs em tempo real
pm2 logs mix-cotacao-web --lines 50
```

### 7. Teste da Nova Funcionalidade

1. **Acesse a aplicação:** `http://SEU-IP-AWS` 
2. **Faça login** com suas credenciais
3. **Teste com uma cotação "Prazo Encerrado":**
   - Vá em Cotações
   - Abra uma cotação com status "Prazo Encerrado"
   - Verifique que os campos estão bloqueados (não editáveis)
   - Verifique que os botões "Salvar" e "Enviar" estão desabilitados

## Solução de Problemas

### Se a aplicação não iniciar:

```bash
# Verificar logs de erro
pm2 logs mix-cotacao-web

# Verificar se a porta está em uso
sudo netstat -tlnp | grep :5000

# Se necessário, matar processos na porta
sudo fuser -k 5000/tcp
```

### Se o build falhar:

```bash
# Limpar cache
rm -rf node_modules package-lock.json
npm install

# Verificar se Node.js está na versão correta
node --version  # Deve ser v20.x

# Tentar build novamente
npm run build
```

### Se houver erro de banco de dados:

```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql

# Reiniciar PostgreSQL se necessário
sudo systemctl restart postgresql

# Testar conexão com banco
sudo -u postgres psql -c "SELECT version();"
```

## Rollback (Em Caso de Problema)

Se algo der errado, você pode voltar à versão anterior:

```bash
# Parar aplicação atual
pm2 stop mix-cotacao-web

# Restaurar backup
sudo rm -rf /home/ubuntu/mix-cotacao-web
sudo mv /home/ubuntu/mix-cotacao-web-backup-YYYYMMDD /home/ubuntu/mix-cotacao-web

# Reiniciar aplicação
cd /home/ubuntu/mix-cotacao-web
pm2 start dist/index.js --name "mix-cotacao-web"
```

## Verificação Final

Após a atualização, confirme que:

✅ Aplicação está rodando (`pm2 list`)  
✅ Logs não mostram erros (`pm2 logs`)  
✅ Site acessível via navegador  
✅ Login funciona normalmente  
✅ Cotações "Prazo Encerrado" não permitem edição  
✅ Cotações "Aguardando digitação" ainda permitem edição  

---

**Tempo estimado:** 15-30 minutos  
**Downtime:** ~5-10 minutos durante restart da aplicação

**Suporte:** Se encontrar problemas, verifique os logs com `pm2 logs mix-cotacao-web` e documente qualquer erro para diagnóstico.