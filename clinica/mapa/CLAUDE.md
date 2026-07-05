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

ARTEFATOS    = []                ← vazio, ou ex: [{ valor:"210x130", hora:"14h20" }]
MEDIAS_RECALC = null             ← null, ou ex: { total:"128x80", vig:"132x84", sono:"116x70" }
```

---

Gere o laudo MAPA com os dados acima.
