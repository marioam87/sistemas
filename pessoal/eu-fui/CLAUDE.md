# Eu Fui! — Regras do sistema (v2.0 — automação e manutenção)

Registro pessoal de shows internacionais de Mario Augusto Mariano (cardiologista,
Curitiba-PR, CRM-PR 34.819). O arquivo histórico oficial é `eu_fui.docx` (121
shows internacionais entre 2007 e 2026, congelado como registro original). A
dashboard HTML interativa é **gerada automaticamente** a partir de uma fonte
única de dados — não é mais editada campo a campo à mão.

## Arquivos desta pasta

- **`eu_fui_master.json`** — fonte única de verdade: array `shows` (canônico) +
  dados curados (`festivais`, `outros`, `estilos.bandas`, `paises_iso3`).
  **É este arquivo que se edita ao adicionar um show novo.**
- **`eu_fui_template.html`** — esqueleto da dashboard (layout, CSS, JS), sem
  dados embutidos. Só se edita para mudanças de design/funcionalidade.
- **`gerar_eu_fui_html.py`** — junta master + template e produz o `eu_fui.html`
  final. Deriva automaticamente: ANOS, PAISES, PAISES_MAP, MAP_DATA, CIDADES,
  RANKING, COMP_GRUPOS, percentuais de ESTILOS e todos os números dos cards.
- **`validar_eu_fui.py`** — auditoria independente de qualquer `eu_fui.html`
  (gerado ou editado à mão), reconfere consistência sem precisar do master.
- **`REGRAS.md`** — este arquivo.
- **`gerar_eu_fui.js`** ⚠️ — gerador DOCX (Node.js), ainda não integrado a esta
  automação. O `eu_fui_master.json` foi desenhado para também alimentá-lo no
  futuro, para que HTML e DOCX nunca mais fiquem dessincronizados.

---

## Como adicionar um show novo

Quando informar um show novo, reunir:
1. **Banda** (exata, com numeração se for repetição: "Metallica V" — o script
   remove o numeral automaticamente para agrupar estatísticas)
2. **Data** (DD/MM/AAAA)
3. **Local** (venue, cidade – UF)
4. **País da banda**
5. **Setlist completo** (ordem das músicas)
6. **Foi \*Pri?** (sim/não) → vira `pri: true/false` no objeto do show
7. **Se banda nova: qual gênero musical** (para classificar em `estilos.bandas`)

Depois, editar `eu_fui_master.json` (não mais o `eu_fui.html`):

1. Adicionar o show ao final do array `shows`, com o próximo `n` sequencial:
   ```json
   {"n": 122, "banda": "NOME DA BANDA", "pais": "🇺🇸 EUA",
    "data": "DD/MM/AAAA", "local": "Venue, Cidade – UF",
    "pri": true, "sets": ["Música 1", "Música 2", "..."]}
   ```
2. Se a banda for nova, adicionar o nome (em title case) à lista `bandas` do
   gênero correspondente em `estilos`. Se esquecer, o script avisa qual banda
   falta — ele não deixa gerar um HTML incompleto.
3. Se for show de festival, adicionar/confirmar a entrada em `festivais`.
4. Rodar:
   ```
   python3 gerar_eu_fui_html.py
   ```
   Gera o `eu_fui.html` final já recalculado e validado.

## O que é calculado automaticamente (nunca mais editar à mão)

- `ANOS`, `PAISES`, `PAISES_MAP`, `MAP_DATA`, `CIDADES` — direto do array `shows`
- `RANKING` e `COMP_GRUPOS` — agrupamento por nº de aparições (trata sufixos
  romanos II/III/IV/V como a mesma banda). Se uma banda passa de 2→3 shows, ela
  migra de grupo sozinha.
- Percentual de cada gênero na aba Estilos
- Todos os números dos cards: Anos, Eventos (shows no mesmo dia = 1), Shows,
  Bandas, Países, Cidades e o texto "(N festivais)"

## O que continua curado manualmente (e por quê)

- `shows`: é o dado primário
- `festivais`: qual show pertence a qual festival não dá pra inferir só pelo `local`
- `outros`: eventos que não são shows (Cirque du Soleil, UFC etc.)
- `estilos.bandas`: classificação musical de cada banda (decisão subjetiva)
- `paises_iso3`: código ISO3 de cada país, usado só no mapa-múndi

## Rede de segurança

`gerar_eu_fui_html.py` recusa gerar (com mensagem explicando o que falta) se:
alguma banda não tiver gênero mapeado, algum país não tiver ISO3, algum `local`
não puder ser interpretado, ou se alguma soma derivada não bater com o total de
shows. Além disso, `validar_eu_fui.py` audita qualquer HTML já pronto:
```
python3 validar_eu_fui.py caminho/para/eu_fui.html
```

---

## Estatísticas atuais

- **121 shows** · **86 bandas** · **14 países** · **8 cidades** · **9 festivais**
- Primeiro show: 20/01/2007 (Donavon Frankenreiter + Ben Harper, Florianópolis)
- Último registrado: 16/05/2026 (Korn, Allianz Parque, São Paulo)
- **52 shows com \*Pri**

---

## Design da Dashboard HTML (verificado)

- **Fonte:** SF Pro (`-apple-system`...) — *não* é Comic Sans MS
- **Paleta:** fundo `#f5f6fa`, navbar azul-noturno `#1A1A2E`, accent laranja `#e87722`
- **\*Pri:** laranja `#e87722` (variável CSS `--pri` / constante JS `PRI_COLOR`)
- **Arquitetura do \*Pri:** campo booleano `"pri": true/false` em cada show
- **7 abas:** Visão Geral · Setlists · Busca por Música · Comparação · Ranking ·
  Estilos (10 gêneros) · Outros Eventos
- **Ranking:** colunas fixas 45% banda / 35% anos / 20% país
- **Setlists:** número `#001–#121`, banda + bandeira + país, data e local,
  `*Pri` em laranja se `true`, setlist numerado + duração estimada (~4 min/música)

## Design do DOCX ⚠️ (não re-verificado; confirmar quando o `gerar_eu_fui.js` estiver disponível)

- **Fonte:** Comic Sans MS
- **Paleta:** Azul-noturno `#1A1A2E` · Laranja accent `#E87722` · Azul secundário
  `#0F3460` · Cinza texto `#6B7280` · Borda `#D1D5DB`
- \*Pri: negrito laranja no DOCX

---

## Estilo de resposta

- Respostas em português, organizado e direto, sem prolixidade
- Ao gerar arquivos, sempre apresentar com `present_files`
- Preferir edições cirúrgicas no script/arquivo existente em vez de reescrever tudo
- Verificar o estado real do arquivo antes de assumir o que já foi feito
