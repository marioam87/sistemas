# Orçamento pessoal — Regras do sistema

Planilha de orçamento pessoal (.xlsm). Finalizada em jun/2026.

## Arquivos desta pasta

- `vba/` — módulos `.bas` versionados **(colar aqui)**
- a planilha `.xlsm` em si **fica fora do Git** se contiver dados sensíveis
- `REGRAS.md` — este arquivo

## Abas

Dados · Mensal · Anual · Recorrente · Plantões · Listas · (Fluxo/Imóveis)

## Agrupamentos dos cards do dashboard

| Card | Regra |
|---|---|
| CARTÃO | pag. Cartão + (Mario **ou** Compartilhado) |
| NUBANK | Nubank + Mario |
| C6 | C6 + Mario |
| CARTÃO-PRI | (C6 + Pri) **ou** (Cartão + Compartilhado) |
| PRI | Pri + Mario |

## VBA

- **100% ASCII com `ChrW()`** (Mac). Entregar como `.bas` para colar manualmente.

## Aba Fluxo/Imóveis

- Macro `AtualizarImoveis` dentro de "Gerar Mensal".
- Tabela de configuração cruza a aba Dados por **cat / subcat / resp / competência**.
- **Consórcios:** opção B.
- **Ônix/Lange:** colunas Prestação/Prazo × Mario/Pri; status único (Pago só quando tudo pago);
  totais de coluna; Saldo = Pri − Mario.
- **208/Compass:** apenas Total Pago e A Pagar.
- Arial 11; cada bloco com cor distinta; abas protegidas. Manter "prazo".
- **AutoFit** em Dados, Imóveis e Recorrente.
- **Excluir** da aba Imóveis as subcats "Ônix" avulsa e "Vitra".
