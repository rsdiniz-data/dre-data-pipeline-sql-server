# 📊 DRE Embraer | Arquitetura SQL Server + Power BI

Evoluí meu projeto de DRE em Power BI para uma arquitetura baseada em SQL Server.

No primeiro momento, os dados vinham direto de arquivos (PDF e Excel), o que funcionava… mas trazia limitações como dependência de arquivos, risco de quebra e pouca governança.

Nesta nova versão, construí um pipeline estruturado:

• Ingestão de dados com Python  
• Armazenamento em SQL Server  
• Modelagem em camadas (staging e camada analítica)  
• Transformações centralizadas no SQL  

Com isso, o Power BI passa a consumir dados já tratados, ganhando performance e confiabilidade.

Além disso, a centralização evita o desperdício de processamento repetitivo no Power BI.

Mais do que uma evolução técnica, foi a transição de um modelo baseado em arquivos para uma arquitetura de dados mais robusta e escalável.

---

## 📌 Navegação

- 📄 [Justificativa](./docs/01_justificativa.md)
- 🏗️ [Arquitetura](./docs/02_arquitetura.md)
- ⚙️ [Desenvolvimento](./docs/03_desenvolvimento.md)
- 💡 [Entrega de Valor](./docs/04_entrega_valor.md)
- 📊 [Dicionário de Dados](./docs/05_dicionario_dados.md)

---

## 📊 Arquitetura

- SQL Server como camada central
- Python para ingestão
- Modelo dimensional (Star Schema)
- Power BI como camada de consumo

📷 ![Modelo](./images/modelo_star_schema.png)

---

## 🔄 Pipeline

Python → Staging → Transformações SQL → Camada Analítica → Power BI

---

## 💻 Scripts

- 📥 [Ingestão Python](./scripts/python/01_ingestao_dados.py)
- 🧱 [Criação de tabelas](./scripts/sql/01_criar_tabelas.sql)
- 🔄 [Transformações](./scripts/sql/02_transformacoes.sql)

---

## 📈 KPIs

- Receita Líquida
- Lucro Bruto
- Margem
- Variação YoY

---

## 🔮 Simulações

- Impacto de Receita
- Impacto de Custos
- Cenários What-If no Power BI

---

## 💡 Valor para o Negócio

- Centralização de dados  
- Redução de risco operacional  
- Escalabilidade  
- Governança  

---

## 📢 Links

📊 [Acessar dashboard interativo](#)  
📢 [Ler artigo completo](#)

---

## 🚀 Evoluções Futuras

- Data Warehouse em Cloud (Azure / AWS)
- Orquestração com Airflow
- APIs financeiras
- Camada semântica (dbt)

---

## ✅ Conclusão

Este projeto demonstra a transição de um BI tradicional para uma arquitetura moderna de dados, com foco em escalabilidade, governança e performance.
