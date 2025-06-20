-- Script de configuração inicial do banco de dados
-- Mix Cotação Web - Usuário Administrador
-- Data: 2025-06-17

-- Inserir usuário administrador
INSERT INTO sellers (
    name, 
    email, 
    password, 
    status, 
    created_at
) VALUES (
    'Administrador',
    'administrador@softsan.com.br',
    '$2b$10$8K1p/a0dLszKT6Q2.SwQNOPjdHCJsm7k1WjHCXKjHsF8yPsRQWZeK', -- M1xgestao@2025
    'Ativo',
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Verificar se o usuário foi criado
SELECT id, name, email, status, created_at 
FROM sellers 
WHERE email = 'administrador@softsan.com.br';

-- Criar usuário de teste não-admin (opcional)
INSERT INTO sellers (
    name, 
    email, 
    password, 
    status, 
    created_at
) VALUES (
    'Usuario Teste',
    'teste@softsan.com.br',
    '$2b$10$K1p/a0dLszKT6Q2.SwQNOPjdHCJsm7k1WjHCXKjHsF8yPsRQWZeK', -- 123456
    'Ativo',
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Mostrar todos os usuários criados
SELECT id, name, email, status, created_at 
FROM sellers 
ORDER BY created_at;

-- Informações sobre as senhas:
-- Administrador: M1xgestao@2025 (privilégios admin por email)
-- Teste: 123456 (vendedor comum)