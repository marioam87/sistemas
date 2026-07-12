# Instruções globais — Claude Code

Convenções que valem para **todos** os subsistemas deste repositório.
Regras específicas de cada sistema estão no `REGRAS.md` da respectiva pasta.

## Identidade / cabeçalhos

- Autor dos documentos clínicos: **Dr. Mario Augusto Mariano — CRM-PR 34.819**
- Idioma padrão de respostas e documentos: **português do Brasil**

## Geração de documentos

- Saídas oficiais em **PDF + DOCX**, convertidas via **LibreOffice** (headless).
- Fontes: Arial. Padrão de laudo → 14pt título, 12pt corpo, 10pt secundário.

## VBA (Excel no Mac)

- **100% ASCII**, sempre com `ChrW()` — nunca `Chr()` — por causa da codificação no Mac.
- Entregar como arquivos `.bas` para colar manualmente no editor de VBA.

## Segurança e privacidade

- **Nenhum dado de paciente entra no Git.** PII, exames e laudos gerados ficam fora do versionamento.
- Requisitos de LGPD são prioridade em qualquer sistema que toque dados de paciente.

## Estilo de trabalho

- Respostas escaneáveis: títulos, tabelas, negrito. Evitar paredão de texto.
- Equilibrar empatia e franqueza; sem linguagem rígida ou professoral.
- Nunca renderizar LaTeX para formatação simples ou prosa.
