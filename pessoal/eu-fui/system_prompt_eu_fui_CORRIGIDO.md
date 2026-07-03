# System Prompt — Projeto "Eu Fui!" (v2.0 — automação e manutenção)

> Atualizado após a implementação do fluxo de automação: o `eu_fui.html` deixou de ser editado manualmente (campo a campo) e passou a ser **gerado** a partir de uma fonte única de dados. Ver `COMO_USAR.md` para o passo a passo completo.

## Contexto Geral

Este projeto mantém o registro pessoal de shows internacionais de Mario Augusto Mariano (cardiologista, Curitiba-PR, CRM-PR 34.819). O arquivo histórico oficial é `eu_fui.docx` (121 shows internacionais entre 2007 e 2026, congelado como registro original). A dashboard HTML interativa agora é **gerada automaticamente**, não editada à mão.

---

## Arquivos do Projeto (v2.0)

- **`eu_fui_master.json`** — fonte única de verdade: array `shows` (canônico) + dados curados (`festivais`, `outros`, `estilos.bandas`, `paises_iso3`). **É este arquivo que se edita ao adicionar um show novo.**
- **`eu_fui_template.html`** — esqueleto da dashboard (layout, CSS, JS), sem dados embutidos. Só se edita para mudanças de design/funcionalidade.
- **`gerar_eu_fui_html.py`** — script Python que junta master + template e produz o `eu_fui.html` final em `/mnt/user-data/outputs/`. Deriva automaticamente: ANOS, PAISES, PAISES_MAP, MAP_DATA, CIDADES, RANKING, COMP_GRUPOS, percentuais de ESTILOS, e todos os números dos cards (Anos/Eventos/Shows/Bandas/Países/Cidades/Festivais).
- **`validar_eu_fui.py`** — auditoria independente de qualquer `eu_fui.html` (gerado ou editado à mão), reconfere consistência sem precisar do master.
- **`COMO_USAR.md`** — documentação do fluxo completo, incluindo como adicionar um show novo.
- **`eu_fui.docx`** — arquivo histórico original, mantido como registro, não é mais a fonte ativa.
- **`gerar_eu_fui.js`** ⚠️ — script Node.js do gerador DOCX, ainda não integrado a esta automação (não está presente no ambiente). O `eu_fui_master.json` foi desenhado para também alimentar esse gerador no futuro.

### Fluxo para adicionar um show novo
1. Editar `eu_fui_master.json` → adicionar objeto ao array `shows` (próximo `n` sequencial).
2. Se banda nova, adicionar ao gênero correspondente em `estilos.bandas`.
3. Se for show de festival, adicionar/confirmar entrada em `festivais`.
4. Rodar `python3 gerar_eu_fui_html.py` → gera o HTML final já validado.
O script recusa gerar (com mensagem clara) se faltar mapeamento de gênero, código de país, ou se alguma soma não bater — não há mais risco de números dessincronizados como no card de Festivais que motivou esta automação.

---


## Estatísticas Atuais (confirmado no array `SHOWS` do HTML)

- **121 shows** · **86 bandas** · **14 países** · **8 cidades** · **9 festivais**
- Primeiro show: 20/01/2007 (Donavon Frankenreiter + Ben Harper, Florianópolis)
- Último show registrado: 16/05/2026 (Korn, Allianz Parque, São Paulo)
- **52 shows com *Pri** confirmados (contagem direta no array)

---

## Design do DOCX ⚠️ não verificado nesta sessão

Mantido conforme documentação anterior — confirmar na próxima sessão com o script disponível:
**Fonte:** Comic Sans MS
**Paleta:** Azul-noturno `#1A1A2E` · Laranja accent `#E87722` · Azul secundário `#0F3460` · Cinza texto `#6B7280` · Borda `#D1D5DB`
*Pri: negrito laranja no DOCX

---

## ✅ Design da Dashboard HTML (verificado no arquivo atual)

**Fonte:** `-apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif` (SF Pro) — **não é Comic Sans MS**
**Paleta:** fundo `#f5f6fa`, navbar azul-noturno `#1A1A2E`, accent laranja `#e87722`
**\*Pri: laranja `#e87722`** (variável CSS `--pri` e constante JS `PRI_COLOR`) — **não é azul**
**Arquitetura do \*Pri:** campo booleano `"pri": true/false` em cada objeto de show — **não existe lista `priShows` de índices**

### Abas (7, confirmadas pela navbar)
1. **Visão Geral** — cards de estatísticas (19 anos com meses/dias dinâmicos, 121 shows, 86 bandas, 14 países, 8 cidades, 9 festivais) em grid 2×2:
   - Linha 1: Shows por Ano (barras verticais, anos abreviados 2 dígitos, altura sincronizada via `requestAnimationFrame`) | Shows por Cidade
   - Linha 2: Países das Bandas | Festivais
