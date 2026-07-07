'use strict';
// ═══════════════════════════════════════════════════════════════════════════════
//  GERAR LAUDO MAPA v7 — Dr. Mario Augusto Mariano | CRM-PR 34.819
//  Compatível com: LibreOffice · Word para Windows · Word para Mac
//
//  Este script NÃO deve ser editado a cada laudo.
//  Passe o arquivo JSON do paciente como argumento:
//
//    node gerar_laudo_v7.js dados_joao.json
//
//  Saída: MAPA_[Nome].pdf  +  MAPA_[Nome].docx  em /mnt/user-data/outputs/
// ═══════════════════════════════════════════════════════════════════════════════

const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ─── Leitura do arquivo de dados ──────────────────────────────────────────────
const jsonPath = process.argv[2];
if (!jsonPath) {
  console.error("Uso: node gerar_laudo_v7.js <arquivo_dados.json>");
  process.exit(1);
}
const d = JSON.parse(fs.readFileSync(path.resolve(jsonPath), "utf8"));

// Desestrutura com os mesmos nomes usados no restante do script
const {
  NOME, SEXO, IDADE, INICIO, TERMINO, DURACAO, EMISSAO,
  N_VALIDAS, PCT_VALIDO, N_VIG, N_SONO,
  SIS_TOTAL, DIA_TOTAL, SIS_VIG, DIA_VIG, SIS_SONO, DIA_SONO,
  PICO_SIS, PICO_DIA,
  C_VIG_SIS, C_VIG_DIA, C_SONO_SIS, C_SONO_DIA,
  DESC_SIS, DESC_DIA,
  NOMENCLATURA = "vigilia_sono",
  ARTEFATOS    = [],
  MEDIAS_RECALC = null,
} = d;

// ─────────────────────────────────────────────────────────────────────────────
//  LÓGICA DE GERAÇÃO — não editar abaixo desta linha
// ─────────────────────────────────────────────────────────────────────────────

const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, PageNumber, BorderStyle, WidthType,
  ShadingType, VerticalAlign, LevelFormat, TabStopType,
  ImageRun, PageBreak,
} = require('docx');

const OUT = "/mnt/user-data/outputs";

// ─── Imagem do carimbo ────────────────────────────────────────────────────────
const CARIMBO_DATA = fs.readFileSync(path.join(__dirname, "carimbo.png"));
const CARIMBO_PX_W = 177;
const CARIMBO_PX_H =  89;

// ─── Nomenclatura dinâmica ────────────────────────────────────────────────────
const T = NOMENCLATURA === "vigilia_sono"
  ? { p1: "Vigília", p2: "Sono",    ritmo: "vigília e sono"               }
  : { p1: "Diurno",  p2: "Noturno", ritmo: "os períodos diurno e noturno" };

const LIM_P1_SIS = 135;
const LIM_P1_DIA = 85;
const LIM_P2_SIS = 120;
const LIM_P2_DIA = 70;

// ─── Nome de arquivo ──────────────────────────────────────────────────────────
function nomeArquivo(nome) {
  return nome
    .split(" ")
    .map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join("_")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Za-z_]/g, "");
}
const NOME_ARQ = nomeArquivo(NOME);

// ─── Classificações automáticas ───────────────────────────────────────────────
function classDesc(pct) {
  if (pct <= 0)               return "Ausente";
  if (pct > 0 && pct < 10)   return "Atenuado";
  if (pct >= 10 && pct <= 20) return "Presente";
  return "Acentuado";
}
function faixaDesc(pct) {
  if (pct <= 0)   return "≤0%";
  if (pct < 10)   return ">0% e <10%";
  if (pct <= 20)  return "≥10% e ≤20%";
  return ">20%";
}
function padraoSIS(pct) {
  if (pct <= 0)   return "Reverse dipper";
  if (pct < 10)   return "Non-dipper";
  if (pct <= 20)  return "Dipper";
  return "Extreme dipper";
}
const isNormalCarga = v => v <= 50;
const fmt1 = v => v.toFixed(2).replace(".", ",") + "%";

