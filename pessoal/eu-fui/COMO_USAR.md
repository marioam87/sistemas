# Eu Fui! — Automação e Manutenção (v2.0)

## O que mudou

Antes, cada show novo exigia editar manualmente vários pontos espalhados no
`eu_fui.html`: o array `SHOWS`, `ANOS`, `PAISES`, `CIDADES`, `RANKING`,
`COMP_GRUPOS` (e mover a banda de grupo se ela passasse de 2→3 ou 3→4
shows), os percentuais da aba Estilos, e os números dos cards no topo da
Visão Geral. Qualquer um desses passos esquecido gerava inconsistência —
foi exatamente o que quase aconteceu com o card de Festivais.

Agora existe **uma única fonte de verdade**: `eu_fui_master.json`. Tudo o
resto é **calculado automaticamente** pelo script `gerar_eu_fui_html.py`.

## Arquivos

| Arquivo                    | O que é                                                          |
|-----------------------------|-------------------------------------------------------------------|
| `eu_fui_master.json`        | Fonte de dados única: shows, festivais, outros eventos, gêneros  |
| `eu_fui_template.html`      | Esqueleto do HTML (layout, CSS, JS) — não tem dados, só estrutura |
| `gerar_eu_fui_html.py`      | Script que junta master + template → `eu_fui.html` final          |
| `validar_eu_fui.py`         | Auditoria independente de um `eu_fui.html` já pronto              |

## O que é calculado automaticamente (nunca mais editar à mão)

- `ANOS`, `PAISES`, `PAISES_MAP`, `MAP_DATA`, `CIDADES` — direto do array `shows`
- `RANKING` e `COMP_GRUPOS` — agrupamento por nº de aparições de cada banda
  (já trata sufixos romanos II/III/IV/V como a mesma banda). **Se uma banda
  passar de 2 para 3 shows, ela migra de grupo sozinha.**
- Percentual de cada gênero na aba Estilos — contagem de shows por banda em
  cada gênero, dividido pelo total
- Todos os números dos cards: Anos (decorridos desde o 1º show, recalculado
  na data em que o script roda), Eventos (shows no mesmo dia = 1), Shows,
  Bandas, Países, Cidades, e o texto "(N festivais)"

## O que continua curado manualmente (e por quê)

- `shows`: óbvio, é o dado primário
- `festivais`: qual show pertence a qual festival não dá pra inferir com
  segurança só pelo texto do campo `local`
- `outros`: eventos que não são shows (Cirque du Soleil, UFC etc.) — fora
  do array `shows`
- `estilos.bandas`: classificação musical de cada banda (gênero é uma
  decisão subjetiva, não um dado derivável)
- `paises_iso3`: código ISO3 de cada país, só usado para o mapa-múndi

## Como adicionar um show novo

1. Abra `eu_fui_master.json` e adicione um objeto ao final do array
   `"shows"`, com o próximo número sequencial em `"n"`:
   ```json
   {"n": 122, "banda": "NOME DA BANDA", "pais": "🇺🇸 EUA",
    "data": "DD/MM/AAAA", "local": "Venue, Cidade – UF",
    "pri": true, "sets": ["Música 1", "Música 2", "..."]}
   ```
2. Se a banda for nova, adicione o nome dela (em title case, ex.: `"Nome
   Da Banda"`) à lista `"bandas"` do gênero correspondente em
   `"estilos"`. Se você esquecer, o script avisa exatamente qual banda
   falta e onde adicionar — ele não deixa gerar um HTML incompleto.
3. Se for um show novo de um festival, adicione (ou confirme que já existe)
   a entrada em `"festivais"`.
4. Rode:
   ```
   python3 gerar_eu_fui_html.py
   ```
   Isso gera o `eu_fui.html` final em `/mnt/user-data/outputs/`, já com
   tudo recalculado e validado.

## Rede de segurança

`gerar_eu_fui_html.py` recusa gerar o arquivo (com mensagem de erro
explicando exatamente o que falta) se:
- alguma banda não tiver gênero mapeado em `estilos`
- algum país não tiver código ISO3 em `paises_iso3`
- algum `local` não puder ser interpretado para extrair a cidade
- a soma de qualquer estatística derivada não bater com o total de shows
  (rede de segurança extra contra bug de lógica)

Além disso, `validar_eu_fui.py` pode auditar qualquer `eu_fui.html` já
pronto (gerado pelo script ou editado à mão), de forma independente:
```
python3 validar_eu_fui.py caminho/para/eu_fui.html
```

## Sobre o DOCX (`gerar_eu_fui.js`)

O script Node não está disponível neste ambiente para integração agora,
mas o `eu_fui_master.json` foi desenhado para ser a fonte também desse
gerador no futuro — assim os dois produtos (HTML e DOCX) leem do mesmo
lugar e nunca mais ficam dessincronizados.
