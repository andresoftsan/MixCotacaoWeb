#!/usr/bin/env node

// Script de diagnóstico completo para produção
// Mix Cotação Web - Diagnóstico AWS Lightsail

const fs = require('fs');
const path = require('path');

console.log('=========================================');
console.log('  Mix Cotação Web - Diagnóstico AWS');
console.log('=========================================\n');

// 1. Verificar arquivo .env
console.log('1. VERIFICAÇÃO DE CONFIGURAÇÃO:');
try {
  if (!fs.existsSync('.env')) {
    console.log('❌ Arquivo .env não encontrado!');
    console.log('Crie o arquivo .env com as configurações necessárias.\n');
    process.exit(1);
  }
  
  const envContent = fs.readFileSync('.env', 'utf8');
  const lines = envContent.split('\n').filter(line => line.trim() && !line.startsWith('#'));
  
  console.log('✅ Arquivo .env encontrado');
  console.log('Variáveis configuradas:');
  
  const requiredVars = ['DATABASE_URL', 'SESSION_SECRET', 'NODE_ENV', 'PORT'];
  const envVars = {};
  
  lines.forEach(line => {
    const [key, ...valueParts] = line.split('=');
    const value = valueParts.join('=').replace(/"/g, '');
    if (key) envVars[key] = value;
  });
  
  requiredVars.forEach(varName => {
    if (envVars[varName]) {
      if (varName === 'DATABASE_URL') {
        const url = envVars[varName];
        console.log(`✅ ${varName}: ${url.substring(0, 30)}...`);
        
        // Verificar se é localhost em produção
        if (url.includes('localhost') && envVars.NODE_ENV === 'production') {
          console.log('⚠️  PROBLEMA: DATABASE_URL usa localhost em produção!');
          console.log('   Isso pode causar erro de certificado SSL.');
        }
        
        // Verificar se é Neon Database
        if (url.includes('neon.tech')) {
          console.log('📡 Usando Neon Database (cloud)');
        } else if (url.includes('localhost')) {
          console.log('🏠 Usando PostgreSQL local');
        }
      } else if (varName === 'SESSION_SECRET') {
        console.log(`✅ ${varName}: ${'*'.repeat(envVars[varName].length)} (${envVars[varName].length} caracteres)`);
      } else {
        console.log(`✅ ${varName}: ${envVars[varName]}`);
      }
    } else {
      console.log(`❌ ${varName}: NÃO CONFIGURADO`);
    }
  });
  
} catch (error) {
  console.log('❌ Erro ao ler .env:', error.message);
}

console.log('\n2. VERIFICAÇÃO DE ARQUIVOS:');

// Verificar arquivos essenciais
const essentialFiles = [
  'package.json',
  'dist/index.js',
  'ecosystem.config.js',
  'production.config.js'
];

essentialFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`✅ ${file}`);
  } else {
    console.log(`❌ ${file} não encontrado`);
  }
});

// 3. Verificar package.json
console.log('\n3. VERIFICAÇÃO DE DEPENDÊNCIAS:');
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  const criticalDeps = [
    '@neondatabase/serverless',
    'drizzle-orm',
    'express',
    'bcrypt'
  ];
  
  criticalDeps.forEach(dep => {
    if (packageJson.dependencies && packageJson.dependencies[dep]) {
      console.log(`✅ ${dep}: ${packageJson.dependencies[dep]}`);
    } else {
      console.log(`❌ ${dep}: não encontrado`);
    }
  });
  
} catch (error) {
  console.log('❌ Erro ao ler package.json:', error.message);
}

// 4. Verificar configuração PM2
console.log('\n4. VERIFICAÇÃO PM2:');
if (fs.existsSync('ecosystem.config.js')) {
  try {
    const ecosystemContent = fs.readFileSync('ecosystem.config.js', 'utf8');
    console.log('✅ ecosystem.config.js encontrado');
    
    if (ecosystemContent.includes('NODE_ENV') && ecosystemContent.includes('production')) {
      console.log('✅ Configurado para produção');
    } else {
      console.log('⚠️  Verifique configuração de ambiente');
    }
  } catch (error) {
    console.log('❌ Erro ao ler ecosystem.config.js:', error.message);
  }
}

// 5. Verificar logs
console.log('\n5. RECOMENDAÇÕES PARA CORRIGIR:');

console.log('Para resolver o erro de certificado SSL:');
console.log('');
console.log('🔧 OPÇÃO 1 - Usar PostgreSQL Local (Recomendado):');
console.log('   1. Instale PostgreSQL no servidor');
console.log('   2. Configure DATABASE_URL=postgresql://user:pass@localhost:5432/db');
console.log('   3. Execute: ./fix-production-database.sh');
console.log('');
console.log('🔧 OPÇÃO 2 - Corrigir URL do Neon:');
console.log('   1. Acesse o painel do Neon Database');
console.log('   2. Copie a CONNECTION STRING correta');
console.log('   3. Atualize no arquivo .env');
console.log('   4. Execute: pm2 restart mix-cotacao-web');
console.log('');
console.log('🔧 COMANDOS ÚTEIS:');
console.log('   - Ver logs: pm2 logs mix-cotacao-web');
console.log('   - Reiniciar: pm2 restart mix-cotacao-web');
console.log('   - Status: pm2 status');
console.log('   - Monitorar: pm2 monit');

console.log('\n=========================================');
console.log('Diagnóstico concluído!');
console.log('=========================================');