const SIS_CONC = MEDIAS_RECALC ? parseInt(MEDIAS_RECALC.total.split("x")[0]) : SIS_TOTAL;
const DIA_CONC = MEDIAS_RECALC ? parseInt(MEDIAS_RECALC.total.split("x")[1]) : DIA_TOTAL;

// ─── Cores ────────────────────────────────────────────────────────────────────
const BLUE  = "2C3E6B";
const GREEN = "1A6B3A";
const RED   = "C0392B";
const REDBG = "FDECEA";
const WHITE = "FFFFFF";
const GRAY  = "F5F5F5";

// ─── Página A4 ────────────────────────────────────────────────────────────────
const PG_W  = 11906;
const PG_H  = 16838;
const MAR   = 1134;
const MAR_B = 1440;
const CW    = PG_W - MAR * 2;

// ─── Helpers de texto ─────────────────────────────────────────────────────────
const r = (text, opts = {}) => new TextRun({
  text, font: "Arial",
  size:    opts.size   ?? 24,
  bold:    opts.bold   ?? false,
  italics: opts.italic ?? false,
  color:   opts.color  ?? "000000",
});

const blank = (sz = 24) => new Paragraph({
  children: [r("", { size: sz })],
  spacing:  { before: 0, after: 0 },
});

const secHead = txt => new Paragraph({
  children: [r(txt, { bold: true, size: 24 })],
  border:   { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 2 } },
  spacing:  { before: 180, after: 120 },
});

const sidebar = txt => new Paragraph({
  children: [r(txt, { size: 20 })],
  border:   { left: { style: BorderStyle.SINGLE, size: 8, color: BLUE, space: 8 } },
  indent:   { left: 240 },
  spacing:  { before: 100, after: 100 },
});

const bul = ch => new Paragraph({
  children: ch,
  numbering: { reference: "bul", level: 0 },
  spacing:   { before: 40, after: 40 },
});
const sub = ch => new Paragraph({
  children: ch,
  numbering: { reference: "sub", level: 0 },
  spacing:   { before: 40, after: 40 },
});
const num = (ch, keep = false) => new Paragraph({
  children:  ch,
  numbering: { reference: "num", level: 0 },
  spacing:   { before: 60, after: 60 },
  keepLines: keep,
});

const CB       = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const CBORDERS = { top: CB, bottom: CB, left: CB, right: CB };
const cellMargins = { top: 80, bottom: 80, left: 140, right: 140 };

const hCell = (txt, w) => new TableCell({
  width:         { size: w, type: WidthType.DXA },
  shading:       { fill: BLUE, type: ShadingType.CLEAR },
  borders:       CBORDERS,
  margins:       cellMargins,
  verticalAlign: VerticalAlign.CENTER,
  children:      [new Paragraph({ children: [r(txt, { bold: true, size: 22, color: WHITE })] })],
});

const dCell = (txt, w, opts = {}) => new TableCell({
  width:         { size: w, type: WidthType.DXA },
  borders:       CBORDERS,
  shading:       { fill: opts.fill ?? WHITE, type: ShadingType.CLEAR },
  margins:       cellMargins,
  verticalAlign: VerticalAlign.CENTER,
  children:      [new Paragraph({ children: [r(txt, { size: opts.size ?? 22, color: opts.color ?? "000000" })] })],
});

