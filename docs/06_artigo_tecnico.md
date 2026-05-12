# 6. Artigo Técnico – DRE Embraer com SQL Server

Este artigo apresenta a evolução de uma solução de análise financeira da DRE da Embraer, migrando de um modelo baseado em arquivos no Power BI para uma arquitetura estruturada em SQL Server.

A solução foi construída utilizando dados públicos em PDF e Excel, com foco em centralização dos dados, governança, performance e organização do pipeline analítico.

## 🔗 Acesse o artigo completo

👉 [Ler no LinkedIn](https://www.linkedin.com/pulse/de-arquivos-para-sql-server-evolu%25C3%25A7%25C3%25A3o-uma-dre-em-power-ricardo-diniz-lb2vf/)

---

## 🧠 O que você vai encontrar no artigo

- Contexto e problema de negócio
- Limitações do modelo baseado em arquivos
- Evolução da arquitetura para SQL Server
- Pipeline de ingestão com Python
- Estruturação das camadas de dados
- Transformações centralizadas no SQL
- Modelagem dimensional (Star Schema)
- Integração com Power BI
- Ganhos de performance, governança e escalabilidade

---

## 🔄 Relação com este repositório

Este repositório contém a implementação prática da solução apresentada no artigo:

- Scripts Python de ingestão  
- Estruturas SQL (staging e camada analítica)  
- Procedures de transformação  
- Modelo dimensional (`dPlanoConta` e `ftResultado`)  
- Integração com Power BI  

---

## ⚡ Destaques da evolução

- Centralização das regras de negócio no SQL Server
- Redução do processamento no Power BI
- Arquitetura mais organizada e escalável
- Separação entre ingestão, transformação e consumo
- Melhoria significativa no tempo de refresh

---

## 🎯 Por que ler o artigo?

O artigo complementa este repositório ao explicar não apenas a implementação técnica, mas também as decisões de arquitetura, os desafios encontrados e a evolução da solução sob a perspectiva de Engenharia de Dados.
