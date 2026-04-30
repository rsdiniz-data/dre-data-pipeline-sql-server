# 1. Justificativa do Projeto

## 🎯 Problema

Os dados da DRE são disponibilizados em relatórios financeiros (PDF e Excel), sem estrutura pronta para análise.

O modelo inicial baseado em arquivos apresentava limitações:

- Dependência de arquivos locais  
- Risco de quebra do relatório  
- Baixa governança  
- Processamento repetitivo no Power BI  

## 💡 Solução

Migrar para uma arquitetura baseada em SQL Server, com pipeline estruturado:

- Centralização dos dados  
- Separação de responsabilidades  
- Regras de negócio no banco de dados  
- Preparação para escalabilidade  

## 🔗 Rastreabilidade

- 📥 Ingestão: [Ver Script Python](../scripts/python/01_ingestao_dados.py)  
- 🧱 Estrutura: [Ver Script SQL](../scripts/sql/01_criar_tabelas.sql)  
- 🔄 Transformações: [Ver Script SQL](../scripts/sql/02_transformacoes.sql)
