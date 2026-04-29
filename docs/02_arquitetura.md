# 02. Arquitetura da Solução

## 🎯 Objetivo

Criar uma arquitetura escalável, organizada e rastreável.

## 🧱 Camadas

### Staging
- Dados brutos
- Sem transformação

Tabelas:
- `stg_Basepdf`
- `stg_PlanoConta`

### Camada Analítica
- Modelo dimensional

Tabelas:
- `dPlanoConta`
- `ftResultado`

## ⭐ Modelo Dimensional

- Fato: `ftResultado`
- Dimensão: `dPlanoConta`

Relacionamento:

dPlanoConta (1) → (N) ftResultado

📷 ![Modelo](../images/modelo_star_schema.png)

## 🔗 Rastreabilidade

Transformações:
👉 [02_transformacoes.sql](../scripts/sql/02_transformacoes.sql)
