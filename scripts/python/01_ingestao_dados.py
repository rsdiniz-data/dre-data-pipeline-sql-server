```markdown
# 🔹 Ingestão de Dados
```
# =========================================================
# 01_INGESTAO_DADOS.py
# Projeto: DRE Embraer com SQL Server
#
# Objetivo:
# 1. Extrair dados da DRE a partir de PDFs (página 16)
# 2. Ler o Plano de Contas (Excel)
# 3. Carregar dados em tabelas de staging no SQL Server
#
# 🔗 Rastreabilidade:
# - Documento: ../docs/03_desenvolvimento.md
# - Seção: Ingestão de Dados com Python
#
# Tabelas de destino:
# - dbo.stg_Basepdf
# - dbo.stg_PlanoConta
# =========================================================

import os
import re
import sys
import traceback
import pandas as pd
import pdfplumber
from sqlalchemy import create_engine, text

# =========================================================
# CONFIGURAÇÕES
# =========================================================

# Referência: Parametrização do pipeline (evitar hardcoding em produção)
CAMINHO_PASTA = r"D:\DRE Embraer"
CAMINHO_BASES = os.path.join(CAMINHO_PASTA, "Bases")
ARQUIVO_PLANO = os.path.join(CAMINHO_BASES, "PlanoContas.xlsx")

# Referência: Camada de persistência (SQL Server)
SQL_SERVER = "localhost"
DATABASE = "DRE_EMBRAER"
DRIVER = "ODBC Driver 17 for SQL Server"

CONN_STR = (
    f"mssql+pyodbc://@{SQL_SERVER}/{DATABASE}"
    f"?driver={DRIVER.replace(' ', '+')}"
    f"&trusted_connection=yes"
)

engine = create_engine(CONN_STR, fast_executemany=True)

# =========================================================
# FUNÇÕES AUXILIARES
# =========================================================

def log(msg):
    """
    Referência: Observabilidade do pipeline
    """
    print(f"[INFO] {msg}")


def limpar_texto(valor):
    """
    Referência: Padronização de dados (qualidade)

    Remove:
    - espaços extras
    - quebras de linha
    """
    if pd.isna(valor):
        return None

    valor = str(valor).strip()
    valor = valor.replace("\n", " ").replace("\r", " ")
    valor = re.sub(r"\s+", " ", valor)

    return valor if valor else None


def validar_ambiente():
    """
    Referência: Validação pré-execução (boas práticas de pipeline)

    Garante:
    - existência das pastas
    - existência dos arquivos
    """
    print("=" * 80)
    print("VALIDANDO AMBIENTE")
    print(f"Python: {sys.executable}")

    if not os.path.isdir(CAMINHO_BASES):
        raise Exception(f"Pasta Bases não encontrada: {CAMINHO_BASES}")

    if not os.path.isfile(ARQUIVO_PLANO):
        raise Exception(f"Arquivo PlanoContas.xlsx não encontrado: {ARQUIVO_PLANO}")

    print("Ambiente OK")
    print("=" * 80)


# =========================================================
# EXTRAÇÃO PDF (pdfplumber)
# =========================================================

def extrair_texto_pdf(pdf_path, pagina=16):
    """
    Referência: 3.2.1.1 → Extração de dados não estruturados (PDF)

    Objetivo de negócio:
    Transformar relatório financeiro em dado estruturado
    """
    with pdfplumber.open(pdf_path) as pdf:
        indice_pagina = pagina - 1

        if indice_pagina >= len(pdf.pages):
            raise Exception(
                f"O PDF {os.path.basename(pdf_path)} não possui a página {pagina}."
            )

        page = pdf.pages[indice_pagina]
        return page.extract_text()


def linha_valida_dre(linha):
    """
    Referência: 3.2.1.2 → Identificação de linhas válidas

    Regras:
    - Código contábil válido
    - Presença de valores numéricos

    Objetivo:
    Remover ruído do PDF
    """
    if not linha:
        return False

    linha = limpar_texto(linha)
    if not linha:
        return False

    tem_codigo = re.match(r"^\d+(?:\.\d+)+\s+", linha) is not None
    numeros = re.findall(r"\(?-?\d[\d\.,]*\)?", linha)

    return tem_codigo and len(numeros) >= 2


def parsear_linha(linha):
    """
    Referência: 3.2.1.3 → Estruturação dos dados

    Extrai:
    - Código da conta
    - Descrição
    - Valores financeiros
    """
    linha = limpar_texto(linha)

    match = re.match(r"^(\d+(?:\.\d+)+)\s+(.*)", linha)
    if not match:
        return None

    codigo = match.group(1)
    resto = match.group(2)

    numeros = list(re.finditer(r"\(?-?\d[\d\.,]*\)?", resto))
    if len(numeros) < 2:
        return None

    valor_1 = numeros[-2].group()
    valor_2 = numeros[-1].group()

    descricao = resto[:numeros[-2].start()].strip(" -")
    if not descricao:
        return None

    return {
        "CodigoConta": codigo,
        "DescricaoConta": descricao,
        "Valor_1": valor_1,
        "Valor_2": valor_2
    }


