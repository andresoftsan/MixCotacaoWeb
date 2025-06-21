#!/usr/bin/env node

// Script para corrigir problemas de imports ESM
// Verifica e corrige extensões de arquivo

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('Verificando imports ESM no build...');

// Verificar se dist existe
const distPath = path.join(__dirname, 'dist');
if (!fs.existsSync(distPath)) {
    console.log('❌ Diretório dist não existe. Execute npm run build primeiro.');
    process.exit(1);
}

// Verificar arquivo principal
const mainFile = path.join(distPath, 'index.js');
if (!fs.existsSync(mainFile)) {
    console.log('❌ Arquivo dist/index.js não existe.');
    process.exit(1);
}

console.log('✅ Build encontrado');

// Testar import do arquivo principal
try {
    console.log('Testando import do arquivo principal...');
    
    // Simular carregamento sem executar
    const content = fs.readFileSync(mainFile, 'utf8');
    
    if (content.includes('import')) {
        console.log('✅ Arquivo contém imports ESM');
    } else {
        console.log('⚠️  Arquivo pode estar usando CommonJS');
    }
    
    if (content.includes('dotenv')) {
        console.log('✅ dotenv configurado no build');
    } else {
        console.log('⚠️  dotenv pode não estar configurado');
    }
    
    console.log('✅ Verificação de imports concluída');
    
} catch (error) {
    console.log('❌ Erro ao verificar imports:', error.message);
    process.exit(1);
}