// ─── TABELA DE RESULTADOS ─────────────────────────────────────────────────────
const C1 = 3000, C2 = 3200, C3 = 3438;
function tabelaResultados() {
  return new Table({
    width:        { size: C1 + C2 + C3, type: WidthType.DXA },
    columnWidths: [C1, C2, C3],
    rows: [
      new TableRow({ children: [hCell("Período", C1), hCell("Resultado", C2), hCell("Valor de Referência", C3)] }),
      new TableRow({ children: [
        dCell("Média Geral",                       C1),
        dCell(`${SIS_TOTAL} x ${DIA_TOTAL} mmHg`, C2),
        dCell("< 130 x 80 mmHg",                  C3),
      ]}),
      new TableRow({ children: [
        dCell(`Período ${T.p1}`,                        C1, { fill: GRAY }),
        dCell(`${SIS_VIG} x ${DIA_VIG} mmHg`,          C2, { fill: GRAY }),
        dCell(`< ${LIM_P1_SIS} x ${LIM_P1_DIA} mmHg`, C3, { fill: GRAY }),
      ]}),
      new TableRow({ children: [
        dCell(`Período ${T.p2}`,                        C1),
        dCell(`${SIS_SONO} x ${DIA_SONO} mmHg`,        C2),
        dCell(`< ${LIM_P2_SIS} x ${LIM_P2_DIA} mmHg`, C3),
      ]}),
      new TableRow({ children: [
        dCell("Pico Sistólico",                             C1, { fill: GRAY }),
        dCell(`${PICO_SIS.valor} mmHg (${PICO_SIS.hora})`, C2, { fill: GRAY }),
        dCell("—",                                          C3, { fill: GRAY }),
      ]}),
      new TableRow({ children: [
        dCell("Pico Diastólico",                            C1),
        dCell(`${PICO_DIA.valor} mmHg (${PICO_DIA.hora})`, C2),
        dCell("—",                                          C3),
      ]}),
    ],
  });
}

// ─── TABELA DE CARGAS ─────────────────────────────────────────────────────────
const K1 = 4800, K2 = 1900, K3 = 2938;
function cargaRow(label, pct, shade) {
  const fill   = shade ? GRAY : WHITE;
  const ok     = isNormalCarga(pct);
  const label2 = ok ? "Normal" : "Anormal";
  return new TableRow({ children: [
    dCell(label,     K1, { size: 20, fill }),
    dCell(fmt1(pct), K2, { size: 22, fill }),
    dCell(label2,    K3, { size: 22, fill }),
  ]});
}
function tabelaCargas() {
  return new Table({
    width:        { size: K1 + K2 + K3, type: WidthType.DXA },
    columnWidths: [K1, K2, K3],
    rows: [
      new TableRow({ children: [hCell("Período / Componente", K1), hCell("Carga", K2), hCell("Classificação", K3)] }),
      cargaRow(`${T.p1} – Sistólica (>${LIM_P1_SIS} mmHg)`,  C_VIG_SIS,  false),
      cargaRow(`${T.p1} – Diastólica (>${LIM_P1_DIA} mmHg)`, C_VIG_DIA,  true),
      cargaRow(`${T.p2} – Sistólica (>${LIM_P2_SIS} mmHg)`,  C_SONO_SIS, false),
      cargaRow(`${T.p2} – Diastólica (>${LIM_P2_DIA} mmHg)`, C_SONO_DIA, true),
    ],
  });
}

// ─── HEADER / FOOTER ──────────────────────────────────────────────────────────
const makeHeader = () => new Header({ children: [
  new Paragraph({
    children: [r("Dr. Mario Augusto Mariano  |  CRM-PR 34.819  |  Cardiologia", { bold: true, size: 20, color: BLUE })],
    border:   { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 2 } },
    spacing:  { before: 0, after: 160 },
  }),
]});

const makeFooter = () => new Footer({ children: [
  new Paragraph({
    children: [
      r(`Emitido em: ${EMISSAO}`, { size: 18 }),
      new TextRun({ text: "\t", font: "Arial" }),
      r("Página ", { size: 18 }),
      new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 18 }),
      r(" de ", { size: 18 }),
      new TextRun({ children: [PageNumber.TOTAL_PAGES], font: "Arial", size: 18 }),
    ],
    tabStops: [{ type: TabStopType.RIGHT, position: CW }],
    border:   { top: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 2 } },
    spacing:  { before: 120, after: 0 },
  }),
]});

