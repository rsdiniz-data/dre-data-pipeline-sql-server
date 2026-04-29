# 01. Justificativa do Projeto

## 🎯 Problema

O modelo inicial baseado em arquivos apresentava limitações:

- Dependência de arquivos locais
- Risco de quebra do relatório
- Baixa governança
- Processamento repetitivo no Power BI

## 💡 Solução

Migrar para uma arquitetura baseada em SQL Server:

- Centralização dos dados
- Separação de responsabilidades
- Regras de negócio no banco

## 🔗 Rastreabilidade

📥 Ingestão: [Script Python](../scripts/python/01_ingestao_dados.py)  
🧱 Estrutura: [Script SQL](../scripts/sql/01_criar_tabelas.sql)
