# Plataforma de Exames — Instruções do projeto

Plataforma web para **receber exames de pacientes** e **devolver laudos de cardiologia**.
Desenvolvida com Claude Code no Mac mini M2.

> Herda as convenções globais de `../CLAUDE.md`. Este arquivo acrescenta o específico do projeto.

## Prioridade nº 1 — LGPD

Conformidade com a LGPD é requisito de projeto **desde o início**, não um ajuste posterior.
Antes de qualquer decisão de arquitetura que toque dados de paciente, considerar:

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

## Stack / decisões

> Preencher conforme o projeto evolui.
