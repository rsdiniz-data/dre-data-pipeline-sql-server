-- =========================================================
-- 🔹 TRANSFORMAÇÕES
-- =========================================================

/* =========================================================
   02_TRANSFORMACOES.sql
   Projeto: DRE Embraer com SQL Server

   Objetivo:
   - Replicar no SQL Server as regras de transformação
     originalmente feitas no Power Query
   - Criar procedures de transformação

   🔗 Rastreabilidade:
   - Documento: ../docs/03_desenvolvimento.md
   - Seção: Transformações SQL
   ========================================================= */

USE DRE_EMBRAER;
GO

/* =========================================================
   Procedure: dPlanoConta

   🔗 Referência:
   - 03_desenvolvimento.md → Transformações dPlanoConta
   - 02_arquitetura.md → Modelo Dimensional

   Regras:
   - Hierarquia contábil
   - FillDown
   - Classificação financeira
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_Criar_dPlanoConta
AS
BEGIN
    SET NOCOUNT ON;

    -- Referência: Reprocessamento controlado (pipeline idempotente)
    TRUNCATE TABLE dbo.dPlanoConta;

    ;WITH Base AS (
        SELECT
            RowNum,

            -- Referência: Padronização de dados (limpeza)
            LTRIM(RTRIM(ID_Conta)) AS ID_Conta,
            Lancamento,
            LTRIM(RTRIM(Descricao)) AS Descricao,
            Calculado,

            -- Referência: 3.4.1 → Identificação da hierarquia
            LEN(LTRIM(RTRIM(ID_Conta))) AS Comprimento
        FROM dbo.stg_PlanoConta
    ),

    -- Referência: 3.4.1.2 → Criação dos níveis hierárquicos
    Marcacoes AS (
        SELECT
            RowNum,
            ID_Conta,
            Lancamento,
            Descricao,
            Calculado,
            Comprimento,

            -- Nível 1 (Grupo)
            CASE
                WHEN Comprimento = 4 THEN Descricao
                ELSE NULL
            END AS N1_Base,

            -- Nível 2 (Subgrupo)
            CASE
                WHEN Comprimento = 7 THEN Descricao
                WHEN Comprimento = 4 THEN 'XXX'
                ELSE NULL
            END AS N2_Base,

            -- Nível 3 (Conta analítica)
            CASE
                WHEN Comprimento = 10 THEN Descricao
                ELSE NULL
            END AS N3,

            -- Código principal da DRE
            CASE
                WHEN Comprimento = 4 THEN ID_Conta
                ELSE NULL
            END AS CodDRE_Base
        FROM Base
    )

    INSERT INTO dbo.dPlanoConta (
        ID_Conta,
        Lancamento,
        Descricao,
        N1,
        N2,
        N3,
        CodDRE,
        Calculado,
        TipoIndicador
    )
    SELECT
        m.ID_Conta,
        m.Lancamento,
        m.Descricao,

        -- Referência: 3.4.1.3 → FillDown (equivalente ao Power Query)
        n1.N1,

        -- Remoção do marcador técnico
        NULLIF(n2.N2, 'XXX') AS N2,

        m.N3,

        -- Referência: Agrupamento da DRE
        cd.CodDRE,

        m.Calculado,

        -- Referência: 3.4.1.5 → Classificação financeira
        CASE
            WHEN cd.CodDRE IN ('3.02', '3.04') THEN -1 -- Custos/Despesas
            ELSE 1 -- Receita/Resultado
        END AS TipoIndicador

    FROM Marcacoes m

    -- FillDown N1
    OUTER APPLY (
        SELECT TOP 1 m1.N1_Base AS N1
        FROM Marcacoes m1
        WHERE m1.RowNum <= m.RowNum
          AND m1.N1_Base IS NOT NULL
        ORDER BY m1.RowNum DESC
    ) n1

    -- FillDown N2
    OUTER APPLY (
        SELECT TOP 1 m2.N2_Base AS N2
        FROM Marcacoes m2
        WHERE m2.RowNum <= m.RowNum
          AND m2.N2_Base IS NOT NULL
        ORDER BY m2.RowNum DESC
    ) n2

    -- FillDown CodDRE
    OUTER APPLY (
        SELECT TOP 1 m3.CodDRE_Base AS CodDRE
        FROM Marcacoes m3
        WHERE m3.RowNum <= m.RowNum
          AND m3.CodDRE_Base IS NOT NULL
        ORDER BY m3.RowNum DESC
    ) cd

    ORDER BY m.RowNum;
END;
GO

/* =========================================================
   Procedure: ftResultado

   🔗 Referência:
   - 03_desenvolvimento.md → Transformações ftResultado

   Regras:
   - Unpivot
   - Conversão de valores
   - Integração com dimensão
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_Criar_ftResultado
AS
BEGIN
    SET NOCOUNT ON;

    -- Referência: Reprocessamento controlado
    TRUNCATE TABLE dbo.ftResultado;

    ;WITH Base AS (
        SELECT
            -- Referência: Padronização de chave
            LTRIM(RTRIM(CodigoConta)) AS ID_Conta,
            DescricaoConta,

            -- Referência: Estrutura original (pré-unpivot)
            Valor_2022,
            Valor_2021,
            Valor_2024,
            Valor_2023
        FROM dbo.stg_Basepdf
    ),

    -- Referência: 3.4.2.2 → Unpivot (transformação crítica)
    UnpivotBase AS (
        SELECT
            ID_Conta,
            DescricaoConta,
            DataRef,
            ValorTexto
        FROM Base
        UNPIVOT (
            ValorTexto FOR DataRef IN (
                Valor_2022,
                Valor_2021,
                Valor_2024,
                Valor_2023
            )
        ) u
    ),

    -- Referência: 3.4.2.3 → Conversão de valores financeiros
    AjusteTipos AS (
        SELECT
            ID_Conta,
            DescricaoConta,

            -- Referência: 3.4.2.4 → Padronização temporal
            CASE
                WHEN DataRef = 'Valor_2022' THEN CAST('2022-12-31' AS DATE)
                WHEN DataRef = 'Valor_2021' THEN CAST('2021-12-31' AS DATE)
                WHEN DataRef = 'Valor_2024' THEN CAST('2024-12-31' AS DATE)
                WHEN DataRef = 'Valor_2023' THEN CAST('2023-12-31' AS DATE)
            END AS [Data],

            -- Conversão robusta de valores financeiros
            TRY_CONVERT(
                DECIMAL(18,2),
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(LTRIM(RTRIM(ValorTexto)), '.', ''),
                                    ',', '.'
                                ),
                                '(', '-'
                            ),
                            ')', ''
                        ),
                        ' ', ''
                    ),
                    CHAR(9), ''
                )
            ) AS Valor
        FROM UnpivotBase
    ),

    -- Referência: 3.4.2.5 → Integração com dimensão
    MergePlanoConta AS (
        SELECT
            a.ID_Conta,
            a.[Data],
            a.Valor,
            p.Lancamento
        FROM AjusteTipos a
        LEFT JOIN dbo.dPlanoConta p
            ON a.ID_Conta = p.ID_Conta
    )

    INSERT INTO dbo.ftResultado (
        ID_Conta,
        [Data],
        Valor
    )
    SELECT
        ID_Conta,
        [Data],
        Valor
    FROM MergePlanoConta

    -- Referência: 3.4.2.6 → Filtro de contas analíticas
    WHERE Lancamento = 1

      -- Referência: 3.4.2.7 → Exclusão de período fora do escopo
      AND [Data] <> '2021-12-31';
END;
GO

/* =========================================================
   Procedure mestre do processo

   🔗 Referência:
   - 03_desenvolvimento.md → Orquestração
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.sp_Processar_DRE_Embraer
AS
BEGIN
    SET NOCOUNT ON;

    -- Execução sequencial do pipeline analítico
    EXEC dbo.sp_Criar_dPlanoConta;
    EXEC dbo.sp_Criar_ftResultado;
END;
GO

/* =========================================================
   Queries de validação

   🔗 Referência:
   - 03_desenvolvimento.md → Validação do pipeline
   ========================================================= */

-- Validação staging
-- SELECT TOP 100 * FROM dbo.stg_Basepdf;
-- SELECT TOP 100 * FROM dbo.stg_PlanoConta ORDER BY RowNum;

-- Validação dimensão
-- SELECT TOP 200 * FROM dbo.dPlanoConta ORDER BY ID_Conta;

-- Validação fato
-- SELECT TOP 200 * FROM dbo.ftResultado ORDER BY [Data], ID_Conta;

-- Validação agregada (consistência financeira)
-- SELECT YEAR([Data]) AS Ano, SUM(Valor) AS Total
-- FROM dbo.ftResultado
-- GROUP BY YEAR([Data])
-- ORDER BY Ano;

-- Validação de integridade (contas não mapeadas)
-- SELECT DISTINCT s.CodigoConta
-- FROM dbo.stg_Basepdf s
-- LEFT JOIN dbo.dPlanoConta d
--     ON LTRIM(RTRIM(s.CodigoConta)) = d.ID_Conta
-- WHERE d.ID_Conta IS NULL;

-- Validação da hierarquia
-- SELECT ID_Conta, Descricao, N1, N2, N3, CodDRE, TipoIndicador
-- FROM dbo.dPlanoConta
-- ORDER BY ID_Conta;
