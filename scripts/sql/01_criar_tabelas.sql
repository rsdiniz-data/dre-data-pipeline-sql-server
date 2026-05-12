-- =========================================================
-- 🔹 CRIAR TABELAS
-- =========================================================

-- =========================================================
-- 01_CRIAR_TABELAS.sql
-- Projeto: DRE Embraer | SQL Server
--
-- Objetivo:
-- - Criar banco de dados da solução analítica
-- - Criar tabelas da camada Staging
-- - Criar tabelas da camada Analítica
-- - Criar índices para otimização de performance
--
-- 🔗 Rastreabilidade:
-- - Documento técnico: ../docs/02_arquitetura.md
-- - Artigo: ../docs/06_artigo_tecnico.md
--   3.3 Criação das Estruturas no SQL Server
--   3.3.1 Etapas
--
-- Pipeline:
-- Arquivos (PDF/Excel)
--     ↓
-- Staging (stg_Basepdf / stg_PlanoConta)
--     ↓
-- Camada Analítica (dPlanoConta / ftResultado)
-- =========================================================

-- =========================================================
-- 1. Criação do banco de dados
-- =========================================================
-- Referência:
-- - 3.3.1 → Criação do banco DRE_EMBRAER
-- Objetivo:
-- - Centralizar os dados em ambiente relacional
-- - Eliminar dependência de arquivos locais

IF DB_ID('DRE_EMBRAER') IS NULL
BEGIN
    CREATE DATABASE DRE_EMBRAER;
END
GO

USE DRE_EMBRAER;
GO

-- =========================================================
-- 2. Criação da camada Staging
-- =========================================================
-- Referência:
-- - docs/02_arquitetura.md → Camada Staging
-- - 3.2.1.6 → Criação da camada de staging
--
-- Objetivo:
-- - Armazenar dados brutos sem transformação
-- - Garantir rastreabilidade e reprocessamento

-- =========================================================
-- 2.1 Tabela stg_Basepdf
-- =========================================================
-- Referência:
-- - 3.2.1 → Ingestão de PDFs
-- - 3.2.1.3 → Extração de campos estruturados

IF OBJECT_ID('dbo.stg_Basepdf', 'U') IS NOT NULL
    DROP TABLE dbo.stg_Basepdf;
GO

CREATE TABLE dbo.stg_Basepdf (

    Id INT IDENTITY(1,1) PRIMARY KEY,

    -- Referência:
    -- 3.2.1.4 → Rastreabilidade de origem
    ArquivoOrigem NVARCHAR(255) NULL,

    -- Referência:
    -- 3.2.1.3 → Estruturação dos dados extraídos
    CodigoConta NVARCHAR(50) NULL,
    DescricaoConta NVARCHAR(500) NULL,

    -- Referência:
    -- Estrutura original antes do unpivot
    Valor_2022 NVARCHAR(100) NULL,
    Valor_2021 NVARCHAR(100) NULL,
    Valor_2024 NVARCHAR(100) NULL,
    Valor_2023 NVARCHAR(100) NULL,

    -- Controle técnico de carga
    DataCarga DATETIME NOT NULL
        DEFAULT GETDATE()
);
GO

-- =========================================================
-- 2.2 Tabela stg_PlanoConta
-- =========================================================
-- Referência:
-- - 3.2.1.5 → Leitura do Excel
-- - Plano de contas oficial da DRE

IF OBJECT_ID('dbo.stg_PlanoConta', 'U') IS NOT NULL
    DROP TABLE dbo.stg_PlanoConta;
GO

CREATE TABLE dbo.stg_PlanoConta (

    -- Referência:
    -- Preservação da ordem do Excel
    RowNum INT NOT NULL,

    -- Referência:
    -- Estrutura contábil oficial
    ID_Conta NVARCHAR(50) NULL,
    Lancamento INT NULL,
    Descricao NVARCHAR(500) NULL,
    Calculado INT NULL,

    -- Controle técnico de carga
    DataCarga DATETIME NOT NULL
        DEFAULT GETDATE()
);
GO

