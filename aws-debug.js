#!/usr/bin/env node
// Script de diagnóstico para AWS - Mix Cotação Web
// Execute: node aws-debug.js

import { Pool } from '@neondatabase/serverless';
import bcrypt from 'bcrypt';
import 'dotenv/config';

console.log('🔍 DIAGNÓSTICO AWS - Mix Cotação Web');
console.log('=====================================\n');

// 1. Verificar variáveis de ambiente
console.log('1. VARIÁVEIS DE AMBIENTE:');
console.log('NODE_ENV:', process.env.NODE_ENV || 'não definido');
console.log('PORT:', process.env.PORT || 'não definido');
console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'configurado ✓' : 'NÃO CONFIGURADO ❌');
console.log('SESSION_SECRET:', process.env.SESSION_SECRET ? 'configurado ✓' : 'NÃO CONFIGURADO ❌');

if (process.env.DATABASE_URL) {
  const dbUrl = new URL(process.env.DATABASE_URL);
  console.log('DB Host:', dbUrl.hostname);
  console.log('DB Port:', dbUrl.port);
  console.log('DB Name:', dbUrl.pathname.slice(1));
  console.log('DB User:', dbUrl.username);
}
console.log('');

// 2. Testar conexão com banco
console.log('2. TESTE DE CONEXÃO COM BANCO:');
if (!process.env.DATABASE_URL) {
  console.log('❌ DATABASE_URL não configurado!');
  console.log('Adicione a variável de ambiente DATABASE_URL com a string de conexão PostgreSQL.');
  process.exit(1);
}

let pool;
try {
  pool = new Pool({ connectionString: process.env.DATABASE_URL });
  console.log('Pool de conexões criado ✓');
  
  // Teste básico de conectividade
  const testResult = await pool.query('SELECT NOW() as current_time, version() as pg_version');
  console.log('Conexão testada com sucesso ✓');
  console.log('Horário do servidor:', testResult.rows[0].current_time);
  console.log('Versão PostgreSQL:', testResult.rows[0].pg_version.split(' ')[0]);
  
} catch (error) {
  console.log('❌ Erro na conexão:', error.message);
  console.log('Código do erro:', error.code);
  
  if (error.code === 'ENOTFOUND') {
    console.log('💡 Possível causa: Host do banco não encontrado. Verifique o endpoint RDS.');
  } else if (error.code === 'ECONNREFUSED') {
    console.log('💡 Possível causa: Conexão recusada. Verifique Security Groups e porta 5432.');
  } else if (error.code === '28P01') {
    console.log('💡 Possível causa: Credenciais inválidas. Verifique usuário e senha.');
  } else if (error.code === '3D000') {
    console.log('💡 Possível causa: Banco de dados não existe.');
  }
  
  process.exit(1);
}
console.log('');

