-- Mix Cotação Web - Script de Configuração do Banco de Dados
-- Execute este script em seu banco PostgreSQL externo

-- Criar tabelas
CREATE TABLE IF NOT EXISTS sellers (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  password TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Ativo',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quotations (
  id SERIAL PRIMARY KEY,
  number TEXT NOT NULL UNIQUE,
  date TIMESTAMP NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'Aguardando digitação',
  deadline TIMESTAMP NOT NULL,
  supplier_cnpj TEXT NOT NULL,
  supplier_name TEXT NOT NULL,
  client_cnpj TEXT NOT NULL,
  client_name TEXT NOT NULL,
  internal_observation TEXT,
  seller_id INTEGER REFERENCES sellers(id) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS api_keys (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  key TEXT NOT NULL UNIQUE,
  seller_id INTEGER REFERENCES sellers(id) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  last_used_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quotation_items (
  id SERIAL PRIMARY KEY,
  quotation_id INTEGER REFERENCES quotations(id) NOT NULL,
  barcode TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quoted_quantity INTEGER NOT NULL,
  available_quantity INTEGER,
  unit_price DECIMAL(10,2),
  validity TIMESTAMP,
  situation TEXT
);

-- Inserir usuários (administrador e vendedores de teste)
INSERT INTO sellers (email, name, password, status) VALUES
-- Administrador (senha: M1xgestao@2025)
('administrador@softsan.com.br', 'Administrador', '$2b$10$xJ74TYRuRTzslVN2VwUg7.NAklZ7Wwdxx4CcxtaAeIsYgPe.6feDe', 'Ativo'),

-- Vendedores de teste (senha: 123456)
('joao.silva@empresa.com.br', 'João Silva', '$2b$10$XduR.IaSMUUyvAQWMAiyIOBCA.YwkKeQ2/ueTaB9CeOEP0TRjvQIu', 'Ativo'),
('maria.santos@empresa.com.br', 'Maria Santos', '$2b$10$XduR.IaSMUUyvAQWMAiyIOBCA.YwkKeQ2/ueTaB9CeOEP0TRjvQIu', 'Ativo'),
('pedro.oliveira@empresa.com.br', 'Pedro Oliveira', '$2b$10$XduR.IaSMUUyvAQWMAiyIOBCA.YwkKeQ2/ueTaB9CeOEP0TRjvQIu', 'Ativo'),
('ana.costa@empresa.com.br', 'Ana Costa', '$2b$10$XduR.IaSMUUyvAQWMAiyIOBCA.YwkKeQ2/ueTaB9CeOEP0TRjvQIu', 'Inativo')

ON CONFLICT (email) DO NOTHING;

-- Inserir cotações de teste
INSERT INTO quotations (
  number, date, status, deadline, supplier_cnpj, supplier_name, 
  client_cnpj, client_name, internal_observation, seller_id
) VALUES
-- Cotações do João Silva (ID: 2)
('COT-2025-001', NOW() - INTERVAL '2 days', 'Aguardando digitação', NOW() + INTERVAL '3 days', 
 '12.345.678/0001-90', 'Distribuidora ABC Ltda', 
 '98.765.432/0001-10', 'Supermercado XYZ S/A', 
 'Cliente preferencial - prazo estendido', 2),

('COT-2025-002', NOW() - INTERVAL '1 day', 'Enviada', NOW() + INTERVAL '5 days',
 '11.222.333/0001-44', 'Fornecedor Beta Ltda', 
 '55.666.777/0001-88', 'Loja do Bairro ME', 
 'Primeira compra do cliente', 2),

('COT-2025-003', NOW() - INTERVAL '10 days', 'Prazo Encerrado', NOW() - INTERVAL '2 days',
 '22.333.444/0001-55', 'Importadora Gama S/A', 
 '77.888.999/0001-11', 'Atacadista Delta Ltda', 
 'Cliente não respondeu no prazo', 2),

-- Cotações da Maria Santos (ID: 3)
('COT-2025-004', NOW(), 'Aguardando digitação', NOW() + INTERVAL '7 days',
 '33.444.555/0001-66', 'Indústria Alimentícia Épsilon', 
 '44.555.666/0001-99', 'Rede de Lojas Zeta', 
 'Produto sazonal - urgente', 3),

('COT-2025-005', NOW() - INTERVAL '3 days', 'Enviada', NOW() + INTERVAL '2 days',
 '12.345.678/0001-90', 'Distribuidora ABC Ltda', 
 '11.223.344/0001-55', 'Mercearia do João', 
 'Negociação de preços em andamento', 3),

-- Cotações do Pedro Oliveira (ID: 4)
('COT-2025-006', NOW() - INTERVAL '1 day', 'Aguardando digitação', NOW() + INTERVAL '4 days',
 '55.666.777/0001-22', 'Produtos de Limpeza Theta', 
 '88.999.000/0001-33', 'Hotel Conforto Ltda', 
 'Cliente corporativo - desconto especial', 4),

('COT-2025-007', NOW() - INTERVAL '5 days', 'Enviada', NOW() + INTERVAL '1 day',
 '66.777.888/0001-44', 'Bebidas Iota Distribuidora', 
 '99.000.111/0001-77', 'Bar e Restaurante Kappa', 
 'Evento especial - entrega programada', 4),

-- Cotação expirada automática
('COT-2025-008', NOW() - INTERVAL '15 days', 'Prazo Encerrado', NOW() - INTERVAL '5 days',
 '77.888.999/0001-55', 'Atacadista Lambda S/A', 
 '00.111.222/0001-88', 'Padaria Mu ME', 
 'Sistema atualizou automaticamente', 2)

ON CONFLICT (number) DO NOTHING;

-- Inserir itens das cotações de teste
INSERT INTO quotation_items (
  quotation_id, barcode, product_name, quoted_quantity, 
  available_quantity, unit_price, validity, situation
) VALUES
-- Itens da COT-2025-001 (ID: 1)
(1, '7891234567890', 'Açúcar Cristal 1kg', 50, 50, 4.50, NOW() + INTERVAL '30 days', 'Disponível'),
(1, '7891234567891', 'Arroz Branco Tipo 1 5kg', 30, 25, 12.80, NOW() + INTERVAL '30 days', 'Parcial'),
(1, '7891234567892', 'Feijão Carioca 1kg', 40, NULL, NULL, NULL, NULL),
(1, '7891234567893', 'Óleo de Soja 900ml', 60, 0, NULL, NULL, 'Indisponível'),

-- Itens da COT-2025-002 (ID: 2)
(2, '7891234567894', 'Macarrão Espaguete 500g', 100, 100, 3.25, NOW() + INTERVAL '45 days', 'Disponível'),
(2, '7891234567895', 'Molho de Tomate 340g', 80, 80, 2.10, NOW() + INTERVAL '45 days', 'Disponível'),
(2, '7891234567896', 'Biscoito Cream Cracker 400g', 60, 60, 4.80, NOW() + INTERVAL '45 days', 'Disponível'),

-- Itens da COT-2025-003 (ID: 3)
(3, '7891234567897', 'Café Torrado e Moído 500g', 40, 35, 8.90, NOW() - INTERVAL '10 days', 'Parcial'),
(3, '7891234567898', 'Leite Integral UHT 1L', 120, NULL, NULL, NULL, NULL),

-- Itens da COT-2025-004 (ID: 4)
(4, '7891234567899', 'Chocolate em Pó 400g', 25, NULL, NULL, NULL, NULL),
(4, '7891234567900', 'Achocolatado em Pó 800g', 35, NULL, NULL, NULL, NULL),
(4, '7891234567901', 'Leite Condensado 395g', 50, NULL, NULL, NULL, NULL),

-- Itens da COT-2025-005 (ID: 5)
(5, '7891234567902', 'Farinha de Trigo 1kg', 80, 70, 3.40, NOW() + INTERVAL '60 days', 'Parcial'),
(5, '7891234567903', 'Fermento Biológico 10g', 200, 200, 0.85, NOW() + INTERVAL '30 days', 'Disponível'),

-- Itens da COT-2025-006 (ID: 6)
(6, '7891234567904', 'Detergente Líquido 500ml', 150, NULL, NULL, NULL, NULL),
(6, '7891234567905', 'Desinfetante 2L', 80, NULL, NULL, NULL, NULL),
(6, '7891234567906', 'Papel Higiênico 12 rolos', 100, NULL, NULL, NULL, NULL),

-- Itens da COT-2025-007 (ID: 7)
(7, '7891234567907', 'Refrigerante Cola 2L', 60, 60, 5.20, NOW() + INTERVAL '15 days', 'Disponível'),
(7, '7891234567908', 'Água Mineral 500ml (pack 12)', 40, 30, 8.50, NOW() + INTERVAL '15 days', 'Parcial'),
(7, '7891234567909', 'Cerveja Lata 350ml (pack 12)', 25, 25, 18.90, NOW() + INTERVAL '10 days', 'Disponível'),

-- Itens da COT-2025-008 (ID: 8)
(8, '7891234567910', 'Pão Francês kg', 20, NULL, NULL, NULL, NULL),
(8, '7891234567911', 'Pão de Forma 500g', 30, NULL, NULL, NULL, NULL);

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_quotations_seller_id ON quotations(seller_id);
CREATE INDEX IF NOT EXISTS idx_quotations_status ON quotations(status);
CREATE INDEX IF NOT EXISTS idx_quotations_deadline ON quotations(deadline);
CREATE INDEX IF NOT EXISTS idx_quotation_items_quotation_id ON quotation_items(quotation_id);
CREATE INDEX IF NOT EXISTS idx_sellers_email ON sellers(email);
CREATE INDEX IF NOT EXISTS idx_api_keys_key ON api_keys(key);
CREATE INDEX IF NOT EXISTS idx_api_keys_seller_id ON api_keys(seller_id);

-- Inserir algumas chaves API de exemplo (opcional)
INSERT INTO api_keys (name, key, seller_id, is_active) VALUES
('Sistema ERP Principal', 'mk_live_1234567890abcdef1234567890abcdef', 1, true),
('Integração E-commerce', 'mk_live_abcdef1234567890abcdef1234567890', 1, true),
('API Terceiros', 'mk_test_9876543210fedcba9876543210fedcba', 2, false)
ON CONFLICT (key) DO NOTHING;

-- Verificar dados inseridos
SELECT 
  'Sellers' as tabela,
  COUNT(*) as total_registros
FROM sellers
UNION ALL
SELECT 
  'Quotations' as tabela,
  COUNT(*) as total_registros  
FROM quotations
UNION ALL
SELECT 
  'Quotation Items' as tabela,
  COUNT(*) as total_registros
FROM quotation_items
UNION ALL
SELECT 
  'API Keys' as tabela,
  COUNT(*) as total_registros
FROM api_keys;

-- Exibir resumo por vendedor
SELECT 
  s.name as vendedor,
  s.email,
  s.status,
  COUNT(q.id) as total_cotacoes,
  COUNT(CASE WHEN q.status = 'Aguardando digitação' THEN 1 END) as aguardando,
  COUNT(CASE WHEN q.status = 'Enviada' THEN 1 END) as enviadas,
  COUNT(CASE WHEN q.status = 'Prazo Encerrado' THEN 1 END) as expiradas
FROM sellers s
LEFT JOIN quotations q ON s.id = q.seller_id
GROUP BY s.id, s.name, s.email, s.status
ORDER BY s.name;

-- Exibir cotações com resumo de itens
SELECT 
  q.number as numero_cotacao,
  q.status,
  q.deadline as prazo,
  s.name as vendedor,
  q.supplier_name as fornecedor,
  q.client_name as cliente,
  COUNT(qi.id) as total_itens,
  COUNT(CASE WHEN qi.situation = 'Disponível' THEN 1 END) as itens_disponiveis,
  COUNT(CASE WHEN qi.situation = 'Parcial' THEN 1 END) as itens_parciais,
  COUNT(CASE WHEN qi.situation = 'Indisponível' THEN 1 END) as itens_indisponiveis,
  COUNT(CASE WHEN qi.situation IS NULL THEN 1 END) as itens_pendentes
FROM quotations q
LEFT JOIN sellers s ON q.seller_id = s.id
LEFT JOIN quotation_items qi ON q.id = qi.quotation_id
GROUP BY q.id, q.number, q.status, q.deadline, s.name, q.supplier_name, q.client_name
ORDER BY q.number;

-- Comentários finais
COMMENT ON TABLE sellers IS 'Tabela de vendedores e administradores do sistema';
COMMENT ON TABLE quotations IS 'Tabela principal de cotações';
COMMENT ON TABLE quotation_items IS 'Itens individuais de cada cotação';
COMMENT ON TABLE api_keys IS 'Chaves de API para integração com sistemas terceiros';

-- Script executado com sucesso!
-- Credenciais de acesso:
-- Administrador: administrador@softsan.com.br / M1xgestao@2025
-- Vendedores teste: [email] / 123456
-- 
-- Estatísticas:
-- - 5 usuários (1 admin + 4 vendedores)
-- - 8 cotações de teste
-- - 25 itens de cotação
-- - 3 chaves API de exemplo
--
-- Para conectar sua aplicação, use a variável DATABASE_URL apontando para este banco.