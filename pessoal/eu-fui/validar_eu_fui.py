#!/usr/bin/env python3
"""
validar_eu_fui.py
==================
Confere a autoconsistência de um eu_fui.html já existente: recalcula tudo a
partir do próprio array SHOWS embutido no arquivo e compara com os números
exibidos nos cards e com os demais consts (ANOS, PAISES, CIDADES, RANKING,
ESTILOS). Não precisa do master JSON — serve para auditar qualquer HTML,
inclusive um editado manualmente fora do fluxo do gerador.

Uso:
    python3 validar_eu_fui.py caminho/para/eu_fui.html
"""
import json
import re
import sys
from collections import defaultdict


def extract_const(content, name):
    m = re.search(rf'const {name} = (\[.*?\]|\{{.*?\}});', content, re.S)
    if not m:
        return None
    raw = m.group(1)
    # COMP_GRUPOS é gerado com vírgula pendente antes do fechamento (ver
    # gerar_eu_fui_html.py) — JS aceita, JSON não. Remover antes de parsear.
    raw = re.sub(r',\s*([\]}])', r'\1', raw)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


_ROMAN_SUFFIX_RE = re.compile(r'^M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$')


def base_name(banda):
    """Mesma regra de gerar_eu_fui_html.py: remove sufixo de numeral romano
    (II, III, IV, V, VI, ...) para agrupar shows repetidos da mesma banda."""
    partes = banda.rsplit(' ', 1)
    if len(partes) == 2 and partes[1] != 'I' and _ROMAN_SUFFIX_RE.fullmatch(partes[1]):
        return partes[0].strip()
    return banda.strip()


def main():
    if len(sys.argv) != 2:
        sys.exit("uso: python3 validar_eu_fui.py caminho/para/eu_fui.html")
    path = sys.argv[1]
    html = open(path, encoding='utf-8').read()

    shows = extract_const(html, 'SHOWS')
    if shows is None:
        sys.exit("ERRO: não encontrei o array SHOWS no arquivo.")

    problemas = []
    avisos = []

    # ── cards do topo ──
    def card_num(label):
        m = re.search(
            r'<div class="stat-card"[^>]*>\s*<div class="num"[^>]*>(\d+)</div>\s*<div class="label">'
            + re.escape(label) + r'</div>', html)
        return int(m.group(1)) if m else None

    total_shows = len(shows)
    bandas = set(base_name(s['banda']) for s in shows)
    paises = set(s['pais'].partition(' ')[2] for s in shows)
    eventos = set(s['data'] for s in shows)

    checks = [
        ('Shows', card_num('Shows'), total_shows),
        ('Bandas', card_num('Bandas'), len(bandas)),
        ('Países', card_num('Países'), len(paises)),
        ('Eventos', card_num('Eventos'), len(eventos)),
    ]
    for label, exibido, real in checks:
        if exibido is None:
            avisos.append(f"card '{label}' não encontrado no HTML (layout pode ter mudado).")
        elif exibido != real:
            problemas.append(f"card '{label}' mostra {exibido}, mas o array SHOWS indica {real}.")

    festivais = extract_const(html, 'FESTIVAIS')
    festivais_label = re.search(r'\((\d+) festivais\)', html)
    if festivais is not None and festivais_label:
        n_label = int(festivais_label.group(1))
        if n_label != len(festivais):
            problemas.append(f"texto '({n_label} festivais)' não bate com FESTIVAIS ({len(festivais)} itens).")

    # ── ANOS ──
    anos_const = extract_const(html, 'ANOS')
    if anos_const is not None:
        anos_real = defaultdict(int)
        for s in shows:
            anos_real[s['data'].split('/')[-1]] += 1
        for ano, qtd in anos_const.items():
            if anos_real.get(ano, 0) != qtd:
                problemas.append(f"ANOS['{ano}'] = {qtd} no HTML, mas SHOWS indica {anos_real.get(ano, 0)}.")

    # ── CIDADES ──
    cidades_const = extract_const(html, 'CIDADES')
    if cidades_const is not None:
        soma = sum(cidades_const.values())
        if soma != total_shows:
            problemas.append(f"soma de CIDADES ({soma}) != total de shows ({total_shows}).")

    # ── RANKING (soma bate com o total de shows, agrupado por base_name) ──
    ranking_const = extract_const(html, 'RANKING')
    if ranking_const is not None:
        soma_ranking = sum(len(v) * int(k) for k, v in ranking_const.items())
        if soma_ranking != total_shows:
            problemas.append(f"soma de RANKING ({soma_ranking}) != total de shows ({total_shows}).")

    # ── COMP_GRUPOS (bandas com >=2 shows, agrupadas por contagem) ──
    comp_grupos_const = extract_const(html, 'COMP_GRUPOS')
    if comp_grupos_const is not None:
        contagem_real = defaultdict(int)
        for bn in bandas:
            c = sum(1 for s in shows if base_name(s['banda']) == bn)
            if c >= 2:
                contagem_real[c] += 1
        for grupo in comp_grupos_const:
            label = grupo.get('label', '')
            m = re.match(r'(\d+) Shows', label)
            if not m:
                avisos.append(f"COMP_GRUPOS: label '{label}' não bate com o padrão 'N Shows'.")
                continue
            count = int(m.group(1))
            qtd_bandas = len(grupo.get('bandas', []))
            if contagem_real.get(count, 0) != qtd_bandas:
                problemas.append(
                    f"COMP_GRUPOS['{label}'] tem {qtd_bandas} banda(s), mas SHOWS indica "
                    f"{contagem_real.get(count, 0)} banda(s) com {count} shows.")
    else:
        avisos.append("COMP_GRUPOS não encontrado ou não parseável no HTML — não validado.")

    # ── ESTILOS (soma dos percentuais) ──
    estilos = extract_const(html, 'ESTILOS')
    if estilos is not None:
        soma_pct = sum(int(e['pct'].rstrip('%')) for e in estilos)
        if not (98 <= soma_pct <= 102):
            problemas.append(f"soma dos percentuais de ESTILOS = {soma_pct}% (esperado ~100%).")

    print(f"Arquivo: {path}")
    print(f"Shows no array: {total_shows} | Bandas distintas: {len(bandas)} | "
          f"Países: {len(paises)} | Eventos: {len(eventos)}")
    print()

    if avisos:
        print("⚠️  AVISOS:")
        for a in avisos:
            print("   -", a)
        print()

    if problemas:
        print("❌ INCONSISTÊNCIAS ENCONTRADAS:")
        for p in problemas:
            print("   -", p)
        sys.exit(1)
    else:
        print("✅ Tudo consistente — nenhuma divergência encontrada.")


if __name__ == '__main__':
    main()
