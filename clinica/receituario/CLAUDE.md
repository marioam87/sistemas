# Receituário Rápido de Cardiologia — Regras do sistema

Ferramenta web (HTML autocontido, sem dependências externas) usada pelo
Dr. Mario Augusto Mariano (CRM-PR 34.819) no consultório, em Curitiba.
Permite selecionar vários medicamentos espalhados em categorias diferentes e
copiar todos de uma vez, formatados, para colar no prontuário do paciente.

## Arquivos desta pasta

- `receituario.html` — a ferramenta (HTML + CSS + JS num único arquivo, offline)
- `medicamentos.json` — lista de categorias e medicamentos (aba "Cardio")
- `pa.json` — medicamentos usados no pronto atendimento (aba "PA")
- `contatos.json` — especialistas/encaminhamentos (aba "Contatos")
- `CLAUDE.md` — este arquivo

Trate os `.json` e o `.html` como a fonte de verdade — os `.json` são
autoritativos para os dados; qualquer divergência entre eles e o que está
embutido no `.html` deve ser corrigida a favor dos `.json`. A cada alteração
(adicionar, remover, editar medicamento, categoria ou contato), editar a
estrutura de dados correspondente e gerar uma nova versão completa do
`receituario.html`.

## Formato dos dados

Cada categoria segue este formato:

```json
{
  "categoria": "NOME DA CATEGORIA EM MAIUSCULAS",
  "itens": [
    {
      "nome": "NOME DO MEDICAMENTO (MARCA) dose",
      "linhas": ["Posologia linha 1", "Posologia linha 2 (opcional, avisos, observacoes)"]
    }
  ]
}
```

`contatos.json` segue a mesma estrutura, mas os "itens" são linhas de contato
(nome do médico, telefone, endereço) sem posologia.

## Regras de comportamento

1. **Sempre entregar o `.html` completo e funcional**, nunca só um trecho — é
   um arquivo único que abre direto no navegador, sem servidor e sem internet.
2. **Preservar o design e a funcionalidade existentes**, a menos que haja
   pedido explícito para mudar:
   - Cabeçalho com nome e CRM do Dr. Mario
   - **Quatro abas**: "Cardio" (medicamentos.json), "PA" (pa.json),
     "Escores" (calculadoras embutidas, sem fonte de dados externa) e
     "Contatos" (contatos.json). Esse número de abas e seus nomes são um
     invariante — se o arquivo aparecer com uma estrutura diferente
     (ex: 2 abas, ou uma aba "IMC" separada), é sinal de versão revertida/
     desatualizada e não deve ser usado como base sem checagem.
   - A aba **Escores** reúne três calculadoras lado a lado (empilhando em
     telas estreitas), todas sem tabela de referência — só campo(s) de
     entrada e um resultado compacto (número + classificação, colorido em
     verde/âmbar/vermelho conforme a faixa de risco):
     - **IMC**: peso e altura → IMC + classificação (sem tabela da OMS)
     - **RCRI (Lee)**: 6 critérios (checkbox) → pontuação, Classe I-IV e
       descrição do risco (baixo/intermediário/alto)
     - **AUB-HAS2**: 6 critérios (checkbox) → pontuação e risco
       (baixo/intermediário/alto)
     Nenhuma das três calculadoras exibe referência bibliográfica na tela.
   - Busca em tempo real (ignorando acentos), categorias expansíveis/recolhíveis
   - Seleção múltipla entre categorias, mantendo a ordem de clique
   - Painel lateral "Receita em montagem" com cabeçalho fixo **USO CONTÍNUO**,
     itens numerados, botões de mover (▲▼) e remover (×) — oculto na aba
     Escores, junto com a barra de busca (classe `tool-mode` no container
     `.app`)
   - Botão "Copiar receita" (copia USO CONTÍNUO + medicamentos formatados,
     nunca o campo `obs`). A cópia é rich-text: `buildText()` gera o texto
     puro e `buildHtml()` gera a mesma coisa em HTML com
     `font-family: Arial, sans-serif; font-size: 10pt`, e
     `copyToClipboard()` escreve os dois via `navigator.clipboard.write()`
     + `ClipboardItem` (`text/plain` e `text/html`), para colar já em
     Arial 10 no Word/prontuário. Fallback em cascata se `ClipboardItem`
     não existir: `fallbackCopyRich()` (div `contenteditable` + `execCommand
     ('copy')`) → `fallbackCopyPlain()` (textarea simples, texto puro)
   - **Paleta clínica é AZUL, não verde/teal**: `--teal: #1D5FA8`,
     `--teal-dark: #123E6E`, `--teal-soft: #E5EEF8`. Isso já regrediu para a
     paleta verde antiga (`--teal: #0E6F65`) mais de uma vez (mesmo padrão de
     regressão visto antes nas abas) — ao editar cores, conferir os tons
     secundários também (hover de linha, borda do checkbox, fundo do bloco
     `obs`, borda do aside, subtítulo do header, e os tons de risco
     `--success`/`--amber`/`--danger` usados nos cards da aba Escores), que
     tendem a ficar esverdeados junto se a paleta for revertida
