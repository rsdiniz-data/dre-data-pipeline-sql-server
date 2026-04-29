/* =========================================================
   01_CRIAR_TABELAS.sql
   Projeto: DRE Embraer com SQL Server
   Objetivo:
   - Criar banco de dados
   - Criar tabelas de staging
   - Criar tabelas finais do modelo dimensional
   ========================================================= */

IF DB_ID('DRE_EMBRAER') IS NULL
BEGIN
    CREATE DATABASE DRE_EMBRAER;
END
GO

USE DRE_EMBRAER;
GO

/* =========================================================
   Tabelas de staging
   ========================================================= */

IF OBJECT_ID('dbo.stg_Basepdf', 'U') IS NOT NULL
    DROP TABLE dbo.stg_Basepdf;
GO

CREATE TABLE dbo.stg_Basepdf (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ArquivoOrigem NVARCHAR(255) NULL,
    CodigoConta NVARCHAR(50) NULL,
    DescricaoConta NVARCHAR(500) NULL,
    Valor_2022 NVARCHAR(100) NULL,
    Valor_2021 NVARCHAR(100) NULL,
    Valor_2024 NVARCHAR(100) NULL,
    Valor_2023 NVARCHAR(100) NULL,
    DataCarga DATETIME NOT NULL DEFAULT GETDATE()
);
GO

IF OBJECT_ID('dbo.stg_PlanoConta', 'U') IS NOT NULL
    DROP TABLE dbo.stg_PlanoConta;
GO

CREATE TABLE dbo.stg_PlanoConta (
    RowNum INT NOT NULL,
    ID_Conta NVARCHAR(50) NULL,
    Lancamento INT NULL,
    Descricao NVARCHAR(500) NULL,
    Calculado INT NULL,
    DataCarga DATETIME NOT NULL DEFAULT GETDATE()
);
GO

/* =========================================================
   Tabelas finais
   ========================================================= */

IF OBJECT_ID('dbo.dPlanoConta', 'U') IS NOT NULL
    DROP TABLE dbo.dPlanoConta;
GO

CREATE TABLE dbo.dPlanoConta (
    ID_Conta NVARCHAR(50) NOT NULL PRIMARY KEY,
    Lancamento INT NULL,
    Descricao NVARCHAR(500) NULL,
    N1 NVARCHAR(500) NULL,
    N2 NVARCHAR(500) NULL,
    N3 NVARCHAR(500) NULL,
    CodDRE NVARCHAR(50) NULL,
    Calculado INT NULL,
    TipoIndicador INT NULL
);
GO

IF OBJECT_ID('dbo.ftResultado', 'U') IS NOT NULL
    DROP TABLE dbo.ftResultado;
GO

CREATE TABLE dbo.ftResultado (
    ID_Conta NVARCHAR(50) NOT NULL,
    [Data] DATE NOT NULL,
    Valor DECIMAL(18,2) NULL
);
GO

/* Índices úteis */
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
