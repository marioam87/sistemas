# Contexto: app "Atividade Física" (academia/index.html)

Documento de handoff para o Claude Code. Este arquivo é um app pessoal de treino/atividade física do Mario, feito como um único arquivo HTML autocontido (HTML+CSS+JS vanilla, sem build, sem dependências externas). Ele foi desenvolvido ao longo de uma conversa longa no Claude.ai e agora está migrando pra manutenção via Claude Code + GitHub Pages.

> Pasta renomeada de `treinos-mario/` para `academia/` em 04/07/2026 —
> puramente cosmético, sem mudança de código ou de dados. A URL do GitHub
> Pages mudou junto (ver aviso na seção "iPhone" abaixo).

> 19/07/2026 — "Musculação" passou a poder ser registrada manualmente no
> formulário do Calendário (antes só era adicionada automaticamente ao
> concluir uma sessão na aba Musculação). Mudança de uma linha: nova
> `<option value="fullbody">Musculação</option>` no `<select id="act-type">`
> dentro de `renderCalendar()`. Nenhuma outra função precisou mudar — a
> pílula, a legenda e o campo de km (que continua escondido pra esse tipo)
> já tratavam `fullbody` corretamente.

## Onde está

`~/pessoal/pessoal/academia/index.html` (nome `index.html` é importante pro GitHub Pages servir na raiz da pasta).

## Deploy (GitHub Pages)

1. Dentro do repo `~/pessoal` (nome do repositório no GitHub continua `sistemas`), a pasta é `pessoal/academia/` com o `index.html` dentro.
2. `git add pessoal/academia/index.html && git commit -m "..." && git push`
3. GitHub Pages já está configurado para servir a partir da branch `main`, raiz do repo — não precisa reconfigurar nada ao editar este app.
4. A URL gerada (`marioam87.github.io/sistemas/pessoal/academia/`) é o link fixo que o Mario abre no Safari do iPhone e adiciona à Tela de Início.

## Estrutura do app

Três abas: **Calendário**, **Musculação** (a composição corporal foi removida a pedido do usuário).

### Aba Calendário
- Resumo anual (navegável por ano, com setas ‹›): cartões de total (Musculação, Boxe, Pedaladas, Km na bike, Tabata, Esteira, Alongamento, Abdominal) — só aparecem categorias com total > 0 naquele ano.
- Resumo mensal (navegável por mês, com setas ‹›, dentro do mesmo card): mesmos cartões, filtrados pro mês.
- Calendário mensal navegável, com histórico importado (ver `SEED_ACTIVITIES`) + registros novos do usuário.
- Formulário de registro manual: data + tipo (**Musculação**/Boxe/Bike/Tabata/Esteira/Alongamento/Abdominal) + km (só bike/esteira). Musculação registrada manualmente aqui é equivalente à registrada automaticamente ao concluir uma sessão — ambas viram uma entrada `{type:'fullbody', label:'Musculação'}` em `state.activities`.

### Aba Musculação
- Trilha de 24 sessões (`SESSIONS`, gerado a partir de `WAVES`), organizadas em 3 ciclos de 4 semanas (2x/semana), full body (braço+perna no mesmo treino), sem afundo com halteres (usuário tem dor no tornozelo).
- Sessão N só desbloqueia quando a sessão N-1 é concluída (todos os exercícios marcados).
- Ao concluir uma sessão, ela também gera automaticamente uma entrada de "Musculação" no calendário do dia (ver seção Calendário acima — mesmo formato da entrada manual).
- Peso de cada exercício é editável e persiste por nome do exercício (`state.weights`), reaproveitado em todas as ocorrências futuras daquele exercício.
- Barra de progresso + "trilha" visual de bolinhas (uma por sessão, agrupadas por ciclo).

## Modelo de dados (localStorage)

Chave: `mfit-trilha-progresso` (constante `STORAGE_KEY`). Um único JSON:

```js
{
  completed: [bool, ...],       // uma entrada por sessão de treino (length = TOTAL)
  checks: [[bool x7], ...],     // checkboxes de exercícios por sessão (length = TOTAL)
  selected: number,             // índice da sessão selecionada na aba Musculação
  weights: { "Nome do Exercício": "12kg", ... },
  activities: {                 // calendário
    "YYYY-MM-DD": [{type: 'fullbody'|'boxe'|'bike'|'tabata'|'esteira'|'alongamento'|'abdominal', label?, km?}, ...]
  },
  seededVersion: number,        // controla histórico importado (SEED_ACTIVITIES)
}
```

`TOTAL = SESSIONS.length` (hoje 24, calculado a partir de `WAVES`).

## ⚠️ REGRA CRÍTICA — não perder progresso do usuário

**Nunca** exigir que `completed.length === TOTAL` para aceitar o estado salvo. Se um dia `TOTAL` mudar (ex: adicionar um 4º ciclo, 24→48 sessões), o código **precisa estender os arrays**, nunca recriar o estado do zero. Isso já está implementado em `loadState()` e em `handleRestoreFile()`:

```js
if(parsed.completed.length < TOTAL){
  const missing = TOTAL - parsed.completed.length;
  parsed.completed = parsed.completed.concat(Array(missing).fill(false));
  parsed.checks = (parsed.checks || []).concat(Array(missing).fill(null).map(() => Array(7).fill(false)));
}
```

Isso preserva: sessões já concluídas, cargas editadas (`weights`), e o calendário inteiro (`activities`), que não tem nenhuma relação com o número de sessões e nunca deveria ser afetado por essa mudança.

**Ao adicionar uma nova rodada de treinos:** só adicionar um novo objeto em `WAVES` (seguindo o padrão dos 3 existentes — mesmos padrões de movimento: agachamento, supino, terra, puxada; variar exercícios; sem afundo com halteres). Não tocar em `SEED_ACTIVITIES`, `state.activities`, nem nas funções de calendário.

## Persistência

- Usa `localStorage` do navegador (não `window.storage` — essa era a versão anterior, ligada ao Claude.ai, que tinha bugs no app mobile e não funcionava fora do ambiente Claude. Foi trocada propositalmente).
- Funciona offline, por navegador/dispositivo. Não sincroniza entre aparelhos.
- Botões de **Baixar backup** (exporta `state` como `.json`) e **Restaurar backup** (importa) já implementados no topo da página — é a rede de segurança do usuário contra perda de dados, ele foi orientado a usar antes de qualquer atualização.

## iPhone — como o usuário usa isso no dia a dia

Abre a URL do GitHub Pages no Safari → "Adicionar à Tela de Início" → abre em tela cheia como um app. Continua funcionando assim mesmo depois de atualizações no código (o localStorage sobrevive a atualizações de conteúdo da mesma origem/URL — a origem `marioam87.github.io` não muda).

**Atenção:** o *caminho* da URL mudou de `.../treinos-mario/` para
`.../academia/` quando a pasta foi renomeada (04/07/2026). O atalho antigo na
Tela de Início do iPhone aponta pra URL antiga (que agora dá 404) — o Mario
precisa remover o atalho velho e adicionar um novo a partir da URL nova. O
localStorage em si não é afetado (mesma origem), só o atalho salvo aponta
pro lugar errado.

## Preferências de estilo do usuário (Mario)

- Fundo branco, tema claro (já implementado).
- Fontes: Space Grotesk (títulos), Inter (corpo), JetBrains Mono (números/dados).
- Cor de destaque: âmbar (`#c17d2e`). Verde para "concluído"/positivo, laranja-avermelhado para "negativo".
- Prefere respostas/interfaces compactas, escaneáveis, sem excesso de texto.
