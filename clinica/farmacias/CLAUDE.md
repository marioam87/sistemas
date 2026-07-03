# Comparação de preços — Farmácias de Curitiba

Ferramenta web (HTML autocontido) de comparação de preços de medicamentos
entre farmácias de Curitiba-PR. Funciona sozinha, aberta no navegador, usando
a API da Anthropic com busca na web.

## Arquivos desta pasta

- `farmapreco_cwb_v2.html` — a ferramenta (versão oficial atual)
- `CLAUDE.md` — este arquivo (regras e contexto do projeto)

## O que a ferramenta cobre

- Busca de preços em **redes de farmácia de Curitiba-PR, em camadas**.
- **Validação de apresentação** (dosagem, quantidade, forma).
- **Preço por unidade** (por comprimido ou dose).
- **Programas PBM** (benefício em medicamento) — a partir de tabela fixa.
- Alternativas **genéricas / similares** intercambiáveis.
- **Filtragem por disponibilidade em Curitiba**.

## Farmácias — em camadas

- **Camada 1 (buscar sempre — fontes confiáveis):** Droga Raia, Callfarma,
  Panvel, Pague Menos, Drogaria Catarinense.
- **Camada 2 (só se a Camada 1 retornar menos de 3 preços):** Morifarma,
  Preço Popular, Unipreço.
- **Nissei:** não é pesquisada online (exige login/CPF). Registrar apenas
  "Nissei: consultar no app".
- **Consulta Remédios:** não usar como fonte de preço (carrega via
  JavaScript, não confiável).

## Regras absolutas

- **Exclusão de fabricantes:** nunca incluir EMS (**exceto Ozivy**, que é
  permitido), Brace Pharma, Cimed ou Teuto — nem genérico, nem similar.
- **Semaglutida:** sempre comparar Wegovy, Poviztra e Ozivy na mesma dose.
- **Sacubitril-valsartana:** sempre comparar Entresto e Neparvis na mesma dose.
- **Rosuvastatina** (isolada e com ezetimiba): apenas comprimidos — excluir
  qualquer marca/laboratório em cápsula.
- **Validação de apresentação:** só corrigir/perguntar se a dose ou
  quantidade pedida claramente não existir no Brasil; não gastar buscas
  revalidando apresentações padrão de mercado.

## PBM — tabela fixa (não pesquisar)

Preencher a partir desta tabela; um item por marca comparada que tenha
programa. Se nenhuma marca tiver PBM, a lista fica vazia.

- **Entresto/Neparvis (Novartis):** Vale Mais Saúde — valemaissaude.com.br,
  cadastro por CPF; desconto cheio a partir da 2ª compra (1ª via Kit Adesão,
  receita de uso contínuo).
- **Wegovy (Novo Nordisk):** Novo Dia — programanovodia.com.br, CPF, rede
  credenciada, retém receita. Preço volátil desde a queda de patente
  (mar/2026).
- **Ozivy (EMS):** Vida + Leve — cerca de R$ 287/mês nos 3 primeiros meses.
- **Mounjaro / Tirzepatida (Lilly):** Lilly Melhor Para Você —
  lillyparavoce.com.br, CPF.
- **Crestor / Rosuvastatina (AstraZeneca):** Faz Bem — fazbem.com.br.
- **Euthyrox / Levotiroxina (Merck):** Merck Cuida — 25% só na 1ª caixa,
  1x por CPF (não é recorrente).
- **Zoloft / Sertralina (Viatris):** Se Cuida — desconto por CPF no balcão.

## Lista monitorada

- Semaglutida 1 mg e 2,4 mg (Wegovy / Poviztra / Ozivy)
- Tirzepatida 2,5 mg e 5 mg (Mounjaro) — 1 caneta
- Sacubitril-valsartana 50 / 100 / 200 mg (Entresto / Neparvis) — 60 cp
- Sertralina 50 mg e 100 mg — 30 cp
- Levotiroxina 88 mcg (Euthyrox) — 42 cp
- Rosuvastatina 20 mg — 30 cp (comprimidos)
- Rosuvastatina + Ezetimiba 20/10 mg e 40/10 mg — 30 cp (comprimidos)
