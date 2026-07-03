# Prompt — Gerar Laudo MAPA

> Cole este bloco no Claude, preencha os campos e envie.
> O Claude atualiza o script e gera o PDF + DOCX automaticamente.

---

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

Gere o laudo MAPA v6 com os dados acima.
