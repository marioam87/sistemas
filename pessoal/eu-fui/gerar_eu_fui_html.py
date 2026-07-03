#!/usr/bin/env python3
"""
gerar_eu_fui_html.py
=====================
Gera o eu_fui.html a partir da fonte única de dados (eu_fui_master.json).

Por que isso existe
--------------------
Antes, cada vez que um show era adicionado, era preciso atualizar manualmente
vários arrays e números espalhados pelo HTML (SHOWS, ANOS, PAISES, CIDADES,
RANKING, COMP_GRUPOS, percentuais da aba Estilos, e os cards de estatística
no topo da Visão Geral). Qualquer um desses passos esquecido gerava
inconsistência (ex.: card "Festivais" desatualizado).

Agora só existe UMA fonte de verdade: eu_fui_master.json (o array "shows" +
um punhado de dados curados: festivais, outros eventos, mapeamento banda→
gênero musical). Este script deriva tudo o mais automaticamente:

  - ANOS, PAISES, MAP_DATA, CIDADES, PAISES_MAP   <- a partir de "shows"
  - RANKING e COMP_GRUPOS (agrupamento por nº de shows da banda, com
    normalização de sufixos romanos II/III/IV/V) <- a partir de "shows"
  - Percentual de cada gênero na aba Estilos       <- contagem de shows por
                                                       banda dividido pelo
                                                       total, usando o
                                                       mapeamento banda→gênero
                                                       curado em "estilos"
  - Todos os números dos cards no topo da Visão
    Geral (Anos/Eventos/Shows/Bandas/Países/
    Cidades/Festivais)                             <- contados diretamente

Uso
---
    python3 gerar_eu_fui_html.py [--master eu_fui_master.json]
                                  [--template eu_fui_template.html]
                                  [--out /mnt/user-data/outputs/eu_fui.html]

Como adicionar um novo show
----------------------------
1. Edite eu_fui_master.json: adicione um objeto ao array "shows" (mesmo
   formato: n, banda, pais, data, local, pri, sets). Use o próximo número
   sequencial em "n".
2. Se a banda for nova, adicione-a também à lista "bandas" do gênero
   correspondente em "estilos" (senão o script vai avisar e abortar).
3. Se o show fizer parte de um festival novo, adicione uma entrada em
   "festivais".
4. Rode este script. Ele recalcula tudo (incluindo se a banda mudou de
   grupo na Comparação/Ranking) e gera o HTML final pronto para apresentar.
"""
import argparse
import json
import re
import sys
from collections import OrderedDict, defaultdict
from datetime import date


# ═══════════════════════════════════════════════════════════════════
# Regras de formatação de nomes (com exceções curadas e explícitas)
# ═══════════════════════════════════════════════════════════════════
SMALL_WORDS = {'of', 'a', 'an', 'and', 'in', 'on', 'at', 'de', 'do', 'da'}
ACRONYMS = {'AC/DC', 'KISS', 'P.O.D.'}
DISPLAY_NAME_OVERRIDES = {
    'BRUCE DICKINSON — CONCERTO FOR GROUP AND ORCHESTRA': 'Bruce Dickinson',
    'SLASH, MYLES KENNEDY & THE CONSPIRATORS': 'Slash',
    'QUEENS OF THE STONE AGE': 'Queens of the Stone Age',
}


def base_name(banda):
    """Remove sufixo de numeral romano (II, III, IV, V) usado para shows
    repetidos da mesma banda em anos diferentes, agrupando-os como uma
    única banda nas estatísticas."""
    return re.sub(r'\s+(II|III|IV|V)$', '', banda).strip()


def title_case(raw):
    """Título legível (ex.: 'AVENGED SEVENFOLD' -> 'Avenged Sevenfold'),
    respeitando acrônimos e os overrides curados acima."""
    key = raw.upper()
    if key in DISPLAY_NAME_OVERRIDES:
        return DISPLAY_NAME_OVERRIDES[key]
    if key in ACRONYMS:
        return key
    words = raw.split(' ')
    out = []
    for i, w in enumerate(words):
        if w.upper() in ACRONYMS:
            out.append(w.upper())
            continue
        wl = w.lower()
        if i > 0 and wl in SMALL_WORDS:
            out.append(wl)
        else:
            out.append(w[:1].upper() + w[1:].lower() if w else w)
    return ' '.join(out)


