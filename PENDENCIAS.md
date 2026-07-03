# Pendências e ideias — sistemas

Lista viva do que ficou para depois. Sem prazo; revisitar quando fizer sentido.

## Próximo passo planejado

- [ ] **Ligar o Claude Code na pasta `sistemas`.** Fazer o Claude ler os
  arquivos direto do Mac, acabando com o vaivém de baixar/re-anexar nos
  Projetos. É o retorno de todo o trabalho de organização.

## Backup / nuvem

- [ ] **Backup na nuvem (GitHub privado).** A gaveta é livre de dados de
  paciente, então pode ir com segurança para um repositório privado — backup
  automático + histórico na nuvem, além do pendrive. Combina fazer junto com
  a configuração do Claude Code.

## Organização

- [ ] **README com o mapa das planilhas vivas.** Hoje são só 2 planilhas
  (guardadas fora da gaveta, com dados sensíveis). Quando forem mais, anotar
  no README onde cada `.xlsm` mora, para não se perder.

## Notas técnicas soltas (para quando rodar local no Claude Code)

- `financeiro/milhas/create_milhas.py` aponta para um caminho de entrada antigo
  (`/mnt/user-data/uploads/...`). Ao rodar no Mac, ajustar para o caminho real
  da planilha de milhas.
- `financeiro/orcamento`: o `restore_codenames.py` não está versionado; é
  recriado quando necessário.
- `pessoal/eu-fui/gerar_eu_fui.js` (gerador DOCX) ainda não foi integrado à
  automação do `eu_fui_master.json`.