// ─── NUMERAÇÃO ───────────────────────────────────────────────────────────────
const NUMBERING = { config: [
  { reference: "bul", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022",
      alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] },
  { reference: "sub", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u25E6",
      alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 900, hanging: 360 } } } }] },
  { reference: "num", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.",
      alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] },
]};

const PAGE_PROPS = {
  size:   { width: PG_W, height: PG_H },
  margin: { top: MAR, right: MAR, bottom: MAR_B, left: MAR },
};

// ─── ALERTA DE QUALIDADE ──────────────────────────────────────────────────────
function alertaQualidade() {
  const blocks = [];
  if (N_VIG < 16 || N_SONO < 8) {
    blocks.push(new Paragraph({
      children: [r("⚠ ATENÇÃO: Critério de Qualidade Insuficiente", { bold: true, size: 24, color: "C0392B" })],
      spacing: { before: 0, after: 60 },
    }));
    blocks.push(new Paragraph({
      children: [r(
        `O exame não atingiu o número mínimo de aferições válidas recomendadas. ` +
        `Foram registradas apenas ${N_VIG} aferições no período ${T.p1.toLowerCase()} e ${N_SONO} no período ${T.p2.toLowerCase()}.`,
        { size: 24 }
      )],
      spacing: { before: 0, after: 120 },
    }));
  }
  return blocks;
}

// ─── ARTEFATOS ────────────────────────────────────────────────────────────────
function blocoArtefatos() {
  if (!ARTEFATOS.length) return [];
  const impacto = !!MEDIAS_RECALC;
  const blocks  = [];
  blocks.push(new Paragraph({
    children: [r("Medidas artefato identificadas:", { bold: true, size: 24 })],
    spacing: { before: 120, after: 60 },
  }));

  let texto;
  if (ARTEFATOS.length === 1) {
    const a = ARTEFATOS[0];
    texto = `Foi identificada medida possivelmente artefatual, por apresentar comportamento isolado e discrepante do restante do exame, com registro de ${a.valor} às ${a.hora}. `;
  } else {
    const lista = ARTEFATOS.map(a => `${a.valor} às ${a.hora}`).join(", ");
    texto = `Foram identificadas medidas possivelmente artefatuais, por apresentarem comportamento isolado e discrepante do restante do exame, com destaque para ${lista}. `;
  }
  texto += impacto
    ? "Tais medidas foram desconsideradas para a interpretação final."
    : `${ARTEFATOS.length === 1 ? "Tal medida não alterou" : "Tais medidas não alteraram"} a interpretação clínica final das 24 horas.`;

  blocks.push(new Paragraph({ children: [r(texto, { size: 24 })], spacing: { before: 0, after: 100 } }));
  return blocks;
}

// ─── MÉDIAS RECALCULADAS ──────────────────────────────────────────────────────
function blocoRecalc() {
  if (!MEDIAS_RECALC) return [];
  return [
    new Paragraph({ children: [r("Médias recalculadas sem artefatos:", { bold: true, size: 24 })], spacing: { before: 120, after: 60 } }),
    new Paragraph({ children: [r(`Média total recalculada: ${MEDIAS_RECALC.total} mmHg`, { size: 24 })], spacing: { before: 0, after: 40 } }),
    new Paragraph({ children: [r(`Média da ${T.p1.toLowerCase()} recalculada: ${MEDIAS_RECALC.vig} mmHg`, { size: 24 })], spacing: { before: 0, after: 40 } }),
    new Paragraph({ children: [r(`Média do ${T.p2.toLowerCase()} recalculada: ${MEDIAS_RECALC.sono} mmHg`, { size: 24 })], spacing: { before: 0, after: 100 } }),
  ];
}

