# Mix Cotação Web - Guia de Deploy

## Problema Resolvido: Driver de Banco

**Situação anterior:** Aplicação configurada com driver Neon (`@neondatabase/serverless`)
**Problema:** Conflitos SSL ao usar PostgreSQL local na AWS
**Solução:** Migração para driver pg padrão (`pg` + `drizzle-orm/node-postgres`)

## Arquivos Importantes

### Configuração Corrigida
- `server/db.ts` - Driver pg configurado para PostgreSQL local
- `fix-postgresql-driver.sh` - Script de migração automatizada
- `aws-emergency-fix.sh` - Correção completa de build ESM

### Configuração de Ambiente
```env
# Para PostgreSQL Local (AWS Lightsail)
DATABASE_URL=postgresql://mixuser:senha@localhost:5432/mixcotacao
NODE_ENV=production
PORT=5000
SESSION_SECRET=chave_secreta_longa
```

## Deploy na AWS

### Correção Rápida
```bash
./fix-postgresql-driver.sh
```

### Passos Manuais
1. Instalar driver correto: `npm install pg @types/pg`
2. Remover Neon: `npm uninstall @neondatabase/serverless`
3. Rebuild: `npm run build`
4. Configurar .env para PostgreSQL local
5. Reiniciar: `pm2 restart mix-cotacao-web`

## Estrutura de Banco

- **Tabelas:** sellers, quotations, quotation_items, api_keys
- **Schema:** `mix_cotacao_schema.sql` (criação completa)
- **Admin:** administrador@softsan.com.br / M1xgestao@2025

## Scripts de Diagnóstico

- `check-aws-environment.sh` - Verificação completa
- `diagnose-production.js` - Análise de configuração
- `fix-env-variables.sh` - Correção de variáveis

## Status Atual

✓ Driver PostgreSQL local configurado
✓ Build ESM corrigido
✓ Variáveis de ambiente carregadas via dotenv
✓ Scripts de correção automática criados
✓ Documentação de troubleshooting completa