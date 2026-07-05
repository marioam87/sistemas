# Milhas — Regras do sistema

Fluxo de caixa do negócio de trading de milhas. Excel (.xlsm) separado do orçamento pessoal.

## Arquivos desta pasta

- `create_milhas.py` — gera a planilha nova (abas dados/estoque)
- `vba/mod_milhas.bas` — módulo VBA **(colar aqui a versão oficial)**
- `titulares_config.json` — nomes reais dos titulares (fora do Git, ver `.gitignore`)
- a planilha `.xlsm` fica fora do Git se contiver dados sensíveis
- `CLAUDE.md` — este arquivo

## Abas

`anual` · `dados` · `estoque`

## Convenções de dados

- **Base financeira = data de PAGAMENTO** (não a data da transação).
- Valores de **TIPO sem acento**: `ENTRADA` / `SAIDA`.
- **VALOR BRUTO sempre positivo**.

## Módulo `mod_milhas`

Subs para: atualização de dados, navegação de ano, controle de parcelas,
validação, ordenação e gráfico combinado.

## Intervalos nomeados dinâmicos

- `DadosPAG`, `DadosTIPO`, `DadosVAL`
- Usam `INDEX` / `COUNTA` para performance.

## VBA

- **100% ASCII com `ChrW()`** (Mac). Entregar como `.bas`.
