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
    try:
        return json.loads(m.group(1))
    except json.JSONDecodeError:
        return None  # ex.: COMP_GRUPOS usa sintaxe JS, não JSON puro


def base_name(banda):
    return re.sub(r'\s+(II|III|IV|V)$', '', banda).strip()


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
