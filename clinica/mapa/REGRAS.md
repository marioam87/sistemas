# MAPA — Regras do sistema

Geração de laudos de MAPA (Monitorização Ambulatorial da Pressão Arterial).
Fluxo Node.js + `docx`, com saída dupla PDF/DOCX via LibreOffice.

## Arquivos desta pasta

- `gerar_laudo_v5.js` — script template padrão **(colar aqui a versão oficial)**
- `assets/carimbo.png` — imagem do carimbo **(colar aqui)**
- `REGRAS.md` — este arquivo

## Template padrão (`gerar_laudo_v5.js`)

- Fontes **Arial**: 14pt título, 12pt corpo, 10pt secundário.
- Cabeçalho: **Dr. Mario Augusto Mariano — CRM-PR 34.819**.
- Cabeçalhos de tabela em azul-escuro **`#2C3E6B`**.
- Carimbo **centralizado** ao final do documento.

## Seção Ritmo Circadiano — quebra de página condicional

- **Sem artefatos:** a seção abre a **página 2** sem sobras, usando `pageBreakBefore`.
- **Com artefatos:** a seção segue o fluxo normal do documento (sem quebra forçada).

## Saída

- Gerar **PDF e DOCX** via LibreOffice (headless).