def parse_cidade(local):
    """Extrai 'Cidade, UF' do campo livre 'local' de um show."""
    m = re.search(r',\s*([^,]+?)\s*[–-]\s*([A-Z]{2})\s*$', local)
    if m:
        return f"{m.group(1).strip()}, {m.group(2)}"
    m2 = re.search(r'^([^,]+?)\s*[–-]\s*([A-Z]{2})\s*$', local)
    if m2:
        return f"{m2.group(1).strip()}, {m2.group(2)}"
    return None


# ═══════════════════════════════════════════════════════════════════
# Derivação dos dados a partir de SHOWS
# ═══════════════════════════════════════════════════════════════════
def derive_all(master):
    shows = master['shows']
    total = len(shows)

    # ── ANOS ──
    anos_count = defaultdict(int)
    for s in shows:
        anos_count[s['data'].split('/')[-1]] += 1
    anos_keys = sorted(int(y) for y in anos_count)
    ANOS = OrderedDict(
        (str(y), anos_count.get(str(y), 0))
        for y in range(anos_keys[0], anos_keys[-1] + 1)
    )

    # ── PAISES / PAISES_MAP / MAP_DATA ──
    paises_count = defaultdict(int)
    paises_map = {}
    for s in shows:
        flag, _, nome = s['pais'].partition(' ')
        paises_count[nome] += 1
        paises_map[nome] = flag
    PAISES = OrderedDict(sorted(paises_count.items()))
    PAISES_MAP = OrderedDict(sorted(paises_map.items()))

    iso3 = master['paises_iso3']
    missing_iso3 = sorted(set(PAISES) - set(iso3))
    if missing_iso3:
        sys.exit(f"ERRO: país(es) sem código ISO3 em 'paises_iso3': {missing_iso3}")
    MAP_DATA = OrderedDict()
    for nome, qtd in PAISES.items():
        code = iso3[nome]
        MAP_DATA[code] = MAP_DATA.get(code, 0) + qtd

    # ── CIDADES ──
    cidades_count = defaultdict(int)
    for s in shows:
        c = parse_cidade(s['local'])
        if c is None:
            sys.exit(f"ERRO: não consegui extrair cidade do local: {s['local']!r} (show #{s['n']})")
        cidades_count[c] += 1
    CIDADES = OrderedDict(sorted(cidades_count.items()))

    # ── EVENTOS (shows no mesmo dia = 1 evento) ──
    eventos = set(s['data'] for s in shows)

    # ── RANKING + COMP_GRUPOS (agrupado por nº de aparições da banda) ──
    grupos = defaultdict(list)  # base_name -> [(ano, pais), ...]
    for s in shows:
        bn = base_name(s['banda'])
        grupos[bn].append((s['data'].split('/')[-1], s['pais']))

    RANKING = defaultdict(list)
    COMP_GRUPOS_RAW = defaultdict(list)  # count -> [banda_raw, ...] (>=2 shows)
    for bn, occ in grupos.items():
        count = len(occ)
        nome = title_case(bn)
        anos_str = ', '.join(o[0] for o in occ)
        pais = occ[0][1]
        RANKING[str(count)].append({"banda": nome, "anos": anos_str, "pais": pais})
        if count >= 2:
            COMP_GRUPOS_RAW[count].append(bn)
    for k in RANKING:
        RANKING[k].sort(key=lambda x: x['banda'].lower())
    for k in COMP_GRUPOS_RAW:
        COMP_GRUPOS_RAW[k].sort()

    GRUPO_CORES = {4: '#e87722', 3: '#d4611a', 2: '#9ca3af'}
    COMP_GRUPOS = []
    for count in sorted(COMP_GRUPOS_RAW, reverse=True):
        COMP_GRUPOS.append({
            "label": f"{count} Shows",
            "color": GRUPO_CORES.get(count, '#9ca3af'),
            "bandas": COMP_GRUPOS_RAW[count],
        })

    # ── ESTILOS (percentual calculado por nº de shows, não de bandas) ──
    banda_genero = {}
    for e in master['estilos']:
        for b in e['bandas']:
            banda_genero[b.strip()] = e['genero']

    genero_shows = defaultdict(int)
    bandas_sem_genero = []
    for s in shows:
        disp = title_case(base_name(s['banda']))
        g = banda_genero.get(disp)
        if g is None:
            bandas_sem_genero.append(disp)
        else:
            genero_shows[g] += 1
    if bandas_sem_genero:
        sys.exit(
            "ERRO: banda(s) sem gênero musical mapeado em 'estilos' do master:\n  - "
            + "\n  - ".join(sorted(set(bandas_sem_genero)))
            + "\nAdicione a banda à lista 'bandas' do gênero correto em eu_fui_master.json."
        )

    ESTILOS = []
    for e in master['estilos']:
        pct = round(100 * genero_shows[e['genero']] / total)
        ESTILOS.append({
            "genero": e['genero'],
            "pct": f"{pct}%",
            "desc": e['desc'],
            "bandas": " · ".join(e['bandas']),
        })

    # ── bandas distintas (após normalizar numerais romanos) ──
    bandas_distintas = len(grupos)

    # ── Anos decorridos desde o primeiro show (card "Anos") ──
    primeira_data = min(
        (date(int(d[2]), int(d[1]), int(d[0])) for d in (s['data'].split('/') for s in shows)),
    )
    hoje = date.today()
    anos_decorridos = hoje.year - primeira_data.year - (
        (hoje.month, hoje.day) < (primeira_data.month, primeira_data.day)
    )

    stats = {
        "anos": anos_decorridos,
        "eventos": len(eventos),
        "shows": total,
        "bandas": bandas_distintas,
        "paises": len(PAISES),
        "cidades": len(CIDADES),
        "festivais": len(master['festivais']),
    }

    return {
        "ANOS": ANOS,
        "PAISES": PAISES,
        "PAISES_MAP": PAISES_MAP,
        "MAP_DATA": MAP_DATA,
        "CIDADES": CIDADES,
        "RANKING": dict(RANKING),
        "COMP_GRUPOS": COMP_GRUPOS,
        "ESTILOS": ESTILOS,
        "stats": stats,
    }


