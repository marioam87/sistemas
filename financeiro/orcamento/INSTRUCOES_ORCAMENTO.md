# Instrucoes do Projeto — Orcamento Pessoal (Mario)

## Arquivo de trabalho
`orcamento_definitivo.xlsm` — macro-enabled workbook, Mac + Windows.

---

## REGRA FUNDAMENTAL: ZERO ACENTOS

Todo o arquivo e completamente livre de acentuacao:
- Valores de celulas, nomes de abas, cabecalhos de coluna de tabela
- Named ranges, formulas, strings no VBA

Isso elimina toda a familia de bugs de encoding Mac/Windows.

Ao adicionar qualquer dado novo, **nunca usar acentos**.
Exemplos corretos: Imoveis, Cartao, Saude, Onix - prestacao, Consorcio,
Responsavel, Periodo, Competencia, Plantoes, Anotacoes.

Ao normalizar celulas via openpyxl, tambem normalizar:
- Nomes de abas
- Nomes de coluna em `xl/tables/tableN.xml`
- Formulas `totalsRowFormula`
- Nomes de estilo em `styles.xml`

Se qualquer um desses for esquecido, o Excel acusa "erro de conteudo" ao abrir.

---

## Toolchain obrigatorio

| Ferramenta | Uso |
|---|---|
| Python + openpyxl (`keep_vba=True`) | Leitura e edicao de celulas/tabelas |
| Zip-level XML surgery | Formatacao, conditional formatting, VBA-safe edits |
| LibreOffice (recalc) | Verificacao de erros de formula apos edicoes |
| `restore_codenames.py` | Restaurar `codeName` apos qualquer recalc |
| `.bas` files | Entrega de modulos VBA para import manual |

### Por que zip-level XML surgery
openpyxl ao salvar reescreve o zip inteiro e pode corromper `vbaProject.bin`.
Para qualquer edicao que envolva VBA ou formatacao avancada: editar diretamente
os XMLs dentro do zip, sem passar pelo save do openpyxl.

### Risco `codeName`
openpyxl E LibreOffice removem atributos `codeName` de worksheets e workbook.
Apos qualquer recalc do LibreOffice: rodar `restore_codenames.py` antes de
devolver o arquivo. Sem isso, os modulos VBA perdem o vinculo com as abas.

---

## Estrutura das abas (16 abas)

| Aba | Descricao |
|---|---|
| Dados | Tabela principal de lancamentos financeiros |
| Mensal | Dashboard mensal (gerado por macro) |
| Fluxo | Imoveis e veiculos (antes "Imoveis"), protegida |
| Anual | Blocos anuais empilhados em ordem decrescente, protegida |
| Anual_bkp | Backup automatico da Anual, oculta |
| Recorrente | Lancamentos recorrentes mensais |
| Pri | Controle financeiro da Pri |
| Pai | Controle financeiro do pai |
| Plantoes | Registro de plantoes medicos |
| Pacientes | Base de ~4.000 pacientes |
| Consultas | Registro de consultas |
| Exames | Registro de exames |
| Anotacoes | Notas livres |
| Magic | Aba auxiliar de calculo |
| Contrato | Contratos ativos |
| Listas | Named ranges e listas de validacao, oculta |

---

## Tabelas (ListObjects)

### ControleFinanceiro — aba Dados, A1:J~3500, 10 colunas
Ano/Mes | Data | Tipo | Categoria | Subcategoria | Anotacoes | Valor | Pagamento | Responsavel | Status

### Recorrente — aba Recorrente, A1:L50, 12 colunas
Ano/Mes | Data | Tipo | Categoria | Subcategoria | Anotacoes | Valor | Pagamento | **Prestacao** | Termino | Responsavel | Status

Obs: Prestacao e Termino sao so controle — NAO exportadas para Dados.
Itens com Valor em branco/zero SAO lancados na Dados de proposito (preenchimento manual ao longo do mes).

### Plantoes — aba Plantoes, A1:E~3000, 5 colunas
Competencia | Data | Dia da Semana | Local de Trabalho | Periodo do Plantao

### TB_Pacientes — aba Pacientes, A1:F4026, 6 colunas
PACIENTE | NASC | IDADE | SEXO | CONVENIO | CLINICA

IDADE e coluna calculada (injetada via XML de tabela).
~4.021 registros de tres clinicas: Clinimarc, Idealprev, Policlinica.

---

## Named ranges (aba Listas)