3. **Ao adicionar/editar um medicamento**, seguir o padrão dos existentes:
   nome em maiúsculas com marca(s) entre parênteses e dose, depois as linhas de
   posologia exatamente como o Mario prescreve (manter avisos como "Este
   medicamento não pode ser partido" como estão, sem reformular).
4. **Após gerar o HTML**, verificar que: o JSON embutido no `<script>` é válido
   (`node --check`), as 4 abas (`data-tab`: cardio/pa/escores/contatos) estão
   presentes, os blocos `CARDIO`/`PA`/`CONTATOS` embutidos batem byte-a-byte
   com `medicamentos.json`/`pa.json`/`contatos.json`, e que um item com `obs`
   selecionado não vaza esse campo no texto copiado.
5. **Atualizar também os `.json`** sempre que a estrutura de dados mudar, para
   manter tudo sincronizado nas próximas conversas.
6. Se o pedido for ambíguo (ex: "muda a dose do Losartana" sem dizer qual
   categoria/apresentação), **perguntar antes de editar** — é receita médica.

## Fora do escopo

Não prestar aconselhamento clínico nem sugerir doses — apenas organizar e
formatar o texto que o Mario fornece. Qualquer conteúdo clínico (dose,
indicação, interação) vem sempre dele. As calculadoras de risco da aba
Escores usam classificações publicadas (Lee et al. 1999 para o RCRI; Dakik
et al. para o AUB-HAS2) e não devem receber lógica clínica adicional além
do que já está implementado.

---

# Como configurar o Project no claude.ai

1. **Criar o Project:** barra lateral → Projetos → + Novo projeto.
   Nome sugerido: *Receituário Cardio — Dr. Mario*
2. **Colar as instruções:** copiar o conteúdo deste `REGRAS.md` (da seção de
   regras) no campo "Instruções personalizadas" do projeto.
3. **Subir os arquivos de conhecimento:** `medicamentos.json`, `contatos.json`,
   `pa.json` e `receituario.html`.
4. **Usar no dia a dia** — pedir em linguagem natural, por exemplo:
   - "Adiciona a apresentação de 100mg do Entresto"
   - "Remove o Atensina, não uso mais"
   - "Muda a posologia da Rosuvastatina para à noite"
   - "Cria a categoria ANTICOLINÉRGICOS com Oxibutinina 10mg, 1x ao dia"

   O Claude atualiza os dados e devolve o `.html` novo, pronto pra baixar e
   substituir o antigo.

**Dica:** ao receber uma versão nova do `receituario.html` (e dos `.json`, se
mudarem), re-anexar na área de conhecimento do projeto — assim a próxima
conversa parte da versão mais recente.