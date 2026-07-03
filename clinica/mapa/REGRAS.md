# MAPA — Regras do sistema

Geração de laudos de MAPA (Monitorização Ambulatorial da Pressão Arterial).
Fluxo Node.js + `docx`, com saída dupla PDF/DOCX via LibreOffice.

## Arquivos desta pasta

- `gerar_laudo_v7.js` — script template padrão (versão oficial atual)
- `dados_modelo.json` — exemplo de preenchimento dos dados do laudo
- `PROMPT_NOVO_LAUDO.md` — prompt para gerar um novo laudo com os campos a preencher
- `assets/carimbo.png` — imagem do carimbo
- `REGRAS.md` — este arquivo

## Template padrão (`gerar_laudo_v7.js`)

- Fontes **Arial**: 14pt título, 12pt corpo, 10pt secundário.
- Cabeçalho: **Dr. Mario Augusto Mariano — CRM-PR 34.819**.
- Cabeçalhos de tabela em azul-escuro **`#2C3E6B`**.
- Carimbo **centralizado** ao final do documento.

## Seção Ritmo Circadiano — quebra de página condicional

- **Sem artefatos:** a seção abre a **página 2** sem sobras, usando `pageBreakBefore`.
- **Com artefatos:** a seção segue o fluxo normal do documento (sem quebra forçada).

## Como gerar um laudo novo

1. Abrir `PROMPT_NOVO_LAUDO.md` e preencher os campos do paciente.
2. Enviar ao Claude; ele atualiza o script e gera o laudo.
3. Estrutura dos dados: ver `dados_modelo.json` como referência.

## Saída

- Gerar **PDF e DOCX** via LibreOffice (headless).

> **Privacidade:** laudos gerados contêm dados de paciente e **não** entram no Git
> (já bloqueados no `.gitignore`). Apenas o script, o modelo e o prompt são versionados.
