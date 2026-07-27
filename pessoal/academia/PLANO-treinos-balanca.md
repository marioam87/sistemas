# Projeto Academia — Plano de Implementação

**Documento gerado em:** 24/07/2026
**App:** `treinos_mario.html` — `marioam87.github.io/sistemas/pessoal/treinos-mario/`
**Objetivo desta rodada:** integrar a balança Omron ao app, proteger os dados existentes e preparar a estrutura para o ciclo 2 de treinos.

---

## Sumário

1. [Onde o projeto está hoje](#1-onde-o-projeto-está-hoje)
2. [Decisões tomadas](#2-decisões-tomadas)
3. [FASE 0 — Proteger o que já existe](#fase-0--proteger-o-que-já-existe)
4. [FASE 1 — Melhorias rápidas no app](#fase-1--melhorias-rápidas-no-app)
5. [FASE 2 — Catálogo de exercícios](#fase-2--catálogo-de-exercícios)
6. [FASE 3 — Backend](#fase-3--backend)
7. [FASE 4 — Balança Omron → app](#fase-4--balança-omron--app)
8. [FASE 5 — Offline e visão integrada](#fase-5--offline-e-visão-integrada)
9. [Checklist geral](#checklist-geral)
10. [Perguntas em aberto](#perguntas-em-aberto)

---

## 1. Onde o projeto está hoje

### O que funciona

- App HTML estático no GitHub Pages, instalado na Tela de Início do iPhone
- Calendário mensal com atividades coloridas + painel de estatísticas
- Programa de 24 sessões (Treino A / Treino B), full body
- Por exercício: checkbox, grupo muscular, séries×reps fixas, campo de carga em kg, link para vídeo no YouTube
- **A carga é registrada por sessão** — a progressão histórica já está preservada (sessão 1 com 12 kg, sessão 3 com 14 kg, etc.)
- Armazenamento em `localStorage`

### As lacunas identificadas

| Lacuna | Consequência |
|---|---|
| Dados só no `localStorage` | Perda total se limpar o Safari ou trocar de iPhone sem restaurar bem |
| Sem visualização da progressão | O histórico existe mas você não consegue vê-lo |
| Sem "última carga" na tela | Precisa lembrar de cabeça o que fez na sessão anterior |
| Estrutura fixa em 24 sessões | O app trava quando o ciclo 1 acabar |
| Exercício identificado por nome | Progressão quebra quando o pacote muda a cada 8 sessões |
| Sem cache-busting | Depois do `git push`, o Safari pode continuar servindo a versão antiga |
| Sem funcionamento offline | Academia com sinal ruim = app não abre |
| Sem dados da balança | Falta o lado da composição corporal |

### Semântica importante da carga

O valor registrado é a **carga por lado**, não o total:

| Tipo | Registrado | Carga real |
|---|---|---|
| Halteres | 12 kg | 24 kg (um em cada braço) |
| Anilhas | 20 kg | 40 kg + peso do equipamento |
| Máquina | 9 kg | 9 kg |
| Peso corporal | 0 kg | peso corporal |

> Qualquer cálculo futuro de volume ou tonelagem precisa saber o tipo de carga de cada exercício. Por isso o catálogo (Fase 2).

---

## 2. Decisões tomadas

| Decisão | Escolha | Motivo |
|---|---|---|
| Onde guardar dados da balança | **Fora do repositório do app** | `git push` de código nunca pode encostar em dados |
| `localStorage` continua? | **Sim, como cache** | Fonte de verdade passa a ser o backend |
| Backend | **Supabase** (preferência) | Traz autenticação pronta; sem ela sobraria senha fixa em repo público |
| Como puxar dados da balança | **Omron Connect → Apple Health → Atalhos → backend** | Não exige engenharia reversa do Bluetooth |
| Identidade dos exercícios | **ID estável em catálogo**, não o nome escrito | Progressão precisa atravessar blocos |
| Numeração de sessões | **Aberta** (25, 26, 27...) | Ciclo 2 continua a sequência sem apagar histórico |

### O que foi descartado

- **Engenharia reversa do Bluetooth da balança** — a Omron usa perfil GATT proprietário, sem API pública. Muito trabalho para pouco ganho, já que o Apple Health resolve.
- **Gist do GitHub como backend** — exigiria token no JavaScript de um repositório público.
- **Parser de texto livre da carga** — desnecessário: os valores já são limpos e numéricos.

---

## FASE 0 — Proteger o que já existe

> **Faça isto primeiro, antes de qualquer código.** São 20 minutos e eliminam o risco de perder tudo.

### 0.1 — Ligar a criptografia do backup do iPhone ⚠️ CRÍTICO

Sem isso, **os dados do app Saúde não estão sendo salvos** nos seus backups no Mac. A Apple só inclui dados de Saúde em backups locais criptografados.

1. Conecte o iPhone ao Mac pelo cabo
2. Abra o **Finder** → seu iPhone na barra lateral → aba **Geral**
3. Marque **"Criptografar backup local"**
4. Crie uma senha e **guarde no gerenciador de senhas** — a Apple não recupera; sem ela o backup fica inutilizável
5. Clique em **"Fazer Backup Agora"**
6. Confirme: em **Gerenciar Backups**, deve aparecer um cadeado ao lado da data

### 0.2 — Instalar o backup JSON no app

Arquivo pronto: `backup-treinos.js`

1. Copie o arquivo para a pasta do app no repositório
2. Antes de `</body>`, adicione:

```html
<script src="backup-treinos.js"></script>
```

3. Adicione dois botões numa aba de configurações (ou no rodapé):

```html
<button onclick="Backup.exportar()">Exportar backup</button>
<button onclick="Backup.importar()">Restaurar backup</button>
```

4. Faça o `git push`
5. **Teste no iPhone:** abra o app, toque em Exportar. Deve abrir a folha de compartilhamento do iOS → salve em Arquivos ou iCloud Drive
6. Abra o arquivo salvo e confira se os dados dos treinos estão lá dentro

> **Se as suas chaves do `localStorage` têm prefixo** (ex.: `treinos_`), preencha a constante `PREFIXOS` no topo do arquivo para não exportar lixo de outros sites. Rode `Backup.inspecionar()` no console para conferir o que sairia.

**Rotina sugerida:** exportar uma vez por mês, e sempre antes de uma atualização grande do app.

### 0.3 — Configurar o iCloud

Você usa backup local no Mac, que é uma escolha boa — mas ele só roda quando você conecta o cabo. O iCloud entra como rede de segurança contínua para o que é pequeno e insubstituível.

**Ver o que já está lá:**

1. **Ajustes** → seu nome no topo → **iCloud**
2. Toque em **"Ver Tudo"** / "Apps que Usam o iCloud" — lista quem sincroniza
3. Toque em **"Gerenciar Armazenamento da Conta"** — mostra quanto cada coisa ocupa

**Configuração recomendada para os 5 GB gratuitos:**

| Ligar | Motivo |
|---|---|
| ✅ **Saúde** | Poucos MB, criptografia ponta a ponta. Protege o histórico da balança todo dia, sem cabo |
| ✅ **Chaveiro / Senhas** | Pesa quase nada, evita dor de cabeça na troca de aparelho |
| ✅ Contatos, Calendários, Notas | Leves |

| Desligar | Motivo |
|---|---|
| ❌ **Fotos do iCloud** | É o que consome os 5 GB. Suas fotos já estão no Mac |
| ❌ **Backup do iCloud** | Redundante com o backup local — e ligá-lo faz o Finder parar de fazer o backup local automático |

> **Ponto importante:** a *sincronização* da Saúde é independente do *Backup* do iCloud. Você pode ligar a Saúde e manter o backup local no Mac sem conflito.

---

## FASE 1 — Melhorias rápidas no app

> Uma sessão de Claude Code. Barato e com impacto imediato no uso diário.

### 1.1 — Mostrar a última carga

**O quê:** ao lado do campo de carga, exibir o valor registrado na última vez que aquele exercício apareceu.

```
Agachamento Livre com Halteres        3x12
Quadríceps                           [ 12kg ]
                                     última vez: 12kg (sessão 1)
```

**Por quê:** é a informação que você precisa exatamente no momento da decisão de aumentar a carga. O dado já está no `localStorage` — é só buscar e exibir.

**Regra:** procurar para trás, a partir da sessão atual, a ocorrência mais recente do mesmo exercício. Se não houver, não mostrar nada (não mostrar "0kg" nem "—").

### 1.2 — Versão visível + cache-busting

**Problema:** você faz `git push`, abre o app e continua vendo a versão antiga. O Safari serve do cache sem avisar.

**Solução:**

1. Adicione um parâmetro de versão nos arquivos referenciados:

```html
<link rel="stylesheet" href="estilo.css?v=20260724">
<script src="app.js?v=20260724"></script>
```

2. Mostre a versão em algum canto discreto da tela (rodapé da aba de configurações)
3. A cada deploy, atualize a data em ambos os lugares

**Por quê:** sem isso você vai perder tempo debugando bugs que já corrigiu.

### 1.3 — Ajustes de interface

- **Campo de carga em exercícios de peso corporal:** o `0kg` do Abdominal Supra Solo não informa nada. Ocultar o campo, ou trocar por "repetições executadas"
- **Ícone do vídeo:** o ▶ azul é o único elemento com cara de padrão de sistema numa interface bem resolvida. Um ícone simples na paleta terrosa do app alinharia o conjunto

---

## FASE 2 — Catálogo de exercícios

> **A decisão estrutural do projeto.** Precisa estar pronta antes de você montar o ciclo 2.

### O problema que resolve

A cada 8 sessões o pacote de exercícios muda. Se o exercício é identificado pelo nome escrito na lista, dois problemas aparecem:

- Uma variação na escrita ("Supino Reto com Halteres" vs "Supino Reto (Halteres)") cria dois exercícios diferentes para o app
- A progressão reseta a cada bloco, em vez de atravessá-los

Você quer o contrário: voltar ao supino no bloco 4 e o app te dizer *"você parou em 16 kg no bloco 2"*.

### O modelo

**Catálogo** — definido uma vez, reaproveitado sempre:

```json
{
  "id": "supino_reto_halteres",
  "nome": "Supino Reto com Halteres",
  "grupo": "Peito",
  "tipoCarga": "halteres",
  "video": "https://youtu.be/..."
}
```

`tipoCarga`: `halteres` | `anilhas` | `maquina` | `corporal` — define como calcular a carga total.

**Sessões** — lista aberta, sem teto:

```json
{
  "sessao": 3,
  "treino": "A",
  "bloco": 1,
  "data": "2026-07-24",
  "concluida": true,
  "exercicios": [
    { "id": "supino_reto_halteres", "series": 3, "reps": 10, "carga": 12, "feito": true }
  ]
}
```

### O que isso destrava

- **Sessão 25 é só mais um item na lista** — nada de "24" fixo no código
- Montar o ciclo 2 = criar sessões novas referenciando IDs do catálogo
- Trocar um link de vídeo muda em todas as sessões de uma vez
- Progressão por exercício atravessa blocos, com lacunas visíveis onde ele saiu do programa (isso é informação útil, não defeito)

### Passo a passo da migração

1. **Exporte um backup JSON antes de começar** (Fase 0.2) — rede de segurança
2. Liste os exercícios distintos das 24 sessões atuais
3. Crie o catálogo, atribuindo `id`, `tipoCarga` e `video` a cada um
4. Converta as 24 sessões para o novo formato, substituindo nomes por IDs
5. Escreva a função de migração que roda uma vez no `localStorage` do usuário e converte os dados existentes
6. Teste com o backup restaurado antes de publicar

> Você está na sessão 3, com ~21 sessões pela frente (~10 semanas). Faça a refatoração **antes** de montar o ciclo 2, não junto — senão migra o dobro de dados.

### 2.1 — Gráfico de progressão por exercício

Com o catálogo pronto, isso deixa de ser trabalho: é só plotar.

- Uma linha por exercício, ao longo das sessões em que ele aparece
- Eixo X: número da sessão (ou data). Eixo Y: carga
- Lacunas onde o exercício saiu do programa

---

## FASE 3 — Backend

> Só faz sentido depois da Fase 2. Antes disso você migraria uma estrutura que ainda vai mudar.

### Por que sair do `localStorage`

| Camada | Hoje | Depois |
|---|---|---|
| Código | GitHub Pages ✅ | GitHub Pages ✅ |
| Dados | `localStorage` ⚠️ | Supabase ✅ |
| Cache offline | — | `localStorage` |

Troca de iPhone deixa de ser evento: abre a URL, faz login, o histórico inteiro volta.

### Por que Supabase

O ponto que decide não é armazenamento — é **autenticação**. Seu site é público; qualquer endpoint precisa saber que é você escrevendo. Sem auth pronta, você acaba com uma senha fixa no JavaScript de um repositório público.

- Login por link no e-mail, uma vez por dispositivo
- Regras de acesso (RLS) garantem que só você lê e escreve
- API REST automática — os Atalhos escrevem direto, sem servidor intermediário
- Painel para inspecionar os dados e consultas SQL depois

**Ressalva:** o plano gratuito pausa projetos inativos por ~1 semana. Uso diário não é afetado, mas depois de férias longas o primeiro acesso demora a responder.

### Passos

1. Criar conta e projeto no Supabase
2. Criar as tabelas: `exercicios` (catálogo), `sessoes`, `sessao_exercicios`, `medidas_corporais`
3. Ativar Auth por e-mail e criar seu usuário
4. Configurar RLS: cada linha pertence ao seu `user_id`
5. No app: login, buscar dados na abertura, gravar alterações
6. `localStorage` vira cache — com fila de sincronização para quando estiver offline

---

## FASE 4 — Balança Omron → app

### 4.1 — Omron Connect → Apple Health

Esta parte é 100% oficial e suportada.

1. Abra o **Omron Connect** no iPhone
2. Vá em **Configurações** → **"Compartilhar dados com outros apps"** (ou "Share data with other apps")
3. Toque em **Apple Health** → **"Vincular" / "Link"**
4. Ative as categorias que você quer compartilhar: **Peso, Percentual de Gordura Corporal, IMC, Massa Muscular**
5. Toque em **Permitir** nas telas de permissão do iOS
6. Volte ao painel do Omron Connect — ele começa a sincronizar o histórico

**Verificação:** abra o app **Saúde** → **Explorar** → **Medidas Corporais** → **Peso**. Suas medições devem aparecer ali.

> **Problema comum:** se o Omron Connect aparecer como "inativo" no Apple Health, desvincule e vincule de novo, e confirme as permissões em **Ajustes → Saúde → Acesso a Dados e Dispositivos → Omron Connect**.

### 4.2 — Apple Health → backend, via Atalhos

O Safari/PWA **não tem acesso ao HealthKit** — apenas apps nativos têm. O app Atalhos faz a ponte.

1. Abra o app **Atalhos** → aba **Automação** → **+**
2. Escolha **Automação Pessoal** → **Hora do Dia** → ex.: todo dia às 09:00
3. Adicione a ação **"Encontrar Dados de Saúde"** (Find Health Samples)
   - Tipo: **Peso**
   - Ordenar por: **Data de Início**, decrescente
   - Limite: **1**
4. Repita para **Percentual de Gordura Corporal** e demais medidas
5. Adicione **"Obter Conteúdo de URL"** (Get Contents of URL)
   - URL: seu endpoint do Supabase (`https://xxxx.supabase.co/rest/v1/medidas_corporais`)
   - Método: **POST**
   - Cabeçalhos: `apikey` e `Authorization` com a chave do Supabase
   - Corpo: JSON com data, peso e demais medidas
6. Desligue **"Perguntar Antes de Executar"** para rodar sozinha

### 4.3 — Aba Balança no app

- Buscar as medidas do backend na abertura
- Gráfico de peso e composição corporal ao longo do tempo
- **Não construir como gráfico isolado** — ver Fase 5

---

## FASE 5 — Offline e visão integrada

### 5.1 — Funcionar sem sinal

Academia com sinal ruim é regra. Hoje, se o GitHub Pages não carregar, o app não abre.

- `manifest.json` + service worker simples que cacheia a aplicação
- Fila local de sincronização: registra a série no subsolo, sincroniza quando voltar a ter rede
- **Ressalva:** o vídeo do YouTube não pode ser cacheado — é o item que quebra primeiro sem sinal

### 5.2 — A visão que junta tudo

O risco da aba balança é virar uma ilha: um gráfico de peso que você olha e fecha.

O valor está no cruzamento:

- Carga total ao longo dos meses **sobreposta** à massa magra
- Frequência de treino no mês **contra** a variação de composição corporal
- Responder de verdade: *"as três semanas em que treinei 4x fizeram diferença?"*

**Projete a aba balança já pensando nisso**, não como gráfico separado.

---

## Checklist geral

### Fase 0 — Proteger (fazer primeiro, ~20 min)
- [ ] Ligar "Criptografar backup local" no Finder e salvar a senha
- [ ] Rodar um backup completo do iPhone
- [ ] Instalar `backup-treinos.js` no app e publicar
- [ ] Testar exportar/importar no iPhone
- [ ] Conferir o consumo dos 5 GB do iCloud
- [ ] Ligar sincronização de Saúde e Chaveiro no iCloud
- [ ] Desligar Fotos do iCloud e Backup do iCloud

### Fase 1 — Melhorias rápidas (1 sessão de Claude Code)
- [ ] "Última vez: X kg" ao lado do campo de carga
- [ ] Cache-busting (`?v=data`) + versão visível na tela
- [ ] Ocultar campo de carga em exercícios de peso corporal
- [ ] Trocar o ícone do vídeo

### Fase 2 — Catálogo (antes da sessão 24)
- [ ] Exportar backup JSON antes de começar
- [ ] Listar exercícios distintos e montar o catálogo com IDs
- [ ] Converter as 24 sessões para o novo formato
- [ ] Escrever a função de migração do `localStorage`
- [ ] Testar restaurando o backup
- [ ] Gráfico de progressão por exercício

### Fase 3 — Backend
- [ ] Criar projeto no Supabase
- [ ] Modelar tabelas e ativar RLS
- [ ] Configurar Auth por e-mail
- [ ] Migrar os dados do `localStorage`
- [ ] `localStorage` vira cache

### Fase 4 — Balança
- [ ] Vincular Omron Connect ao Apple Health
- [ ] Confirmar as medições no app Saúde
- [ ] Montar a automação no Atalhos
- [ ] Criar a aba Balança no app

### Fase 5 — Refinamento
- [ ] `manifest.json` + service worker
- [ ] Fila de sincronização offline
- [ ] Visão integrada carga × composição corporal

---

## Perguntas em aberto

1. **Ciclo 2** — os exercícios do próximo ciclo já estão definidos, ou serão montados quando o ciclo 1 acabar? Isso muda quando a Fase 2 precisa estar pronta.
2. **Blocos** — dentro das 24 sessões atuais, os exercícios repetem entre os três blocos ou cada bloco é totalmente novo? Define quanto da progressão atravessa os blocos.
3. **Aeróbico e alongamento** — entram no mesmo modelo de sessões ou ficam só no calendário?
4. **Medidas da balança** — além de peso e gordura, quais quer acompanhar? (gordura visceral, músculo esquelético, metabolismo basal, idade corporal)

---

## Arquivos deste projeto

| Arquivo | O que é |
|---|---|
| `treinos_mario.html` | O app |
| `CONTEXTO-treinos-mario.md` | Contexto para o Claude Code |
| `backup-treinos.js` | Módulo de exportar/importar (pronto, a instalar) |
| `PLANO-treinos-balanca.md` | Este documento |