-- =========================================================
-- 3. Criação da camada Analítica
-- =========================================================
-- Referência:
-- - docs/02_arquitetura.md → Modelo Dimensional
-- - 3.4 → Transformações de Dados no SQL Server
--
-- Objetivo:
-- - Estruturar modelo Star Schema
-- - Separar dimensão e fato
-- - Otimizar consumo no Power BI

-- =========================================================
-- 3.1 Tabela dPlanoConta
-- =========================================================
-- Referência:
-- - 3.4.1 → Transformações dPlanoConta
-- - 4.1 → Dicionário de Dados
--
-- Objetivo:
-- - Estruturar hierarquia contábil da DRE

IF OBJECT_ID('dbo.dPlanoConta', 'U') IS NOT NULL
    DROP TABLE dbo.dPlanoConta;
GO

CREATE TABLE dbo.dPlanoConta (

    -- Referência:
    -- Chave principal da dimensão
    ID_Conta NVARCHAR(50) NOT NULL
        PRIMARY KEY,

    -- Referência:
    -- 3.4.2.6 → Filtro de contas analíticas
    Lancamento INT NULL,

    -- Descrição da conta contábil
    Descricao NVARCHAR(500) NULL,

    -- Referência:
    -- 3.4.1.2 → Criação da hierarquia
    N1 NVARCHAR(500) NULL,
    N2 NVARCHAR(500) NULL,
    N3 NVARCHAR(500) NULL,

    -- Referência:
    -- 3.4.1.4 → Agrupamento da DRE
    CodDRE NVARCHAR(50) NULL,

    -- Campo auxiliar do plano
    Calculado INT NULL,

    -- Referência:
    -- 3.4.1.5 → TipoIndicador
    --
    -- +1 → Receita / Resultado
    -- -1 → Custos / Despesas
    TipoIndicador INT NULL
);
GO

-- =========================================================
-- 3.2 Tabela ftResultado
-- =========================================================
-- Referência:
-- - 3.4.2 → Transformações ftResultado
-- - 4.2 → Dicionário de Dados
--
-- Objetivo:
-- - Armazenar valores financeiros da DRE

IF OBJECT_ID('dbo.ftResultado', 'U') IS NOT NULL
    DROP TABLE dbo.ftResultado;
GO

CREATE TABLE dbo.ftResultado (

    -- Referência:
    -- Relacionamento com dimensão dPlanoConta
    ID_Conta NVARCHAR(50) NOT NULL,

    -- Referência:
    -- 3.4.2.4 → Criação da coluna Data
    [Data] DATE NOT NULL,

    -- Referência:
    -- Métrica financeira principal da DRE
    Valor DECIMAL(18,2) NULL
);
GO

-- =========================================================
-- 4. Criação de índices
-- =========================================================
-- Referência:
-- - docs/05_entrega_valor.md → Performance
-- - 5.2 → Performance
--
-- Objetivo:
-- - Melhorar consultas analíticas
-- - Otimizar joins
-- - Reduzir tempo de leitura no Power BI

-- =========================================================
-- 4.1 Índice ftResultado
-- =========================================================
-- Referência:
-- Consultas por conta e período

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ftResultado_IDConta_Data'
      AND object_id = OBJECT_ID('dbo.ftResultado')
)
BEGIN

    CREATE INDEX IX_ftResultado_IDConta_Data
        ON dbo.ftResultado (
            ID_Conta,
            [Data]
        );

END
GO

-- =========================================================
-- 4.2 Índice stg_Basepdf
-- =========================================================
-- Referência:
-- Integração entre staging e dimensão

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_stg_Basepdf_CodigoConta'
      AND object_id = OBJECT_ID('dbo.stg_Basepdf')
)
BEGIN

    CREATE INDEX IX_stg_Basepdf_CodigoConta
        ON dbo.stg_Basepdf (
            CodigoConta
        );

END
GO

-- =========================================================
-- 4.3 Índice stg_PlanoConta
-- =========================================================
-- Referência:
-- Performance de joins e transformações

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_stg_PlanoConta_IDConta'
      AND object_id = OBJECT_ID('dbo.stg_PlanoConta')
)
BEGIN

    CREATE INDEX IX_stg_PlanoConta_IDConta
        ON dbo.stg_PlanoConta (
            ID_Conta
        );

END
GO