| Named Range | Conteudo |
|---|---|
| Tipo | Receitas / Despesas |
| Rec_Cat | Categorias de receita |
| Rec_Sub | Subcategorias de receita |
| Desp_Cat | Categorias de despesa |
| Pagamento | Cartao / C6 / Nubank / Pri |
| Responsavel | Mario / Compartilhado / Pri |
| Status | Pago / A pagar |
| Dia_Semana | domingo a sabado |
| Periodo_Plantao | turnos de plantao |
| Carga_Horaria | cargas horarias |

Named ranges de subcategoria por categoria de despesa (usados via INDIRECT nos dropdowns):
Alimentacao, Casa, Compras, Educacao, Empresa, Imoveis, Impostos, Lazer, Saude, Servicos, Seguros, Transporte

Obs: o named range de subcategorias de imoveis chama-se "Imoveis" (sem conflito porque a aba foi renomeada para "Fluxo").

---

## Modulos VBA

### Modulo_Principal.bas
Macros principais:

| Macro | Descricao |
|---|---|
| GerarDashboard | Gera dashboard mensal na aba Mensal. Pergunta mes (YYYY-MM). Limpa A8:N(fim) — nunca colunas P em diante (preserva tabela Prestacoes em P:Q e auxiliar em S). Chama AtualizarImoveis ao final. |
| GerarDashboardAnual | Gera/regenera bloco anual na aba Anual. Cria backup em Anual_bkp antes de alterar. Blocos em ordem decrescente. Botao "Gerar Anual" recriado free-floating em O3. |
| LancarRecorrentes | Copia tabela Recorrente para Dados no mes informado. Colunas Prestacao/Termino nao sao exportadas. Responsavel e Status vem das colunas 10 e 11 da Recorrente (nao 9 e 10). |
| OrdenarDados | Ordena tabela da aba ativa por Data crescente. |
| LimparFiltros | Limpa filtros e reexibe todas as linhas. |
| ValidarDados | Varre ControleFinanceiro e aponta ate 25 inconsistencias (Ano/Mes x Data, ordem, Tipo, sinal Valor, Categoria fora de lista). |
| AtualizarImoveis | Alimenta aba Fluxo a partir dos lancamentos de Imoveis/Transporte na Dados. Config em col BJ (62), linhas 4-12. Usa Collection (nao Scripting.Dictionary) para compatibilidade Mac. |
| CriarBotoes | Recria todos os botoes em todas as abas. |
| ReativarEventos | Restaura EnableEvents/ScreenUpdating/Calculation — usar se duplo clique parar de responder. |

Helpers privados: AsciiKey, FindKey, FindKey1, ColIndex, FmtRow, RenderCart, CartMatch, PlacarAnual, CabecalhoAnual, LinhaAnual, TotalAnual, GarantirBotaoAnual, AtuFixaSimples, AtuFixaDupla, AtuAberta, FmtLinhaImv, FmtTotImv, AddBtnAt, AddBtn.

### Modulo_DuploClique_v3.bas
Colado em **EstaPasta_de_trabalho** (ThisWorkbook), nao em modulo de planilha.
Evento: `Workbook_SheetBeforeDoubleClick`

- Age apenas nas abas: Dados, Plantoes, Recorrente
- Coluna B (Data), linha > 1
- Abre InputBox de data (dd/mm/aaaa)
- Preenche Ano/Mes na coluna A
- Em Plantoes: preenche dia da semana na coluna C (sem acentos: Terca, Sabado)
- Formata a linha inteira (Arial 12, centralizado, bordas, fundo branco)
- lastCol por aba: Dados=10, Recorrente=11, Plantoes=5
- Usa `Sh` (parametro do evento), nunca `Me` — por isso funciona no ThisWorkbook

---

## Aba Fluxo (imoveis e veiculos)

Configuracao em BJ3:BQ12 (col 62, linhas 4-12):

