# sistemas

Repositório central dos meus sistemas técnicos — clínicos, financeiros e pessoais.
Fonte única de verdade. Se uma regra ou script vive aqui, esta é a versão oficial.

> **Regra de ouro:** dados de paciente NUNCA entram neste repositório.
> Laudos, exames e qualquer PII ficam fora do controle de versão (ver `.gitignore`).

## Mapa

| Pasta | O que é |
|---|---|
| `clinica/mapa/` | Geração de laudos de MAPA (Node + docx → PDF/DOCX) |
| `clinica/mrpa/` | Protocolo de processamento de tabelas de MRPA |
| `clinica/labs/` | Convenção de extração compacta de exames laboratoriais |
| `clinica/receituario/` | Ferramenta HTML de receituário + base de medicamentos |
| `clinica/farmacias/` | Prompt de comparação de preços entre farmácias de Curitiba |
| `financeiro/orcamento/` | Planilha de orçamento pessoal (.xlsm) + VBA |
| `financeiro/milhas/` | Fluxo de caixa do negócio de milhas (.xlsm) + VBA |
| `plataforma-exames/` | Plataforma web para receber exames e devolver laudos (LGPD) |
| `pessoal/eu-fui/` | Histórico de shows internacionais (DOCX + dashboard) |
| `pessoal/treinos-mario/` | App de treino e atividade física (HTML + localStorage, hospedado via GitHub Pages) |

## Como usar com o Claude Code

Abra a sessão apontando para a pasta do sistema em que vai trabalhar — não a raiz.
Exemplo: para mexer no laudo de MAPA, abra em `~/sistemas/clinica/mapa/`.
O Claude Code lê o `REGRAS.md` daquela pasta + o `CLAUDE.md` da raiz automaticamente.

## Convenções globais

Estão em `CLAUDE.md` (raiz). Valem para todos os subsistemas.