# ═══════════════════════════════════════════════════════════════════
# Validação cruzada (autoconsistência) antes de gravar
# ═══════════════════════════════════════════════════════════════════
def validar(master, derived):
    erros = []
    shows = master['shows']

    soma_anos = sum(derived['ANOS'].values())
    if soma_anos != len(shows):
        erros.append(f"soma de ANOS ({soma_anos}) != total de shows ({len(shows)})")

    soma_paises = sum(derived['PAISES'].values())
    if soma_paises != len(shows):
        erros.append(f"soma de PAISES ({soma_paises}) != total de shows ({len(shows)})")

    soma_cidades = sum(derived['CIDADES'].values())
    if soma_cidades != len(shows):
        erros.append(f"soma de CIDADES ({soma_cidades}) != total de shows ({len(shows)})")

    soma_ranking = sum(len(v) * int(k) for k, v in derived['RANKING'].items())
    if soma_ranking != len(shows):
        erros.append(f"soma de RANKING ({soma_ranking}) != total de shows ({len(shows)})")

    soma_pct = sum(int(e['pct'].rstrip('%')) for e in derived['ESTILOS'])
    if not (98 <= soma_pct <= 102):  # tolerância de arredondamento
        erros.append(f"soma dos percentuais de ESTILOS ({soma_pct}%) fora de 98-102%")

    ns = [s['n'] for s in shows]
    if ns != list(range(1, len(shows) + 1)):
        erros.append("campo 'n' dos shows não é uma sequência 1..N contígua")

    if erros:
        sys.exit("ERRO DE VALIDAÇÃO — geração abortada:\n  - " + "\n  - ".join(erros))


