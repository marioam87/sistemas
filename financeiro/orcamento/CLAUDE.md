# Orcamento Pessoal (Mario) — Regras do sistema

## Arquivos de trabalho

O ecossistema agora tem **dois arquivos `.xlsm` separados**:

| Arquivo | Escopo | Abas |
|---|---|---|
| `orcamento_definitivo.xlsm` | Financeiro pessoal | Dados, Mensal, Fluxo, Anual, Anual_bkp, Recorrente, Pri, Pai, Contrato, Anotacoes, Magic (+ eventualmente Plantoes/Pacientes/Consultas/Exames/Listas — a confirmar, ver nota abaixo) |
| `CONSULTORIO.xlsm` | Consultorio medico (plantoes, pacientes, agenda) | Plantoes, Pacientes, Consultas, Exames, Listas (oculta) |

> **Nota em aberto:** os modulos do Consultorio deixam explicito que as macros
> financeiras (`GerarDashboard`, `LancarRecorrentes`, `AtualizarImoveis`, etc.)
> **nao existem** nesse arquivo — elas ficaram no arquivo financeiro (referenciado
> nos comentarios do modulo como `orcamento_6_6.xlsm`, possivelmente um nome de
> versao anterior a `orcamento_definitivo.xlsm`). Nao esta confirmado se as abas
> Plantoes/Pacientes/Consultas/Exames/Listas foram **removidas** do arquivo
' financeiro ao criar o `CONSULTORIO.xlsm`, ou se ele e apenas uma copia enxuta
> derivada para uso mais leve/portatil. Confirmar com Mario antes de assumir
> qualquer uma das duas hipoteses em futuras edicoes.

> **Privacidade:** ambos os arquivos contem dados sensiveis (aba Pacientes com
> ~4.000 pacientes reais + controle financeiro) e **ficam fora do Git**. Esta
> pasta versiona apenas os modulos VBA (`.bas`) e esta documentacao.

Mario trabalha em Mac (workflow principal) — ver detalhes de compatibilidade
Mac/Windows por arquivo abaixo.

---

## REGRA FUNDAMENTAL: ZERO ACENTOS

Vale para **os dois arquivos**. Todo o conteudo e completamente livre de acentuacao:
- Valores de celulas, nomes de abas, cabecalhos de coluna de tabela
- Named ranges, formulas, strings no VBA

Isso elimina toda a familia de bugs de encoding Mac/Windows.

Ao adicionar qualquer dado novo, **nunca usar acentos**.
Exemplos corretos: Imoveis, Cartao, Saude, Onix - prestacao, Consorcio,
Responsavel, Periodo, Competencia, Plantoes, Anotacoes, Terca, Sabado.

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
| `.bas` files | Entrega de modulos VBA para import manual (Windows) ou colagem direta na VBE (Mac) |

### Por que zip-level XML surgery
openpyxl ao salvar reescreve o zip inteiro e pode corromper `vbaProject.bin`.
Para qualquer edicao que envolva VBA ou formatacao avancada: editar diretamente
os XMLs dentro do zip, sem passar pelo save do openpyxl. Validar via SHA-256
que `vbaProject.bin` permanece byte-a-byte identico.

### Risco `codeName`
openpyxl E LibreOffice removem atributos `codeName` de worksheets e workbook.
Apos qualquer recalc do LibreOffice: rodar `restore_codenames.py` antes de
devolver o arquivo. Sem isso, os modulos VBA perdem o vinculo com as abas.
(O `restore_codenames.py` nao esta versionado aqui — e recriado quando necessario.)

### Regra de entrega de modulos `.bas`
- **Colagem direta na VBE (fluxo padrao do Mario, Mac)**: nunca incluir a linha
  `Attribute VB_Name = "..."` — causa erro de sintaxe ao colar direto no painel
  de codigo da VBE. O dialogo de Import File e quebrado no Mac (bug de sandboxing).
- **Arquivo `.bas` para File > Import (Windows)**: incluir `Attribute VB_Name`
  normalmente. So usar esse formato se explicitamente pedido.

---

# ARQUIVO 1 — orcamento_definitivo.xlsm (financeiro)

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

## Tabelas (ListObjects)

### ControleFinanceiro — aba Dados, A1:J~3500, 10 colunas
Ano/Mes | Data | Tipo | Categoria | Subcategoria | Anotacoes | Valor | Pagamento | Responsavel | Status

### Recorrente — aba Recorrente, A1:L50, 12 colunas
Ano/Mes | Data | Tipo | Categoria | Subcategoria | Anotacoes | Valor | Pagamento | **Prestacao** | Termino | Responsavel | Status

Obs: Prestacao e Termino sao so controle — NAO exportadas para Dados.
Itens com Valor em branco/zero SAO lancados na Dados de proposito (preenchimento manual ao longo do mes).

