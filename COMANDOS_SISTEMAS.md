# COMANDOS_SISTEMAS.md

## Comandos básicos

```
cd ~/sistemas
claude
/exit
```

---

**Ver o que está pendente** (não muda nada, só mostra)
```
cd ~/sistemas && git status
```

**Ver tudo que o Git guarda** (não muda nada, só lista)
```
cd ~/sistemas && git ls-files
```

---

## Plugins e ferramentas

**`claude-code-setup`** — plugin de **diagnóstico, não de execução**. Ele
escaneia seu projeto (package.json, estrutura de pastas, linguagens,
dependências) e recomenda de 1-2 automações por categoria, específicas pro
seu stack.

**Como instalar e usar:**
```
/plugin install claude-code-setup@claude-plugins-official
```
Depois é só pedir em linguagem natural: *"recomende automações pra esse
projeto"* ou *"o que devo configurar aqui"*.

**Vale a pena pro seu caso?** Pro projeto do site médico (Node/JS + PDF/
PAdES + WhatsApp Business), pode ser interessante rodar uma vez pra ver o
que ele sugere — tipo hooks de lint ou um subagent de revisão de segurança,
já que você mexe com dados de pacientes e assinatura digital. Mas não é
essencial; é mais um "achado" útil do que algo que muda o rumo do projeto.

---

## 1. Reduzir erro de execução (a mais importante)

**Plan Mode antes de codar features grandes.** Pro site (multi-subsistema,
PAdES, WhatsApp), toda feature nova complexa deveria passar por Plan Mode
primeiro — o Claude Code monta o plano, você aprova/ajusta, *depois* ele
executa. Evita o cenário de "codificou errado, agora preciso desfazer".

```
# ativar por sessão
shift+tab (alterna pra Plan Mode)
# ou deixar como padrão do projeto no settings
```

> ~~Subagents especializados (`security-reviewer`, `pdf-reviewer`)~~ —
> já registrado em `site/PROJETO.md`, seção "Forma de trabalho".

---

## 2. Gastar menos token

> ~~CLAUDE.md enxuto, não duplicado~~ — já aplicado no `CLAUDE.md` do site.

**`/clear` ou `/compact` entre tarefas não relacionadas.** Se você termina
o módulo de MAPA e vai pro módulo de WhatsApp na mesma sessão, limpar o
contexto intermediário evita carregar tokens de uma parte do projeto que
não importa mais pra tarefa atual.

**Referenciar arquivo, não colar conteúdo.** Em vez de colar trechos de
código na conversa, deixe o Claude Code ler o arquivo direto
(`@arquivo.js`) — ele só carrega o que precisa.

---

## 3. Acelerar o ciclo

**Slash commands customizados** pros fluxos que você repete. Ex:

```
/novo-tipo-exame    → cria o boilerplate padrão (endpoint, template PDF, entrada no board)
/testar-assinatura  → roda o fluxo de teste PAdES end-to-end
```
Isso evita reexplicar o mesmo processo toda vez.

> ~~Git worktrees para trabalhar em duas frentes do site em paralelo~~ —
> já registrado em `site/PROJETO.md`, seção "Forma de trabalho".
