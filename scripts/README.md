# 💻 Scripts do Projeto

Esta pasta contém os scripts responsáveis pelo pipeline de dados.

## 🔄 Pipeline

1. Ingestão (Python)
2. Staging (SQL)
3. Transformações (SQL)

## 📂 Estrutura

### 🐍 Python
- [01_ingestao_dados.py](./python/01_ingestao_dados.py)

Responsável por:
- Extração de PDFs
- Leitura de Excel
- Carga no SQL Server

---

### 🧱 SQL
- [01_criar_tabelas.sql](./sql/01_criar_tabelas.sql)
- [02_transformacoes.sql](./sql/02_transformacoes.sql)

Responsável por:
- Estrutura do banco
- Modelagem dimensional
- Regras de negócio

## 🔗 Integração com Docs

Ver detalhes em:
👉 ../docs/03_desenvolvimento.md