A tabela `Prestacoes` em Mensal usa SUMIFS contra ranges fixos em Recorrente
(`$G$2:$G$48`, `$I$2:$I$48`, `$N$2:$N$48`), com `$S$1` fazendo o parse do mes
lancado a partir do titulo do dashboard em A1. SUMIFS exige que todos os ranges
tenham exatamente o mesmo tamanho — descasamento silencioso gera `#VALUE!`.

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
| GerarDashboard | Gera dashboard mensal na aba Mensal. Pergunta mes (YYYY-MM). Limpa A8:N(fim) — nunca colunas P em diante (preserva tabela Prestacoes em P:Q e auxiliar em S). Chama SincronizarColunaN no inicio e AtualizarImoveis ao final. |
| SincronizarColunaN | Resincroniza a coluna auxiliar N (indice mes/ano) da aba Recorrente com o tamanho atual da tabela — exclusao de linha na tabela deixa a formula da ultima linha orfa (#REF!) e as demais desalinhadas em 1 linha. Reescreve a formula em toda linha + 1 buffer, sempre auto-referenciada. Roda automatica no inicio de GerarDashboard; tambem tem botao proprio na aba Recorrente. |
| GerarDashboardAnual | Gera/regenera bloco anual na aba Anual. Cria backup em Anual_bkp antes de alterar. Blocos em ordem decrescente. Botao "Gerar Anual" recriado free-floating em O3. |
| LancarRecorrentes | Copia tabela Recorrente para Dados no mes informado. Colunas Prestacao/Termino nao sao exportadas. Responsavel e Status vem das colunas 11 e 12 da Recorrente (nao 9 e 10). |
| OrdenarDados | Ordena tabela da aba ativa por Data crescente. |
| LimparFiltros | Limpa filtros e reexibe todas as linhas. |
| ValidarDados | Varre ControleFinanceiro e aponta ate 25 inconsistencias (Ano/Mes x Data, ordem, Tipo, sinal Valor, Categoria fora de lista). |
| AtualizarImoveis | Alimenta aba Fluxo a partir dos lancamentos de Imoveis/Transporte na Dados. Config em col BJ (62), linhas 4-12. Usa Collection (nao Scripting.Dictionary) para compatibilidade Mac. |
| CriarBotoes | Recria todos os botoes em todas as abas. |
| ReativarEventos | Restaura EnableEvents/ScreenUpdating/Calculation — usar se duplo clique parar de responder. |

Helpers privados: AsciiKey, FindKey, FindKey1, ColIndex, FmtRow, RenderCart, CartMatch, PlacarAnual, CabecalhoAnual, LinhaAnual, TotalAnual, GarantirBotaoAnual, AtuFixaSimples, AtuFixaDupla, AtuAberta, FmtLinhaImv, FmtTotImv, AddBtnAt, AddBtn.

### Modulo_DuploClique_v3.bas
Colado em **EstaPastaDeTrabalho** (ThisWorkbook), nao em modulo de planilha.
Evento: `Workbook_SheetBeforeDoubleClick`

- Age apenas nas abas: Dados, Plantoes, Recorrente
- Coluna B (Data), linha > 1
- Abre InputBox de data (dd/mm/aaaa)
- Preenche Ano/Mes na coluna A
- Em Plantoes: preenche dia da semana na coluna C (sem acentos: Terca, Sabado)
- Formata a linha inteira (Arial 12, centralizado, bordas, fundo branco)
- lastCol por aba: Dados=10, Recorrente=11, Plantoes=5
- Usa `Sh` (parametro do evento), nunca `Me` — por isso funciona no ThisWorkbook

**Cuidado com objetos duplicados:** imports/conversoes podem criar um
`EstaPastaDeTrabalho` duplicado. Antes de colar codigo de evento, confirmar o
objeto ativo real via `? ThisWorkbook.CodeName` na Immediate Window.

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

# ARQUIVO 2 — CONSULTORIO.xlsm (consultorio medico)

Arquivo separado, deliberadamente **enxuto**: contem apenas o que faz sentido
no contexto do consultorio. As macros financeiras (GerarDashboard,
LancarRecorrentes, AtualizarImoveis, dashboards Mensal/Anual, etc.) **nao
existem** neste arquivo.

## Abas
Plantoes, Pacientes, Consultas, Exames, Listas (oculta).

Estrutura de dados dessas abas segue o mesmo padrao do Arquivo 1 (ver
`Plantoes` e `TB_Pacientes` acima) ate confirmacao em contrario.

## Modulos VBA

### Modulo_Principal_Consultorio.bas
Instalado via colagem direta na VBE (Alt+F11 > Inserir > Modulo > colar > Ctrl+S).

| Macro | Descricao |
|---|---|
| LimparFiltros | Limpa AutoFilter/ShowAllData e reexibe linhas ocultas da aba ativa. |
| OrdenarDados | Ordena a tabela da aba ativa pela coluna "Data" (crescente). Botao so faz sentido em Plantoes (unica aba com esse botao). |
| ValidarDados | **Versao Plantoes** (diferente da versao ControleFinanceiro do Arquivo 1): varre a tabela Plantoes conferindo (a) Competencia (col A, yyyy-mm) bate com a Data (col B), (b) ordem cronologica, (c) Dia da Semana (col C) bate com `Weekday(Data)`. Reporta ate 25 problemas. |
| CriarBotoes | Recria os 3 botoes (Limpar Filtros, Ordenar Dados, Validar Dados) na aba Plantoes, empilhados abaixo da tabela. Roda uma vez apos importar os modulos. |
| ReativarEventos | Restaura EnableEvents/ScreenUpdating/Calculation. |

Helper privado: `AddBtnAt(ws, r, col, cap, macroName)`.

### Modulo_DuploClique_Consultorio.bas
Colado em **EstaPasta_de_trabalho** (ThisWorkbook) — **atencao**: este arquivo
usa o nome com underscores (`EstaPasta_de_trabalho`), diferente da grafia usada
no Arquivo 1 (`EstaPastaDeTrabalho`). Confirmar o nome real do objeto via
`? ThisWorkbook.CodeName` antes de colar, igual ao procedimento do Arquivo 1.

Evento: `Workbook_SheetBeforeDoubleClick`

- Age **apenas** na aba Plantoes (mais restrito que o Arquivo 1, que cobre
  Dados/Plantoes/Recorrente)
- Coluna B (Data), linha > 1
- Abre InputBox de data (dd/mm/aaaa)
- Preenche Competencia (coluna A, formato yyyy-mm)
- Preenche Dia da Semana (coluna C) automaticamente, sem acentos (Terca, Sabado)
- Formata a linha inteira A:E (Arial 12, centralizado, bordas, fundo branco)
- Aplica formato de data `[$-416]d/mmm/yy;@`
- Usa `Sh` (parametro do evento), nunca `Me`
- Comentado no proprio modulo: nao depende de Dados/Recorrente nem de nenhuma
  aba que ficou no arquivo financeiro — confirma o isolamento entre os dois arquivos

## Armadilhas especificas do CONSULTORIO.xlsm

| Problema | Causa | Solucao |
|---|---|---|
| Nome do ThisWorkbook diferente entre arquivos | `EstaPasta_de_trabalho` aqui vs `EstaPastaDeTrabalho` no Arquivo 1 | Sempre verificar `? ThisWorkbook.CodeName` antes de colar codigo de evento; nao assumir o mesmo nome entre os dois arquivos |
| ValidarDados com nome igual ao do Arquivo 1 mas logica diferente | Mesma macro-name, escopo diferente (Plantoes vs ControleFinanceiro) | Ao editar, confirmar em qual arquivo/modulo se esta trabalhando antes de portar logica de um para o outro |
| Duplo clique so funciona em Plantoes aqui | Modulo deliberadamente restrito (vs. 3 abas no Arquivo 1) | Nao portar automaticamente o comportamento das 3 abas do Arquivo 1 para este arquivo sem confirmar com Mario |

---

## Armadilhas conhecidas (gerais, ambos os arquivos)

| Problema | Causa | Solucao |
|---|---|---|
| `codeName` sumindo | openpyxl ou LibreOffice removem o atributo | Rodar `restore_codenames.py` apos todo recalc |
| VBA nao encontra aba | Modulo de duplo clique colado no lugar errado | Colar no ThisWorkbook do arquivo correto, usar `Sh` nao `Me` |
| Duplo ThisWorkbook | Import/conversao cria objeto ThisWorkbook duplicado | Verificar `ThisWorkbook.CodeName` no Immediate Window |
| `val` como variavel | Conflito com VBA built-in `Val()` | Usar `valor` |
| `CDbl` em celula vazia | Type error | Usar `Val(cell & "")` |
| Clear destroi Prestacoes | Full-row clear apaga P:Q (so no Arquivo 1) | Limpar so `A8:N(fim)` |
| Botao Anual sumindo | Insert/Delete de linhas move botao ancorado | Usar `xlFreeFloating` |
| Tabela Recorrente: 12 colunas | Prestacao e Termino existem entre Pagamento e Responsavel (so Arquivo 1) | Responsavel = col 11, Status = col 12; no LancarRecorrentes: `src.Cells(1,11)` = Responsavel, `src.Cells(1,12)` = Status |
| `Scripting.Dictionary` | So existe no Windows | Usar `Collection` + `ColIndex()` helper |
| openpyxl strips VBA | Save normal reescreve o zip | Sempre usar zip surgery para edits VBA-safe |
| LibreOffice reseta largura de colunas | Recalc padroniza tudo | Reaplicar larguras apos recalc sem novo recalc |
| Conditional formatting fora do range | Regras ficam ancoradas ao range antigo no XML | Atualizar manualmente via XML do sheet apos mover tabelas |
| VBE Import File quebrado no Mac | Bug de sandboxing | Colar codigo direto no painel de codigo da VBE (nao usar File > Import) |
| Modulos `.bas` com `Attribute VB_Name` colados na VBE | Causa erro de sintaxe ao colar direto | Remover essa linha para entregas de colagem direta; so incluir para import no Windows |
