-- =========================================================
-- 🔹 CRIAR TABELAS
-- =========================================================

/* =========================================================
   01_CRIAR_TABELAS.sql
   Projeto: DRE Embraer com SQL Server

   Objetivo:
   - Criar banco de dados
   - Criar tabelas de staging
   - Criar tabelas finais do modelo dimensional

   🔗 Rastreabilidade:
   - Documento: ../docs/02_arquitetura.md
   - Seção: Camadas (Staging e Analítica)
   ========================================================= */

-- Referência: 03_desenvolvimento.md → Criação da base de dados
IF DB_ID('DRE_EMBRAER') IS NULL
BEGIN
    CREATE DATABASE DRE_EMBRAER;
END
GO

USE DRE_EMBRAER;
GO

/* =========================================================
   Tabelas de staging

   🔗 Referência:
   - Documento: 02_arquitetura.md
   - Seção: Camada Staging
   - Objetivo: Armazenar dados brutos sem transformação
   ========================================================= */

IF OBJECT_ID('dbo.stg_Basepdf', 'U') IS NOT NULL
    DROP TABLE dbo.stg_Basepdf;
GO

CREATE TABLE dbo.stg_Basepdf (
    Id INT IDENTITY(1,1) PRIMARY KEY,

    -- Referência: 03_desenvolvimento.md → Ingestão Python
    ArquivoOrigem NVARCHAR(255) NULL,

    -- Referência: Extração de dados da DRE (PDF)
    CodigoConta NVARCHAR(50) NULL,
    DescricaoConta NVARCHAR(500) NULL,

    -- Referência: Estrutura original dos dados (antes do unpivot)
    Valor_2022 NVARCHAR(100) NULL,
    Valor_2021 NVARCHAR(100) NULL,
    Valor_2024 NVARCHAR(100) NULL,
    Valor_2023 NVARCHAR(100) NULL,

    -- Controle de carga
    DataCarga DATETIME NOT NULL DEFAULT GETDATE()
);
GO

IF OBJECT_ID('dbo.stg_PlanoConta', 'U') IS NOT NULL
    DROP TABLE dbo.stg_PlanoConta;
GO

CREATE TABLE dbo.stg_PlanoConta (
    -- Referência: 03_desenvolvimento.md → Preservação da ordem (Excel)
    RowNum INT NOT NULL,

    -- Referência: Plano de Contas (estrutura contábil)
    ID_Conta NVARCHAR(50) NULL,
    Lancamento INT NULL,
    Descricao NVARCHAR(500) NULL,
    Calculado INT NULL,

    -- Controle de carga
    DataCarga DATETIME NOT NULL DEFAULT GETDATE()
);
GO

/* =========================================================
   Tabelas finais (Camada Analítica)

   🔗 Referência:
   - Documento: 02_arquitetura.md
   - Seção: Modelo Dimensional (Star Schema)
   ========================================================= */

IF OBJECT_ID('dbo.dPlanoConta', 'U') IS NOT NULL
    DROP TABLE dbo.dPlanoConta;
GO

CREATE TABLE dbo.dPlanoConta (
    -- Referência: Dimensão principal da DRE
    ID_Conta NVARCHAR(50) NOT NULL PRIMARY KEY,

    -- Referência: Filtro de contas analíticas (ftResultado)
    Lancamento INT NULL,

    -- Descrição da conta
    Descricao NVARCHAR(500) NULL,

    -- Referência: 03_desenvolvimento.md → Hierarquia contábil
    N1 NVARCHAR(500) NULL,
    N2 NVARCHAR(500) NULL,
    N3 NVARCHAR(500) NULL,

    -- Referência: Agrupamento da DRE
    CodDRE NVARCHAR(50) NULL,

    -- Campo técnico do plano de contas
    Calculado INT NULL,

    -- Referência: Tipo de indicador financeiro
    -- +1 Receita | -1 Despesa
    TipoIndicador INT NULL
);
GO

IF OBJECT_ID('dbo.ftResultado', 'U') IS NOT NULL
    DROP TABLE dbo.ftResultado;
GO

CREATE TABLE dbo.ftResultado (
    -- Referência: Relacionamento com dimensão
    ID_Conta NVARCHAR(50) NOT NULL,

    -- Referência: 03_desenvolvimento.md → Conversão de anos em datas
    [Data] DATE NOT NULL,

    -- Referência: Métrica principal (valor financeiro)
    Valor DECIMAL(18,2) NULL
);
GO

/* =========================================================
   Índices (Performance)

   🔗 Referência:
   - Documento: 05_entrega_valor.md
   - Seção: Performance
   ========================================================= */

-- Índice para consultas analíticas por conta e data
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_ftResultado_IDConta_Data'
      AND object_id = OBJECT_ID('dbo.ftResultado')
)
BEGIN
    CREATE INDEX IX_ftResultado_IDConta_Data
        ON dbo.ftResultado (ID_Conta, [Data]);
END
GO

-- Índice para otimizar joins e buscas na staging
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_stg_Basepdf_CodigoConta'
      AND object_id = OBJECT_ID('dbo.stg_Basepdf')
)
BEGIN
    CREATE INDEX IX_stg_Basepdf_CodigoConta
        ON dbo.stg_Basepdf (CodigoConta);
END
GO

-- Índice para integração com plano de contas
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_stg_PlanoConta_IDConta'
      AND object_id = OBJECT_ID('dbo.stg_PlanoConta')
)
BEGIN
    CREATE INDEX IX_stg_PlanoConta_IDConta
        ON dbo.stg_PlanoConta (ID_Conta);
END
GO