// ─── RITMO CIRCADIANO ─────────────────────────────────────────────────────────
function blocoRitmo(temArtefatos) {
  const blocks = [];
  if (!temArtefatos) {
    blocks.push(new Paragraph({ children: [new PageBreak()] }));
  }
  blocks.push(
    new Paragraph({
      children: [r(`Ritmo circadiano > variação da pressão entre ${T.ritmo}`, { bold: true, size: 24 })],
      border:   { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 2 } },
      spacing:  { before: 180, after: 120 },
    }),
    bul([r("Queda noturna da pressão arterial sistólica: "),  r(fmt1(DESC_SIS), { bold: true })]),
    bul([r("Queda noturna da pressão arterial diastólica: "), r(fmt1(DESC_DIA), { bold: true })]),
    sidebar(
      "Valores inferiores a 10% - Sistólica – e 10% - Diastólica – em pacientes hipertensos, " +
      "estão relacionados a maior probabilidade de lesões em órgãos-alvo e complicações cardiovasculares."
    ),
  );
  return blocks;
}

// ─── CONCLUSÕES ───────────────────────────────────────────────────────────────
function blocoConc() {
  const sisOk = SIS_CONC < 130;
  const diaOk = DIA_CONC < 80;
  let item1;
  if (sisOk === diaOk) {
    const palavra = sisOk ? "normal" : "anormal";
    item1 = [
      r("Comportamento "), r(palavra, { bold: true }),
      r(" da média da pressão arterial sistólica ("), r(`${SIS_CONC} mmHg`, { bold: true }),
      r(") e diastólica ("), r(`${DIA_CONC} mmHg`, { bold: true }),
      r(") na monitorização realizada."),
    ];
  } else {
    item1 = [
      r("Comportamento "), r(sisOk ? "normal" : "anormal", { bold: true }),
      r(" da média da pressão arterial sistólica ("), r(`${SIS_CONC} mmHg`, { bold: true }),
      r(") e "), r(diaOk ? "normal" : "anormal", { bold: true }),
      r(" da média da pressão arterial diastólica ("), r(`${DIA_CONC} mmHg`, { bold: true }),
      r(") na monitorização realizada."),
    ];
  }

  const vigSisOk  = isNormalCarga(C_VIG_SIS);
  const sonoSisOk = isNormalCarga(C_SONO_SIS);
  let item2;
  if (vigSisOk === sonoSisOk) {
    const d = vigSisOk ? "dentro" : "fora";
    item2 = [r("Cargas pressóricas sistólicas "), r(d, { bold: true }), r(` da normalidade na ${T.p1.toLowerCase()} e no ${T.p2.toLowerCase()}.`)];
  } else {
    item2 = [
      r("Cargas pressóricas sistólicas "),
      r(vigSisOk ? "dentro" : "fora", { bold: true }),
      r(` da normalidade na ${T.p1.toLowerCase()} e `),
      r(sonoSisOk ? "dentro" : "fora", { bold: true }),
      r(` da normalidade no ${T.p2.toLowerCase()}.`),
    ];
  }

  const vigDiaOk  = isNormalCarga(C_VIG_DIA);
  const sonoDiaOk = isNormalCarga(C_SONO_DIA);
  let item3;
  if (vigDiaOk === sonoDiaOk) {
    const d = vigDiaOk ? "dentro" : "fora";
    item3 = [r("Cargas pressóricas diastólicas "), r(d, { bold: true }), r(` da normalidade na ${T.p1.toLowerCase()} e no ${T.p2.toLowerCase()}.`)];
  } else {
    item3 = [
      r("Cargas pressóricas diastólicas "),
      r(vigDiaOk ? "dentro" : "fora", { bold: true }),
      r(` da normalidade na ${T.p1.toLowerCase()} e `),
      r(sonoDiaOk ? "dentro" : "fora", { bold: true }),
      r(` da normalidade no ${T.p2.toLowerCase()}.`),
    ];
  }

  const cSIS   = classDesc(DESC_SIS);
  const cDIA   = classDesc(DESC_DIA);
  const fSIS   = faixaDesc(DESC_SIS);
  const fDIA   = faixaDesc(DESC_DIA);
  const padSIS = padraoSIS(DESC_SIS);
  const padDIA = padraoSIS(DESC_DIA);
  let padTexto;
  if (padSIS === padDIA) {
    padTexto = [r("Padrão: "), r(padSIS, { bold: true })];
  } else {
    padTexto = [
      r("Padrão "), r(padSIS, { bold: true }),
      r(" considerando a pressão sistólica e "),
      r(padDIA.toLowerCase(), { bold: true }),
      r(" considerando a pressão diastólica."),
    ];
  }

  return [
    secHead("Conclusões"),
    num(item1),
    num(item2),
    num(item3),
    num([r("Descenso Noturno:", { bold: true })]),
    sub([r("Pressão sistólica: "),  r(cSIS, { bold: true }), r(` (${fSIS})`)]),
    sub([r("Pressão diastólica: "), r(cDIA, { bold: true }), r(` (${fDIA})`)]),
    sub(padTexto),
  ];
}

