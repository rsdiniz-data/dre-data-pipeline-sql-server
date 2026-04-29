# 03. Desenvolvimento do Projeto

## 🔄 Pipeline

1. Ingestão (Python)
2. Staging (SQL)
3. Transformação (SQL)
4. Consumo (Power BI)

---

## 📥 Ingestão com Python

Responsável por:

- Leitura de PDFs (DRE)
- Leitura Excel (Plano de Contas)
- Carga no SQL

🔗 Script:  
👉 [01_ingestao_dados.py](../scripts/python/01_ingestao_dados.py)

---

## 🧱 Criação das Tabelas

🔗 Script:  
👉 [01_criar_tabelas.sql](../scripts/sql/01_criar_tabelas.sql)

Inclui:

- Banco `DRE_EMBRAER`
- Staging
- Tabelas finais
- Índices

---

## 🔄 Transformações SQL

🔗 Script:  
👉 [02_transformacoes.sql](../scripts/sql/02_transformacoes.sql)

---

### 📊 dPlanoConta

Regras:

- Hierarquia por tamanho do código
- FillDown com OUTER APPLY
- Criação de N1, N2, N3
- TipoIndicador

📌 Referência técnica:
```sql
-- Referência ao tópico 3.3: Hierarquia de contas
LEN(ID_Conta)
