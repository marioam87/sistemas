# Milhas — Regras do sistema

Fluxo de caixa do negócio de trading de milhas. Excel (.xlsm) separado do orçamento pessoal.

## Arquivos desta pasta

- `vba/mod_milhas.bas` — módulo VBA **(colar aqui a versão oficial)**
- a planilha `.xlsm` fica fora do Git se contiver dados sensíveis
- `REGRAS.md` — este arquivo

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