// ─── BLOCO FINAL (referência + carimbo) ──────────────────────────────────────
function blocoFinal() {
  return [
    blank(),
    secHead("Referência"),
    new Paragraph({
      children: [r(
        "Diretrizes Brasileiras de Medidas da Pressão Arterial Dentro e Fora do Consultório – " +
        "2023. Arq Bras Cardiol. 2024;121(4). DOI: https://doi.org/10.36660/abc.20240113"
      )],
      spacing: { before: 60, after: 120 },
    }),
    new Paragraph({
      children: [r(
        "Nota: Os resultados deste exame devem ser correlacionados com a história clínica e o " +
        "exame físico do paciente para a tomada de decisão terapêutica.",
        { italic: true, size: 20 }
      )],
      spacing: { before: 60, after: 0 },
    }),
    blank(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [
        new ImageRun({
          data:           CARIMBO_DATA,
          type:           "png",
          transformation: { width: CARIMBO_PX_W, height: CARIMBO_PX_H },
          altText: {
            title:       "Assinatura",
            description: "Dr. Mario Augusto Mariano – CRM-PR 34.819",
            name:        "carimbo",
          },
        }),
      ],
      spacing: { before: 1200, after: 200 },
    }),
  ];
}

// ─── QUALIDADE ────────────────────────────────────────────────────────────────
// Regra (V/6ª Diretrizes MAPA-MRPA): exames com ≥20% de exclusão de medidas são
// provavelmente decorrentes de problema técnico do aparelho.
// Alguns aparelhos (ex. Contec) não discriminam quantas medidas foram excluídas,
// apenas o total de medidas válidas obtidas — nesses casos não há como calcular
// o percentual de exclusão, e o script declara essa limitação no laudo (Opção B)
// em vez de omitir o assunto ou inventar um percentual.
function parsePct(v) {
  if (v === null || v === undefined || v === "") return null;
  const n = parseFloat(String(v).replace("%", "").replace(",", "."));
  return isNaN(n) ? null : n;
}

function fraseQualidade() {
  const pctValido = parsePct(PCT_VALIDO);

  // ── Caso 1: aparelho não informa percentual de validade (ex. Contec) ──
  if (pctValido === null) {
    return [
      new Paragraph({
        children: [
          r("Procedimento realizado, tendo sido obtidas "),
          r(N_VALIDAS, { bold: true }),
          r(` medições válidas nas `),
          r(DURACAO, { bold: true }),
          r("."),
        ],
        spacing: { before: 60, after: 40 },
      }),
      new Paragraph({
        children: [r(
          "O equipamento utilizado não fornece discriminação do percentual de medidas excluídas. " +
          "A avaliação de qualidade técnica deste exame baseia-se, portanto, no número total de " +
          "medições válidas obtidas em relação ao mínimo recomendado (16 na vigília e 8 no sono).",
          { italic: true, size: 20 }
        )],
        spacing: { before: 0, after: 80 },
      }),
    ];
  }

  // ── Caso 2: aparelho informa percentual — checar exclusão ≥20% ──
  const pctExcluido = 100 - pctValido;
  const qualidadeReduzida = pctExcluido >= 20;

  const paragrafos = [
    new Paragraph({
      children: [
        r(qualidadeReduzida
          ? "Procedimento realizado, tendo sido obtidas "
          : "Procedimento realizado com boa qualidade técnica, tendo sido obtidas "),
        r(N_VALIDAS, { bold: true }),
        r(` medições válidas (${PCT_VALIDO}) nas `),
        r(DURACAO, { bold: true }),
        r("."),
      ],
      spacing: { before: 60, after: qualidadeReduzida ? 40 : 80 },
    }),
  ];

  if (qualidadeReduzida) {
    paragrafos.push(new Paragraph({
      children: [r(
        `Percentual de exclusão de medidas (${pctExcluido.toFixed(1).replace(".", ",")}%) igual ou ` +
        "superior a 20%, provavelmente decorrente de problema técnico do aparelho ou má adaptação do " +
        "paciente ao equipamento. Este achado deve ser considerado na interpretação do exame.",
        { italic: true, size: 20 }
      )],
      spacing: { before: 0, after: 80 },
    }));
  }

  return paragrafos;
}

