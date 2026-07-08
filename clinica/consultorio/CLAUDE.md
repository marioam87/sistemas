# CLAUDE.md — Projeto CONSULTORIO.xlsm

Este arquivo dá contexto rápido sobre as macros VBA deste workbook, para quem
(humano ou Claude) for dar manutenção nelas no futuro.

## Visão geral

Workbook de gestão de um consultório médico, com (pelo menos) estas abas:

- **Plantoes** — agenda de plantões (tabela/ListObject chamada `Plantoes`)
- **Pacientes**
- **Consultas**
- **Exames**
- **Listas** (oculta — provavelmente fonte de listas de validação/dropdowns)

O projeto contém **2 módulos VBA**, cada um com um papel bem específico:

| Arquivo | Onde cola no VBE | Tipo |
|---|---|---|
| `Modulo_DuploClique_Consultorio.bas` | Objeto **EstaPasta_de_trabalho** (`ThisWorkbook`) | Evento de planilha |
| `Modulo_Principal_Consultorio.bas` | Um **Módulo** comum (Inserir > Módulo) | Sub-rotinas utilitárias |

> ⚠️ Importante: o primeiro **não pode** ser colado em um módulo comum — ele
> usa o evento `Workbook_SheetBeforeDoubleClick`, que só existe no objeto
> `ThisWorkbook`.

## Contexto histórico

Este workbook é um "spin-off" enxuto de um workbook maior de orçamento
(`orcamento_6_6.xlsm`). As macros financeiras (`GerarDashboard`,
`LancarRecorrentes`, `AtualizarImoveis`, dashboards Mensal/Anual etc.)
**ficaram no orçamento e não existem aqui** — isso é mencionado
explicitamente nos comentários do código para evitar confusão/reimportação
indevida no futuro.

## Modulo_DuploClique_Consultorio.bas

Contém `Workbook_SheetBeforeDoubleClick`, que roda **apenas** na aba
**Plantoes**, coluna **B (Data)**, fora do cabeçalho (linha > 1).

Fluxo ao dar duplo clique numa célula de Data:

1. Cancela o comportamento padrão do duplo clique (`Cancel = True`).
2. Abre um `InputBox` pedindo a data no formato `dd/mm/aaaa` (padrão: hoje).
3. Se a data for válida:
   - Grava a data na coluna **B**.
   - Grava a Competência (`yyyy-mm`) na coluna **A** (uma coluna à esquerda).
   - Calcula o Dia da Semana (sem acentos: Domingo, Segunda, Terca, Quarta,
     Quinta, Sexta, Sabado) e grava na coluna **C**.
   - Formata a linha inteira **A:E** (fundo branco, Arial 12, sem negrito,
     texto preto, centralizado, bordas finas).
   - Aplica o formato de número `[$-416]d/mmm/yy;@` na célula de Data.
4. Reativa `Application.EnableEvents` no final (usa
   `Application.EnableEvents = False/True` para não disparar o próprio
   evento recursivamente).

Layout de colunas assumido em **Plantoes**: `A=Competência, B=Data,
C=Dia da Semana, D e E = outras colunas (formatadas mas não preenchidas
por esta macro)`.

## Modulo_Principal_Consultorio.bas

Módulo comum com `Option Explicit`. Contém:

- **`LimparFiltros`** — limpa filtros e reexibe todas as linhas da aba
  ativa (funciona com `ListObject` com ou sem AutoFilter, e também remove
  `Rows.Hidden`).
- **`OrdenarDados`** — ordena a tabela da aba ativa pela coluna "Data"
  (crescente). Só funciona em abas cuja tabela tenha uma coluna chamada
  exatamente "Data" (na prática, isso é a aba Plantoes; nas outras abas o
  botão associado a esta macro simplesmente não existe).
- **`ValidarDados`** — roda apenas na aba **Plantoes**. Para cada linha
  (a partir da 2), verifica:
  - Data ausente ou inválida.
  - Competência (coluna A) bate com `yyyy-mm` da Data (coluna B).
  - Ordem cronológica das datas (comparando com a linha anterior).
  - Dia da Semana (coluna C) bate com o calculado a partir da Data.
  Reporta até 25 problemas num `MsgBox`; se não houver nenhum, mostra
  quantos plantões foram validados com sucesso.
- **`CriarBotoes`** — apaga todos os botões da aba Plantoes e recria os
  3 botões (Limpar Filtros / Ordenar Dados / Validar Dados) logo abaixo da
  tabela `Plantoes`, usando a sub auxiliar `AddBtnAt`. Deve ser rodada uma
  única vez após importar os módulos (pode rodar de novo sem problema).
- **`AddBtnAt`** (privada) — helper que cria um botão de formulário em uma
  posição específica e associa a uma macro (`OnAction`).
- **`ReativarEventos`** — utilitário de emergência: reativa
  `EnableEvents`, `ScreenUpdating` e volta o cálculo para automático, caso
  algum erro tenha deixado o Excel "travado" (ex.: duplo clique parou de
  responder porque `EnableEvents` ficou `False`).

## Convenções usadas no código

- Sempre usa o parâmetro **`Sh`** (nunca `Me`) nos eventos de planilha, o
  que permite colar o código em `ThisWorkbook` e ainda assim funcionar
  corretamente independentemente de qual aba disparou o evento.
- Strings **sem acentuação** (ex.: "Terca", "Sabado") — provavelmente para
  evitar problemas de encoding ao colar/editar o código no VBE do Mac.
- `On Error Resume Next` / `On Error GoTo 0` usados de forma pontual em
  `LimparFiltros` e `OrdenarDados` para tolerar ausência de `AutoFilter`
  ou de uma tabela na aba ativa.

## Instalação (Mac)

1. `Alt+F11` para abrir o VBE (ou Ferramentas > Macro > Editor do Visual
   Basic).
2. **Módulo de duplo clique**: no Project Explorer, dê duplo clique em
   "EstaPasta_de_trabalho" e cole `Modulo_DuploClique_Consultorio.bas`.
3. **Módulo principal**: Inserir > Módulo e cole
   `Modulo_Principal_Consultorio.bas`.
4. `Ctrl+S` para salvar (mantendo o formato `.xlsm`).
5. Rodar `CriarBotoes` uma vez para colocar os 3 botões na aba Plantoes.

## Coisas para ter em mente ao editar

- Se adicionar/remover colunas na tabela **Plantoes**, ajustar o range de
  formatação `A:E` em `Workbook_SheetBeforeDoubleClick` e a posição dos
  botões em `CriarBotoes`/`AddBtnAt`.
- `OrdenarDados` depende do nome exato da coluna **"Data"** no
  `ListObject` — renomear essa coluna quebra a ordenação.
- `ValidarDados` está fortemente acoplado ao layout `A=Competência,
  B=Data, C=Dia da Semana` — qualquer mudança de coluna nessa aba exige
  atualizar os índices `ws.Cells(i, 1/2/3)`.
- Se o duplo clique parar de responder (geralmente após um erro no meio
  do evento), rodar `ReativarEventos` antes de tentar de novo.
