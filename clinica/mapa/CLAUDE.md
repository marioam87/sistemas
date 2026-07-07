# MAPA — Regras do sistema

Geração de laudos de MAPA (Monitorização Ambulatorial da Pressão Arterial).
Fluxo Node.js + `docx`, com saída dupla PDF/DOCX via LibreOffice.

## Arquivos desta pasta

- `gerar_laudo_v7.js` — script template padrão (versão oficial atual)
- `dados_modelo.json` — exemplo de preenchimento dos dados do laudo
- `assets/carimbo.png` — imagem do carimbo
- `REGRAS.md` — este arquivo (inclui o prompt de geração no final)

## Template padrão (`gerar_laudo_v7.js`)

- Fontes **Arial**: 14pt título, 12pt corpo, 10pt secundário.
- Cabeçalho: **Dr. Mario Augusto Mariano — CRM-PR 34.819**.
- Cabeçalhos de tabela em azul-escuro **`#2C3E6B`**.
- Carimbo **centralizado** ao final do documento.

## Seção Ritmo Circadiano — quebra de página condicional

- **Sem artefatos:** a seção abre a **página 2** sem sobras, inserindo um
  `Paragraph` isolado com `new PageBreak()` (não a propriedade `pageBreakBefore`).
- **Com artefatos:** a seção segue o fluxo normal do documento (sem quebra forçada).

## Saída

- Gerar **PDF e DOCX** via LibreOffice (headless).

> **Privacidade:** laudos gerados contêm dados de paciente e **não** entram no Git
> (já bloqueados no `.gitignore`). Apenas o script e o modelo são versionados.

---

# Prompt — Gerar um laudo novo

> Cole este bloco no Claude, preencha os campos e envie.
> O Claude atualiza o script e gera o PDF + DOCX automaticamente.
> A estrutura dos dados está exemplificada em `dados_modelo.json`.

## Dados do paciente

```
NOME       = ""           ← nome completo em MAIÚSCULAS
SEXO       = ""           ← "Masculino" ou "Feminino"
IDADE      = ""           ← ex: "52 anos"
INICIO     = ""           ← ex: "10/06/2025 às 08h00"
TERMINO    = ""           ← ex: "11/06/2025 às 08h15"
DURACAO    = ""           ← ex: "24h15"
EMISSAO    = ""           ← data do laudo  ex: "20/06/2025"
```

## Qualidade

```
N_VALIDAS  = ""           ← número de medições válidas  ex: "72"
PCT_VALIDO = ""           ← percentual válido           ex: "95%"
N_VIG      =              ← nº de aferições na vigília  (número inteiro)
N_SONO     =              ← nº de aferições no sono     (número inteiro)
```

## Critérios de exclusão de medidas discrepantes (aplicar automaticamente)

Ao processar a tabela de aferições individuais do exame (PDF do aparelho), identificar e
excluir automaticamente — **sem precisar perguntar ao médico** — qualquer medida que se
enquadre em:

| Critério | Condição de exclusão |
|---|---|
| PAD muito alta | PAD > 140 mmHg |
| PAD muito baixa | PAD < 40 mmHg |
| PAS muito baixa | PAS < 70 mmHg |
| PAS muito alta | PAS > 250 mmHg |
| Pressão de pulso estreita | PP < 20 mmHg (PP = PAS − PAD) |
| Pressão de pulso ampla | PP > 100 mmHg |
| Desvio da média do período | \|PAS − média do período (vigília/sono)\| > 40 mmHg, OU \|PAD − média do período\| > 40 mmHg |

> Os critérios absolutos (PAD, PAS, PP) seguem as Diretrizes Brasileiras de Medidas da PA
> Dentro e Fora do Consultório (2023) — os mesmos usados no MRPA (ver `mrpa/CLAUDE.md`).
> O critério de desvio da média do período é um refinamento clínico do Dr. Mario, para
> capturar medidas isoladas que não violam os limiares absolutos mas destoam do padrão do
> próprio exame (ex.: base 120-130x90 com medida isolada de 180x95).

Após identificar as exclusões, preencher automaticamente:
- `ARTEFATOS`: cada medida excluída, com valor e horário.
- `MEDIAS_RECALC`: médias recalculadas (total, vigília, sono) sem as medidas excluídas.

Não perguntar ao médico quais medidas excluir — aplicar os critérios diretamente. Só pedir
confirmação se houver ambiguidade na leitura do PDF (valor ilegível) ou se a exclusão mudar
significativamente a conclusão clínica do exame.

## Médias pressóricas (mmHg — apenas números inteiros)

```
SIS_TOTAL  =              ← sistólica  média geral
DIA_TOTAL  =              ← diastólica média geral
SIS_VIG    =              ← sistólica  vigília
DIA_VIG    =              ← diastólica vigília
SIS_SONO   =              ← sistólica  sono
DIA_SONO   =              ← diastólica sono
```

## Picos pressóricos

```
PICO_SIS   = { valor: "", hora: "" }   ← ex: { valor: "165", hora: "09h30" }
PICO_DIA   = { valor: "", hora: "" }
```

## Cargas pressóricas (percentual — número decimal, ex: 35.00)

```
C_VIG_SIS  =              ← carga sistólica  na vigília
C_VIG_DIA  =              ← carga diastólica na vigília
C_SONO_SIS =              ← carga sistólica  no sono
C_SONO_DIA =              ← carga diastólica no sono
```

## Descenso noturno (percentual — número decimal, ex: 10.61)

```
DESC_SIS   =              ← queda noturna sistólica
DESC_DIA   =              ← queda noturna diastólica
```

## Opções

```
NOMENCLATURA = "vigilia_sono"    ← ou "diurno_noturno"

ARTEFATOS    = []                ← preenchido automaticamente a partir dos critérios de
                                    exclusão acima, quando a tabela de aferições for fornecida
MEDIAS_RECALC = null             ← idem — calculado automaticamente junto com ARTEFATOS
```

---

Gere o laudo MAPA com os dados acima.