# ═══════════════════════════════════════════════════════════════════
# Geração do HTML final (substituição cirúrgica dos consts + cards)
# ═══════════════════════════════════════════════════════════════════
def js_array(obj):
    return json.dumps(obj, ensure_ascii=False)


def render_html(template, master, derived):
    html = template
    s = derived['stats']

    def replace_const(name, value, is_multiline_estilos=False):
        nonlocal html
        if name == 'ESTILOS':
            lines = ',\n  '.join(js_array(e) for e in value)
            new_block = f"const ESTILOS = [\n  {lines}\n];"
        elif name == 'COMP_GRUPOS':
            lines = ',\n  '.join(js_array(g) for g in value)
            new_block = f"const COMP_GRUPOS = [\n  {lines},\n];"
        else:
            new_block = f"const {name} = {js_array(value)};"
        pattern = re.compile(rf'const {name} = (\[.*?\]|\{{.*?\}});', re.S)
        if not pattern.search(html):
            sys.exit(f"ERRO: não encontrei 'const {name} = ...' no template para substituir.")
        html = pattern.sub(lambda m: new_block.replace('\\', '\\\\'), html, count=1)

    replace_const('SHOWS', master['shows'])
    replace_const('ANOS', derived['ANOS'])
    replace_const('PAISES', derived['PAISES'])
    replace_const('PAISES_MAP', derived['PAISES_MAP'])
    replace_const('MAP_DATA', derived['MAP_DATA'])
    replace_const('CIDADES', derived['CIDADES'])
    replace_const('RANKING', derived['RANKING'])
    replace_const('FESTIVAIS', master['festivais'])
    replace_const('ESTILOS', derived['ESTILOS'])
    replace_const('OUTROS', master['outros'])
    replace_const('COMP_GRUPOS', derived['COMP_GRUPOS'])

    # ── Cards de estatística no topo da Visão Geral ──
    def sub_stat(label, value, html_in):
        pattern = re.compile(
            r'(<div class="stat-card"[^>]*>\s*<div class="num"[^>]*>)\d+(</div>\s*<div class="label">'
            + re.escape(label) + r'</div>)'
        )
        new_html, n = pattern.subn(lambda m: f"{m.group(1)}{value}{m.group(2)}", html_in)
        if n != 1:
            sys.exit(f"ERRO: não encontrei (ou encontrei mais de uma vez) o card '{label}' no template.")
        return new_html

    html = sub_stat('Anos', s['anos'], html)
    html = sub_stat('Eventos', s['eventos'], html)
    html = sub_stat('Shows', s['shows'], html)
    html = sub_stat('Bandas', s['bandas'], html)
    html = sub_stat('Países', s['paises'], html)
    html = sub_stat('Cidades', s['cidades'], html)

    # "(N festivais)" sob o card Eventos
    html = re.sub(
        r'\(\d+ festivais\)',
        f"({s['festivais']} festivais)",
        html,
    )

    return html


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--master', default='eu_fui_master.json')
    ap.add_argument('--template', default='eu_fui_template.html')
    ap.add_argument('--out', default='/mnt/user-data/outputs/eu_fui.html')
    args = ap.parse_args()

    with open(args.master, encoding='utf-8') as f:
        master = json.load(f)
    with open(args.template, encoding='utf-8') as f:
        template = f.read()

    derived = derive_all(master)
    validar(master, derived)
    html = render_html(template, master, derived)

    with open(args.out, 'w', encoding='utf-8') as f:
        f.write(html)

    s = derived['stats']
    print("✅ eu_fui.html gerado com sucesso em", args.out)
    print(f"   {s['anos']} anos · {s['eventos']} eventos · {s['shows']} shows · "
          f"{s['bandas']} bandas · {s['paises']} países · {s['cidades']} cidades · "
          f"{s['festivais']} festivais")


if __name__ == '__main__':
    main()
