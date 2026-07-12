# CLAUDE.md — Plataforma de Exames e Laudos Médicos

Plataforma web para **receber exames de pacientes** e **devolver laudos de
cardiologia** (ECG, MAPA, Holter — futuro: ECOTT, DCV), substituindo o
serviço pago atual (LaudoSyn). Desenvolvida com Claude Code no Mac mini M2.
Nome comercial e branding: **a definir**.

> Herda as convenções globais de `../CLAUDE.md`.
> Este arquivo é **índice de navegação** do projeto — detalhes técnicos
> vivem nos `CONTEXTO-*.md` de cada subpasta; aqui só aponta pra onde
> procurar e define as regras que valem pro projeto inteiro.

## Prioridade nº 1 — LGPD

Conformidade com a LGPD é requisito de projeto **desde o início**, não um
ajuste posterior. Antes de qualquer decisão de arquitetura que toque dados
de paciente, considerar:

- Minimização: coletar só o necessário.
- Base legal para tratamento de dado sensível de saúde.
- Criptografia em trânsito e em repouso.
- Controle de acesso e trilha de auditoria.
- Retenção e descarte definidos.
- Consentimento e direitos do titular (acesso, correção, exclusão).

## Segurança do repositório

- **Nenhum exame, laudo ou PII entra no Git.**
- Segredos (chaves, credenciais) fora do versionamento — usar variáveis de ambiente.
- Revisar `.gitignore` antes do primeiro commit.
- Nunca logar CPF, nome completo ou resultado de exame em texto plano.
- Qualquer código que toque dado de paciente passa por revisão de segurança
  antes de ir pra produção.

## Subsistemas

| Subsistema | Responsável | O que faz | Contexto detalhado |
|---|---|---|---|
| **Administrador** | Mario | Gestão geral, parceiros, configuração | `./administrador/CONTEXTO-administrador.md` |
| **Laudos** | Mario (ECG/MAPA) + Dra. Gislaini (Holter) | Geração, edição e assinatura de laudos | `./laudos/CONTEXTO-laudos.md` |
| **Parceiros** | 4 clínicas parceiras | Envio de exames, acompanhamento | `./parceiros/CONTEXTO-parceiros.md` |

*(ajustar os caminhos acima pra bater com a estrutura real do repo)*

## Stack / decisões arquiteturais

> Stack técnica: preencher conforme o projeto evolui.

Decisões já tomadas — não revisitar sem motivo explícito:

- **Notificações:** WhatsApp Business API
- **Assinatura digital:** PAdES / ICP-Brasil via Bird ID
- **PDF final:** label do paciente + laudo + exame bruto, concatenados; carimbo/assinatura na última página do laudo
- **Identificação:** QR code por exame
- **Hospedagem:** VPS Integrator
- **Backup:** AWS
- **Padrão de laudo:** Arial · 14pt título / 12pt corpo / 10pt secundário · azul escuro `#2C3E6B` nos headers de tabela · Dr. Mario Augusto Mariano, CRM-PR 34.819

## Diretrizes de desenvolvimento (não-negociáveis)

- **Sem assumir:** ambiguidade de arquitetura, fluxo ou regra de negócio
  (formato de PDF, timing de notificação, regra de exclusão de assinatura)
  é esclarecida com o Mario antes de implementar — nunca resolvida
  silenciosamente com suposição.
- **Simplicidade primeiro:** implementar apenas o subsistema/exame em questão.
  Não generalizar preventivamente (ex: não abstrair pra ECOTT/DCV enquanto só
  ECG/MAPA/Holter estão em desenvolvimento).
- **Mudanças cirúrgicas:** ao alterar código existente e funcional (ex:
  `gerar_laudo_v7.js`, fluxo de assinatura Bird ID), tocar só o necessário.
  Não refatorar partes adjacentes sem pedido explícito.
- **Critério de sucesso verificável:** toda tarefa tem um "concluído quando..."
  objetivo e testável (ex: "PDF valida assinatura PAdES no verificador oficial
  ICP-Brasil").

## Fluxo de trabalho recomendado

1. Para features novas ou mudanças de arquitetura → **Plan Mode primeiro**
   (aprovar o plano antes de gerar código).
2. Para mudanças pontuais em módulo existente → execução direta, mudança
   cirúrgica.
3. Ao trocar de subsistema no meio da sessão → `/clear` ou `/compact` pra não
   carregar contexto irrelevante.
4. Referenciar arquivos com `@caminho`, não colar trechos grandes na conversa.

## Roteiro do projeto

Ver `PROJETO.md` na raiz para o roteiro completo de construção do site,
tarefas e decisões em aberto.
