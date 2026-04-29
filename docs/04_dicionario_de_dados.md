# 04. Dicionário de Dados

## 📊 dPlanoConta

| Coluna        | Tipo        | Descrição                         | Relacionamentos |
|--------------|------------|----------------------------------|-----------------|
| `ID_Conta`   | NVARCHAR   | Código da conta                  | 1:N → ftResultado |
| `Descricao`  | NVARCHAR   | Nome da conta                    | - |
| `N1`         | NVARCHAR   | Nível 1                          | - |
| `N2`         | NVARCHAR   | Nível 2                          | - |
| `N3`         | NVARCHAR   | Nível 3                          | - |
| `CodDRE`     | NVARCHAR   | Código principal                 | - |
| `TipoIndicador` | INT     | Receita (+1) / Despesa (-1)      | - |

🔗 Script:  
👉 [02_transformacoes.sql](../scripts/sql/02_transformacoes.sql)

---

## 📈 ftResultado

| Coluna      | Tipo        | Descrição              | Relacionamentos |
|------------|------------|------------------------|-----------------|
| `ID_Conta` | NVARCHAR   | Conta contábil         | N:1 → dPlanoConta |
| `Data`     | DATE       | Data (ano)             | - |
| `Valor`    | DECIMAL    | Valor financeiro       | - |

🔗 Script:  
👉 [02_transformacoes.sql](../scripts/sql/02_transformacoes.sql)