def extrair_pdf(pdf_path):
    """
    Referência: 3.2.1 → Pipeline de ingestão

    Fluxo:
    PDF → Texto → Linhas válidas → Estrutura tabular → DataFrame

    Objetivo:
    Preparar dados para staging
    """
    log(f"Processando {pdf_path}")

    texto = extrair_texto_pdf(pdf_path, pagina=16)

    if not texto:
        return None

    linhas = texto.split("\n")
    registros = []

    for linha in linhas:
        if linha_valida_dre(linha):
            reg = parsear_linha(linha)
            if reg:
                registros.append(reg)

    if not registros:
        return None

    df = pd.DataFrame(registros)

    nome_arquivo = os.path.basename(pdf_path)

    # Referência: 3.2.1.4 → Identificação do ano
    df["Valor_2022"] = None
    df["Valor_2021"] = None
    df["Valor_2024"] = None
    df["Valor_2023"] = None

    if "2022" in nome_arquivo:
        df["Valor_2022"] = df["Valor_1"]
        df["Valor_2021"] = df["Valor_2"]
    elif "2024" in nome_arquivo:
        df["Valor_2024"] = df["Valor_1"]
        df["Valor_2023"] = df["Valor_2"]

    # Referência: rastreabilidade de origem
    df["ArquivoOrigem"] = nome_arquivo

    df = df.drop(columns=["Valor_1", "Valor_2"], errors="ignore")

    return df[
        [
            "ArquivoOrigem",
            "CodigoConta",
            "DescricaoConta",
            "Valor_2022",
            "Valor_2021",
            "Valor_2024",
            "Valor_2023"
        ]
    ]


# =========================================================
# LEITURA DO PLANO DE CONTAS
# =========================================================

def ler_plano_conta():
    """
    Referência: 3.2.1.5 → Leitura do Excel

    Objetivo:
    Importar estrutura contábil oficial
    """
    log("Lendo PlanoContas.xlsx")

    xls = pd.ExcelFile(ARQUIVO_PLANO, engine="openpyxl")

    if "PlanoContas" not in xls.sheet_names:
        raise Exception(
            f"A aba 'PlanoContas' não foi encontrada."
        )

    df = pd.read_excel(xls, sheet_name="PlanoContas")

    # Referência: Padronização de colunas
    df = df.rename(columns={
        "ID Conta": "ID_Conta",
        "Lançamento": "Lancamento",
        "Descrição": "Descricao",
        "Calculado": "Calculado"
    })

    df = df[["ID_Conta", "Lancamento", "Descricao", "Calculado"]].copy()

    # Referência: Preservação da hierarquia (ordem do Excel)
    df.insert(0, "RowNum", range(1, len(df) + 1))

    df["ID_Conta"] = df["ID_Conta"].apply(limpar_texto)
    df["Descricao"] = df["Descricao"].apply(limpar_texto)

    return df


# =========================================================
# CARGA SQL
# =========================================================

def carregar_sql(basepdf, plano):
    """
    Referência: 3.2.1.7 → Carga no SQL Server

    Estratégia:
    - TRUNCATE (reprocessamento completo)
    - INSERT (carga controlada)

    Objetivo:
    Garantir consistência da staging
    """
    log("Carregando staging no SQL Server")

    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE dbo.stg_Basepdf"))
        conn.execute(text("TRUNCATE TABLE dbo.stg_PlanoConta"))

    basepdf.to_sql(
        "stg_Basepdf",
        con=engine,
        schema="dbo",
        if_exists="append",
        index=False
    )

    plano.to_sql(
        "stg_PlanoConta",
        con=engine,
        schema="dbo",
        if_exists="append",
        index=False
    )

    log("Carga finalizada com sucesso")


# =========================================================
# MAIN (ORQUESTRAÇÃO)
# =========================================================

def main():
    """
    Referência: 3.5 → Orquestração do pipeline

    Fluxo:
    Validação → Extração → Transformação → Carga
    """
    try:
        validar_ambiente()

        arquivos_pdf = [
            os.path.join(CAMINHO_BASES, f)
            for f in os.listdir(CAMINHO_BASES)
            if f.lower().endswith(".pdf")
        ]

        if not arquivos_pdf:
            raise Exception("Nenhum PDF encontrado.")

        lista_basepdf = []

        for pdf in arquivos_pdf:
            df_pdf = extrair_pdf(pdf)

            if df_pdf is not None and not df_pdf.empty:
                lista_basepdf.append(df_pdf)
            else:
                log(f"Nenhum dado válido em {os.path.basename(pdf)}")

        if not lista_basepdf:
            raise Exception("Nenhum PDF gerou dados.")

        basepdf = pd.concat(lista_basepdf, ignore_index=True)

        print("\nPrévia stg_Basepdf:")
        print(basepdf.head())

        plano = ler_plano_conta()

        print("\nPrévia stg_PlanoConta:")
        print(plano.head())

        carregar_sql(basepdf, plano)

        print("\nPROCESSO FINALIZADO COM SUCESSO")

    except Exception as e:
        print("\nERRO:")
        print(str(e))
        traceback.print_exc()


if __name__ == "__main__":
    main()
