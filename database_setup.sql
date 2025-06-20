-- ===============================================
-- Mix Cotação Web - Setup Usuário Administrador
-- Tabela: sellers (usuários do sistema)
-- Data: 2025-06-17
-- ===============================================

-- Limpar dados anteriores se necessário (descomente se precisar)
-- DELETE FROM sellers WHERE email IN ('administrador@softsan.com.br', 'teste@softsan.com.br');

-- Inserir usuário administrador principal
INSERT INTO sellers (
    email, 
    name, 
    password, 
    status
) VALUES (
    'administrador@softsan.com.br',
    'Administrador',
    '$2b$10$8K1p/a0dLszKT6Q2.SwQNOPjdHCJsm7k1WjHCXKjHsF8yPsRQWZeK',
    'Ativo'
) ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    password = EXCLUDED.password,
    status = EXCLUDED.status;

-- Inserir usuário de teste (opcional)
INSERT INTO sellers (
    email, 
    name, 
    password, 
    status
) VALUES (
    'teste@softsan.com.br',
    'Usuario Teste',
    '$2b$10$K1p/a0dLszKT6Q2.SwQNOPjdHCJsm7k1WjHCXKjHsF8yPsRQWZeK',
    'Ativo'
) ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    password = EXCLUDED.password,
    status = EXCLUDED.status;

-- Verificar usuários criados
SELECT 
    id, 
    email, 
    name, 
    status, 
    created_at,
    CASE 
        WHEN email = 'administrador@softsan.com.br' THEN 'ADMINISTRADOR'
        ELSE 'VENDEDOR'
    END as tipo_usuario
FROM sellers 
WHERE email IN ('administrador@softsan.com.br', 'teste@softsan.com.br')
ORDER BY id;

-- Mostrar estatísticas
SELECT 
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN email = 'administrador@softsan.com.br' THEN 1 END) as admins,
    COUNT(CASE WHEN email != 'administrador@softsan.com.br' THEN 1 END) as vendedores,
    COUNT(CASE WHEN status = 'Ativo' THEN 1 END) as ativos
FROM sellers;

-- ===============================================
-- CREDENCIAIS DE ACESSO:
-- 
-- ADMINISTRADOR:
--   Email: administrador@softsan.com.br
--   Senha: M1xgestao@2025
--   Tipo: Admin (identificado pelo email)
--
-- TESTE:
--   Email: teste@softsan.com.br  
--   Senha: 123456
--   Tipo: Vendedor comum
-- ===============================================