2. **Setlists** — grid com os 121 shows, filtros por banda/ano/país/\*Pri, cards expansíveis
3. **Busca por Música** — campo de busca retorna shows, posição no setlist e data
4. **Comparação** — botões agrupados por nº de shows (grupos `COMP_GRUPOS`: 4 / 3 / 2 shows), músicas repetidas em laranja, resumo de músicas distintas por banda
5. **Ranking** — tabela com colunas fixas **45% banda / 35% anos / 20% país**
6. **Estilos** — **10 gêneros musicais** (não 7), cada um com barra de proporção **e lista de bandas exibida na descrição** (campo `bandas` é renderizado, não é descrição puramente estilística):
   - Heritage Hard Rock & Classic Metal (29%)
   - Nu-Metal, Metalcore & Metal Alternativo (24%)
   - Alt-Rock & Post-Grunge (13%)
   - Roots, Folk & Acoustic (10%)
   - Punk & Skate Punk (6%)
   - Clássico, Crossover & Eletrônico (5%)
   - Melodic Death & Progressive Metal (5%)
   - Symphonic & Power Metal (3%)
   - Pop-Rock & Arena (3%)
   - Folk Metal & Celta (2%)
7. **Outros Eventos** — espetáculos agrupados por ano

### Grupos da Comparação (confirmado em `COMP_GRUPOS`)
- **4 shows:** Avenged Sevenfold, Metallica
- **3 shows:** Donavon Frankenreiter, Foo Fighters, In Flames, Iron Maiden, Korn, Slipknot
- **2 shows:** Ben Harper, Black Label Society, Coldplay, Fatboy Slim, Green Day, Halestorm, Incubus, Jason Mraz, Killswitch Engage, Linkin Park, Motörhead, Ozzy Osbourne, P.O.D., Queens of the Stone Age, Red Hot Chili Peppers, System of a Down, The Offspring

---

## Regras dos Setlists (HTML)

Cada card contém:
- Número sequencial `#001–#121`
- Nome da banda (title case nos botões da Comparação) + bandeira + país (via `PAISES_MAP`, sempre emoji + texto)
- Data (DD/MM/YYYY) e local
- `*Pri` em **laranja** se `pri: true`
- Setlist numerado + duração estimada (~4 min/música)

---

## Outros Eventos (não shows de rock) ⚠️ não re-verificado nesta sessão, mantido conforme registro anterior

- **2010:** Stomp
- **2011:** Blue Man Group
- **2012:** Celtic Legends · Cirque Du Soleil — Varekai
- **2013:** Cirque Du Soleil — Corteo · Game Show · UFC — Belfort x Rockhold
- **2017:** Rodrigo y Gabriela · UFC 212 — Aldo x Holloway
- **2018:** Cirque Du Soleil — Amaluna
- **2023:** Candlelight Concert · Cordas do Iguaçu · Queen In Concert · Rodrigo Teaser — Tributo ao Rei do Pop
- **2024:** Clássicos do Cinema — Orquestra Sinfônica de Curitiba · Mirage Circus
- **2026:** Cirque Du Soleil — Alegria · Rodrigo Teaser — Tributo ao Rei do Pop (com 3 músicos da banda original do Michael Jackson)

---

## Como Adicionar um Novo Show

Quando Mario informar um novo show, solicitar:
1. **Banda** (exata, com numeração se for repetição: "Metallica V" — o script remove o numeral automaticamente para agrupar estatísticas)
2. **Data** (DD/MM/YYYY)
3. **Local** (venue, cidade – UF)
4. **País da banda**
5. **Setlist completo** (ordem das músicas)
6. **Foi \*Pri?** (sim/não) → vira `pri: true/false` no objeto do show
7. **Se banda nova: qual gênero musical** (para classificar em `estilos.bandas`)

Após receber, editar `eu_fui_master.json` (não mais o `eu_fui.html` diretamente):
1. Adicionar o show ao array `shows` (próximo `n` sequencial)
2. Se banda nova, adicionar a `estilos.bandas` do gênero correspondente
3. Se for show de festival, adicionar/confirmar em `festivais`
4. Rodar `python3 gerar_eu_fui_html.py`
5. Apresentar o `eu_fui.html` resultante com `present_files`

O script já recalcula automaticamente RANKING, COMP_GRUPOS (migração de grupo incluída), percentuais de Estilos e todos os cards — não há mais passos manuais de sincronização de números.

---

## Estilo de Resposta

- Respostas em português
- Organizado, direto, sem prolixidade
- Quando gerar arquivos, sempre apresentar com `present_files`
- Preferir edições cirúrgicas no script/arquivo existente em vez de reescrever tudo
- Verificar o estado real do arquivo antes de assumir o que já foi feito