// 3. Verificar estrutura das tabelas
console.log('3. VERIFICAÇÃO DE TABELAS:');
try {
  const tables = await pool.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name
  `);
  
  if (tables.rows.length === 0) {
    console.log('❌ Nenhuma tabela encontrada!');
    console.log('💡 Execute o script database_setup.sql no banco de dados.');
    process.exit(1);
  }
  
  console.log('Tabelas encontradas:');
  for (const table of tables.rows) {
    const count = await pool.query(`SELECT COUNT(*) FROM ${table.table_name}`);
    console.log(`- ${table.table_name}: ${count.rows[0].count} registros`);
  }
  
} catch (error) {
  console.log('❌ Erro ao verificar tabelas:', error.message);
  process.exit(1);
}
console.log('');

// 4. Verificar usuário administrador
console.log('4. VERIFICAÇÃO DO USUÁRIO ADMINISTRADOR:');
try {
  const adminCheck = await pool.query(
    'SELECT id, email, name, status FROM sellers WHERE email = $1',
    ['administrador@softsan.com.br']
  );
  
  if (adminCheck.rows.length === 0) {
    console.log('❌ Usuário administrador não encontrado!');
    console.log('Criando usuário administrador...');
    
    const hashedPassword = await bcrypt.hash('M1xgestao@2025', 10);
    const result = await pool.query(`
      INSERT INTO sellers (email, name, password, status) 
      VALUES ($1, $2, $3, $4) 
      RETURNING id, email, name
    `, ['administrador@softsan.com.br', 'Administrador', hashedPassword, 'Ativo']);
    
    console.log('✅ Usuário administrador criado:', result.rows[0]);
  } else {
    const admin = adminCheck.rows[0];
    console.log('✅ Usuário administrador encontrado:');
    console.log(`ID: ${admin.id}, Email: ${admin.email}, Status: ${admin.status}`);
    
    // Testar login
    console.log('Testando credenciais de login...');
    const passwordCheck = await pool.query('SELECT password FROM sellers WHERE email = $1', 
      ['administrador@softsan.com.br']);
    
    if (passwordCheck.rows.length > 0) {
      const isValid = await bcrypt.compare('M1xgestao@2025', passwordCheck.rows[0].password);
      if (isValid) {
        console.log('✅ Senha do administrador válida');
      } else {
        console.log('❌ Senha do administrador inválida!');
        console.log('💡 A senha pode ter sido alterada. Use a senha atual ou redefina.');
      }
    }
  }
  
} catch (error) {
  console.log('❌ Erro ao verificar administrador:', error.message);
  process.exit(1);
}
console.log('');

// 5. Testar operações CRUD básicas
console.log('5. TESTE DE OPERAÇÕES CRUD:');
try {
  // Teste SELECT
  const sellersCount = await pool.query('SELECT COUNT(*) FROM sellers');
  console.log('✅ SELECT testado - Total de vendedores:', sellersCount.rows[0].count);
  
  // Teste INSERT (vendedor temporário)
  const tempEmail = `test_${Date.now()}@temp.com`;
  const hashedTempPass = await bcrypt.hash('123456', 10);
  const insertResult = await pool.query(`
    INSERT INTO sellers (email, name, password, status) 
    VALUES ($1, $2, $3, $4) 
    RETURNING id
  `, [tempEmail, 'Teste Temporário', hashedTempPass, 'Ativo']);
  console.log('✅ INSERT testado - ID criado:', insertResult.rows[0].id);
  
  // Teste UPDATE
  await pool.query('UPDATE sellers SET name = $1 WHERE id = $2', 
    ['Teste Atualizado', insertResult.rows[0].id]);
  console.log('✅ UPDATE testado');
  
  // Teste DELETE (limpar registro temporário)
  await pool.query('DELETE FROM sellers WHERE id = $1', [insertResult.rows[0].id]);
  console.log('✅ DELETE testado');
  
} catch (error) {
  console.log('❌ Erro em operações CRUD:', error.message);
  process.exit(1);
}
console.log('');

// 6. Verificar dados de exemplo
console.log('6. VERIFICAÇÃO DE DADOS DE EXEMPLO:');
try {
  const quotationsCount = await pool.query('SELECT COUNT(*) FROM quotations');
  const itemsCount = await pool.query('SELECT COUNT(*) FROM quotation_items');
  
  console.log(`Cotações: ${quotationsCount.rows[0].count}`);
  console.log(`Itens de cotação: ${itemsCount.rows[0].count}`);
  
  if (quotationsCount.rows[0].count === '0') {
    console.log('⚠️  Nenhuma cotação de exemplo encontrada.');
    console.log('💡 Considere executar o script database_setup.sql para dados de teste.');
  } else {
    console.log('✅ Dados de exemplo encontrados');
  }
  
} catch (error) {
  console.log('❌ Erro ao verificar dados:', error.message);
}
console.log('');

// 7. Teste de sessão/cookie (simulação)
console.log('7. CONFIGURAÇÃO DE SESSÃO:');
if (!process.env.SESSION_SECRET) {
  console.log('⚠️  SESSION_SECRET não configurado. Usando padrão (não recomendado para produção)');
} else {
  console.log('✅ SESSION_SECRET configurado');
}
console.log('');

// 8. Resumo e recomendações
console.log('8. RESUMO E RECOMENDAÇÕES:');
console.log('=====================================');

try {
  const adminExists = await pool.query(
    'SELECT COUNT(*) FROM sellers WHERE email = $1 AND status = $2',
    ['administrador@softsan.com.br', 'Ativo']
  );
  
  if (adminExists.rows[0].count > 0) {
    console.log('✅ Sistema configurado corretamente!');
    console.log('');
    console.log('CREDENCIAIS DE ACESSO:');
    console.log('Email: administrador@softsan.com.br');
    console.log('Senha: M1xgestao@2025');
    console.log('');
    console.log('URLs PARA TESTE:');
    console.log('- Health Check: http://seu-servidor/api/health');
    console.log('- Login: POST http://seu-servidor/api/auth/login');
    console.log('- Dashboard: http://seu-servidor/');
    console.log('');
    console.log('Se ainda houver erro 500, verifique:');
    console.log('1. Logs da aplicação no servidor');
    console.log('2. Configuração do Load Balancer');
    console.log('3. Security Groups permitindo tráfego');
    console.log('4. Configuração de CORS se necessário');
    
  } else {
    console.log('❌ Problema na configuração do administrador');
  }
  
} catch (error) {
  console.log('❌ Erro final:', error.message);
}

// Fechar conexões
await pool.end();
console.log('');
console.log('🔍 Diagnóstico concluído.');