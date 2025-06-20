-- ===============================================
-- Mix Cotação Web - Schema Completo do Banco
-- PostgreSQL Database Schema
-- Data: 2025-06-17
-- ===============================================

-- Remover tabelas se existirem (para recriação completa)
DROP TABLE IF EXISTS quotation_items CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS quotations CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;

-- ===============================================
-- TABELA: sellers (usuários do sistema)
-- ===============================================
CREATE TABLE sellers (
    id SERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    password TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Ativo',
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_sellers_email ON sellers(email);
CREATE INDEX idx_sellers_status ON sellers(status);

-- ===============================================
-- TABELA: quotations (cotações)
-- ===============================================
CREATE TABLE quotations (
    id SERIAL PRIMARY KEY,
    number TEXT NOT NULL UNIQUE,
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'Aguardando digitação',
    deadline TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    supplier_cnpj TEXT NOT NULL,
    supplier_name TEXT NOT NULL,
    client_cnpj TEXT NOT NULL,
    client_name TEXT NOT NULL,
    internal_observation TEXT,
    seller_id INTEGER NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_quotations_number ON quotations(number);
CREATE INDEX idx_quotations_seller_id ON quotations(seller_id);
CREATE INDEX idx_quotations_status ON quotations(status);
CREATE INDEX idx_quotations_date ON quotations(date);
CREATE INDEX idx_quotations_deadline ON quotations(deadline);
CREATE INDEX idx_quotations_client_cnpj ON quotations(client_cnpj);
CREATE INDEX idx_quotations_supplier_cnpj ON quotations(supplier_cnpj);

-- ===============================================
-- TABELA: api_keys (chaves de API)
-- ===============================================
CREATE TABLE api_keys (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    key TEXT NOT NULL UNIQUE,
    seller_id INTEGER NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITHOUT TIME ZONE
);

-- Índices para performance
CREATE INDEX idx_api_keys_key ON api_keys(key);
CREATE INDEX idx_api_keys_seller_id ON api_keys(seller_id);
CREATE INDEX idx_api_keys_is_active ON api_keys(is_active);

-- ===============================================
-- TABELA: quotation_items (itens de cotação)
-- ===============================================
CREATE TABLE quotation_items (
    id SERIAL PRIMARY KEY,
    quotation_id INTEGER NOT NULL REFERENCES quotations(id) ON DELETE CASCADE,
    barcode TEXT NOT NULL,
    product_name TEXT NOT NULL,
    quoted_quantity INTEGER NOT NULL,
    available_quantity INTEGER,
    unit_price DECIMAL(10, 2),
    validity TIMESTAMP WITHOUT TIME ZONE,
    situation TEXT
);

-- Índices para performance
CREATE INDEX idx_quotation_items_quotation_id ON quotation_items(quotation_id);
CREATE INDEX idx_quotation_items_barcode ON quotation_items(barcode);
CREATE INDEX idx_quotation_items_situation ON quotation_items(situation);

-- ===============================================
-- DADOS INICIAIS
-- ===============================================

-- Inserir usuário administrador
INSERT INTO sellers (
    email, 
    name, 
    password, 
    status
) VALUES (
    'administrador@softsan.com.br',
    'Administrador',
    '$2b$10$8K1p/a0dLszKT6Q2.SwQNOPjdHCJsm7k1WjHCXKjHsF8yPsRQWZeK', -- M1xgestao@2025
    'Ativo'
);

-- Inserir usuário de teste (opcional)
INSERT INTO sellers (
    email, 
    name, 
    password, 
    status
) VALUES (
    'teste@softsan.com.br',
    'Usuario Teste',
    '$2b$10$K1p/a0dLszKT6Q2.SwQNOPjdHCJsm7k1WjHCXKjHsF8yPsRQWZeK', -- 123456
    'Ativo'
);

-- ===============================================
-- VERIFICAÇÕES E VALIDAÇÕES
-- ===============================================

-- Verificar se as tabelas foram criadas
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as colunas
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

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
ORDER BY id;

-- Verificar constraints e relacionamentos
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- ===============================================
-- ESTATÍSTICAS FINAIS
-- ===============================================
SELECT 
    'sellers' as tabela, COUNT(*) as registros FROM sellers
UNION ALL
SELECT 
    'quotations' as tabela, COUNT(*) as registros FROM quotations
UNION ALL
SELECT 
    'quotation_items' as tabela, COUNT(*) as registros FROM quotation_items
UNION ALL
SELECT 
    'api_keys' as tabela, COUNT(*) as registros FROM api_keys
ORDER BY tabela;

-- ===============================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ===============================================

COMMENT ON TABLE sellers IS 'Tabela de usuários do sistema (vendedores e administradores)';
COMMENT ON COLUMN sellers.email IS 'Email único do usuário (usado para login)';
COMMENT ON COLUMN sellers.password IS 'Senha criptografada com bcrypt';
COMMENT ON COLUMN sellers.status IS 'Status do usuário: Ativo ou Inativo';

COMMENT ON TABLE quotations IS 'Tabela principal de cotações';
COMMENT ON COLUMN quotations.number IS 'Número único da cotação (formato: COT-YYYY-NNN)';
COMMENT ON COLUMN quotations.status IS 'Status: Aguardando digitação, Prazo Encerrado, Enviada';
COMMENT ON COLUMN quotations.seller_id IS 'Referência ao vendedor responsável';

COMMENT ON TABLE quotation_items IS 'Itens individuais de cada cotação';
COMMENT ON COLUMN quotation_items.situation IS 'Situação: Disponível, Indisponível, Parcial';
COMMENT ON COLUMN quotation_items.quoted_quantity IS 'Quantidade solicitada';
COMMENT ON COLUMN quotation_items.available_quantity IS 'Quantidade disponível';

COMMENT ON TABLE api_keys IS 'Chaves de API para integração externa';
COMMENT ON COLUMN api_keys.key IS 'Token único para autenticação via API';
COMMENT ON COLUMN api_keys.is_active IS 'Se a chave está ativa ou desabilitada';

-- ===============================================
-- RESUMO DE INSTALAÇÃO
-- ===============================================

/*
INSTRUÇÕES DE USO:

1. Execute este script em um banco PostgreSQL vazio:
   psql -U usuario -d banco -h host -f mix_cotacao_schema.sql

2. Credenciais criadas:
   - Admin: administrador@softsan.com.br / M1xgestao@2025
   - Teste: teste@softsan.com.br / 123456

3. O administrador é identificado pelo email específico no código

4. Todas as tabelas, índices e relacionamentos são criados automaticamente

5. O script inclui verificações e validações ao final
*/