// ─── CABEÇALHO DO PACIENTE ───────────────────────────────────────────────────
function blocoPaciente() {
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children:  [r("MONITORIZAÇÃO AMBULATORIAL DA PRESSÃO ARTERIAL", { bold: true, size: 28 })],
      spacing:   { before: 0, after: 0 },
    }),
    blank(),
    secHead("Dados do Paciente"),
    bul([r("Nome: ", { bold: true }), r(NOME)]),
    bul([r("Sexo: ", { bold: true }), r(SEXO), r("  |  "), r("Idade: ", { bold: true }), r(IDADE)]),
    bul([r("Início: ", { bold: true }), r(INICIO), r("  |  "), r("Término: ", { bold: true }), r(TERMINO)]),
    bul([r("Duração: ", { bold: true }), r(DURACAO)]),
    blank(),
    secHead("Laudo Médico"),
    blank(),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DOCUMENTO PDF (com tabelas)
// ═══════════════════════════════════════════════════════════════════════════════
function gerarDocxParaPDF() {
  const temArtefatos = ARTEFATOS.length > 0;
  const children = [
    ...alertaQualidade(),
    ...blocoPaciente(),
    secHead("Qualidade do procedimento"),
    ...fraseQualidade(),
    ...blocoArtefatos(),
    secHead("Resultados"),
    tabelaResultados(),
    blank(20),
    ...blocoRecalc(),
    secHead("Cargas pressóricas"),
    tabelaCargas(),
    sidebar("Admite-se como anormais valores superiores à 50%."),
    blank(20),
    ...blocoRitmo(temArtefatos),
    blank(),
    ...blocoConc(),
    ...blocoFinal(),
  ];
  return new Document({ numbering: NUMBERING, sections: [{
    properties: { page: PAGE_PROPS },
    headers:    { default: makeHeader() },
    footers:    { default: makeFooter() },
    children,
  }]});
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DOCUMENTO DOCX (texto descritivo, sem tabelas)
// ═══════════════════════════════════════════════════════════════════════════════
function gerarDocx() {
  const temArtefatos = ARTEFATOS.length > 0;

  const resultados = [
    secHead("Resultados"),
    bul([r("Pressão arterial média total: "), r(`${SIS_TOTAL} x ${DIA_TOTAL} mmHg`, { bold: true }), r(" (VR: 130 x 80 mmHg)")]),
    bul([r(`Pressão arterial média no período de ${T.p1.toLowerCase()}: `), r(`${SIS_VIG} x ${DIA_VIG} mmHg`, { bold: true }), r(` (VR: ${LIM_P1_SIS} x ${LIM_P1_DIA} mmHg)`)]),
    bul([r(`Pressão arterial média no período de ${T.p2.toLowerCase()}: `), r(`${SIS_SONO} x ${DIA_SONO} mmHg`, { bold: true }), r(` (VR: ${LIM_P2_SIS} x ${LIM_P2_DIA} mmHg)`)]),
    bul([r("Pico pressórico sistólico: "),  r(`${PICO_SIS.valor} mmHg`, { bold: true }), r(" às "), r(PICO_SIS.hora, { bold: true })]),
    bul([r("Pico pressórico diastólico: "), r(`${PICO_DIA.valor} mmHg`, { bold: true }), r(" às "), r(PICO_DIA.hora, { bold: true })]),
    blank(20),
  ];

  const cargas = [
    secHead("Cargas pressóricas"),
    new Paragraph({ children: [r(`Período de ${T.p1}`, { bold: true })], spacing: { before: 100, after: 60 } }),
    bul([r(`Sistólica (>${LIM_P1_SIS} mmHg): `),  r(fmt1(C_VIG_SIS),  { bold: true }), r(` — ${isNormalCarga(C_VIG_SIS)  ? "Normal" : "⚠ Anormal"}`)]),
    bul([r(`Diastólica (>${LIM_P1_DIA} mmHg): `), r(fmt1(C_VIG_DIA),  { bold: true }), r(` — ${isNormalCarga(C_VIG_DIA)  ? "Normal" : "⚠ Anormal"}`)]),
    new Paragraph({ children: [r(`Período de ${T.p2}`, { bold: true })], spacing: { before: 100, after: 60 } }),
    bul([r(`Sistólica (>${LIM_P2_SIS} mmHg): `),  r(fmt1(C_SONO_SIS), { bold: true }), r(` — ${isNormalCarga(C_SONO_SIS) ? "Normal" : "⚠ Anormal"}`)]),
    bul([r(`Diastólica (>${LIM_P2_DIA} mmHg): `), r(fmt1(C_SONO_DIA), { bold: true }), r(` — ${isNormalCarga(C_SONO_DIA) ? "Normal" : "⚠ Anormal"}`)]),
    sidebar("Admite-se como anormais valores superiores à 50%."),
    blank(20),
  ];

  const children = [
    ...alertaQualidade(),
    ...blocoPaciente(),
    secHead("Qualidade do procedimento"),
    ...fraseQualidade(),
    ...blocoArtefatos(),
    ...resultados,
    ...cargas,
    ...blocoRecalc(),
    ...blocoRitmo(temArtefatos),
    blank(),
    ...blocoConc(),
    ...blocoFinal(),
  ];

  return new Document({ numbering: NUMBERING, sections: [{
    properties: { page: PAGE_PROPS },
    headers:    { default: makeHeader() },
    footers:    { default: makeFooter() },
    children,
  }]});
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EXECUÇÃO
// ═══════════════════════════════════════════════════════════════════════════════
(async () => {
  try {
    const [buf1, buf2] = await Promise.all([
      Packer.toBuffer(gerarDocxParaPDF()),
      Packer.toBuffer(gerarDocx()),
    ]);

    const pdfDocxPath = path.join(OUT, `MAPA_${NOME_ARQ}_pdf.docx`);
    fs.writeFileSync(pdfDocxPath, buf1);
    console.log(`✓ DOCX intermediário: ${pdfDocxPath}`);

    execSync(
      `python3 /mnt/skills/public/docx/scripts/office/soffice.py --headless --convert-to pdf "${pdfDocxPath}" --outdir "${OUT}"`,
      { stdio: "inherit" }
    );
    const pdfSrc  = path.join(OUT, `MAPA_${NOME_ARQ}_pdf.pdf`);
    const pdfDest = path.join(OUT, `MAPA_${NOME_ARQ}.pdf`);
    fs.renameSync(pdfSrc, pdfDest);
    fs.unlinkSync(pdfDocxPath);
    console.log(`✓ PDF final:  ${pdfDest}`);

    const docxPath = path.join(OUT, `MAPA_${NOME_ARQ}.docx`);
    fs.writeFileSync(docxPath, buf2);
    console.log(`✓ DOCX final: ${docxPath}`);

  } catch (e) {
    console.error("ERRO:", e.message);
    process.exit(1);
  }
})();
