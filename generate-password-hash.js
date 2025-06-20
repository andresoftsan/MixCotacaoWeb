#!/usr/bin/env node

// Script para gerar hash de senhas
// Mix Cotação Web - Gerador de Hash
// Uso: node generate-password-hash.js [senha]

const bcrypt = require('bcrypt');

async function generateHash(password) {
    try {
        const saltRounds = 10;
        const hash = await bcrypt.hash(password, saltRounds);
        return hash;
    } catch (error) {
        console.error('Erro ao gerar hash:', error);
        process.exit(1);
    }
}

async function main() {
    const password = process.argv[2];
    
    if (!password) {
        console.log('Uso: node generate-password-hash.js [senha]');
        console.log('Exemplo: node generate-password-hash.js MinhaSenh@123');
        process.exit(1);
    }
    
    console.log('Gerando hash para a senha...');
    const hash = await generateHash(password);
    
    console.log('\n=== RESULTADO ===');
    console.log('Senha:', password);
    console.log('Hash:', hash);
    console.log('\n=== SQL PARA INSERIR USUÁRIO ===');
    console.log(`INSERT INTO sellers (name, email, password, is_admin, status, created_at)`);
    console.log(`VALUES ('Nome do Usuario', 'email@exemplo.com', '${hash}', false, 'Ativo', NOW());`);
    console.log('\n=== VERIFICAR SENHA ===');
    
    // Verificar se o hash está correto
    const isValid = await bcrypt.compare(password, hash);
    console.log('Hash válido:', isValid ? 'SIM' : 'NÃO');
}

main().catch(console.error);