| Offset | Campo |
|---|---|
| +0 | Nome do bloco (BJ) |
| +1 | Categoria |
| +2 | Subcategorias (separadas por pipe) |
| +3 | Responsaveis |
| +4 | Tipo: FIXA ou ABERTA |
| +5 | Coluna de inicio do bloco |
| +6 | Linha de inicio dos dados |
| +7 | Cor do banner (hex sem #) |

Tipos de bloco:
- **FIXA sem responsavel**: consorcios simples (ex: Compass 208) — chave cat|sub|comp
- **FIXA com responsavel**: consorcios duplos Mario+Pri — chave cat|sub|resp|comp
- **ABERTA**: Onix e Lange (prestacao + prazo, Mario + Pri) — regenera linhas dinamicamente

---

## Aba Anual

- Titulo de bloco: `"Dashboard Anual - YYYY"`
- Placar no topo: RECEITA (verde), DESPESA (vermelho), SALDO (azul)
- Cabecalho de meses: JAN FEV MAR ABR MAI JUN JUL AGO SET OUT NOV DEZ (meses com * = trimestre)
- Colunas por bloco: Categoria (A) | Subcategoria (B) | JAN..DEZ (C..N) | MENSAL (O) | ANUAL (P)
- Linhas de total: "Total de Receitas" (verde), "Total de Despesas" (vermelho), "Saldo do Mes" (azul), "Saldo Acumulado" (navy)
- Aba protegida apos geracao; botao em O3 e free-floating (xlFreeFloating) para nao sumir com Insert/Delete de linhas
- Despesas da Pri ficam fora do dashboard anual
- Tabela "Evolucao Salarial" em col R, linha 1: Ano | Anual | Mensal (2015-2026, com calculo proporcional por meses trabalhados)

---

## Aba Mensal

- Linha 1: titulo "Dashboard Financeiro - YYYY-MM"
- Linhas 3-4: KPIs (Receitas em A3:C4, Despesas em E3:G4, Saldo em I3:K4)
- Linhas 6-7: cabecalhos de secao
- Linha 8+: dados gerados pela macro (A:N apenas — P em diante intocado)
- Colunas P:Q: tabela Prestacoes (reposicionada de row 5 para row 1, dados em P3:Q38)
- Coluna S: auxiliar
- Botao "Gerar Mensal" em M3

Tabelas de cartao (cols I..N) em cascata, so referencia (valores ja estao em Despesas):
CARTAO | NUBANK | C6 | CARTAO - PRI | PRI

Logica CartMatch por modo:
- PAG_CARTAO: pag=Cartao, res=Mario ou Compartilhado
- PAG_NUBANK: pag=Nubank, res=Mario
- PAG_C6: pag=C6, res=Mario
- PRI_COMP: (pag=C6, res=Pri) ou (pag=Cartao, res=Compartilhado)
- PRI: pag=Pri, res=Mario

Obs: Nubank/Pri ficam intencionalmente vazios ate julho (inicio de uso).

---

## Formatacao padrao

- Fonte: Arial 12 (dados), Arial 11 (dashboard)
- Alinhamento: centralizado horizontal e vertical
- Cabecalhos: `#1B4F72` fill, texto branco bold
- Bordas: xlContinuous, xlThin, preto
- Numero: `#,##0` ou `#,##0.00` conforme contexto
- Data: `[$-416]d/mmm/yy;@`
- Valor: `#,##0;[Red]#,##0`

---

## Armadilhas conhecidas

| Problema | Causa | Solucao |
|---|---|---|
| `codeName` sumindo | openpyxl ou LibreOffice removem o atributo | Rodar `restore_codenames.py` apos todo recalc |
| VBA nao encontra aba | Modulo de duplo clique colado no lugar errado | Colar em EstaPasta_de_trabalho, usar `Sh` nao `Me` |
| Duplo ThisWorkbook | Import/conversao cria `EstaPastaDeTrabalho` duplicado | Verificar `ThisWorkbook.CodeName` no Immediate Window |
| `val` como variavel | Conflito com VBA built-in `Val()` | Usar `valor` |
| `CDbl` em celula vazia | Type error | Usar `Val(cell & "")` |
| Clear destroi Prestacoes | Full-row clear apaga P:Q | Limpar so `A8:N(fim)` |
| Botao Anual sumindo | Insert/Delete de linhas move botao ancorado | Usar `xlFreeFloating` |
| Tabela Recorrente: 12 colunas | Prestacao e Termino existem entre Pagamento e Responsavel | Responsavel = col 11, Status = col 12; no LancarRecorrentes: `src.Cells(1,10)` = Responsavel, `src.Cells(1,11)` = Status |
| `Scripting.Dictionary` | So existe no Windows | Usar `Collection` + `ColIndex()` helper |
| openpyxl strips VBA | Save normal reescreve o zip | Sempre usar zip surgery para edits VBA-safe |
| LibreOffice reseta largura de colunas | Recalc padroniza tudo | Reaplicar larguras apos recalc sem novo recalc |
| Conditional formatting fora do range | Regras ficam ancoradas ao range antigo no XML | Atualizar manualmente via XML do sheet apos mover tabelas |
