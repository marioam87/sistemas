# Receituário Rápido de Cardiologia — Regras do sistema

Ferramenta web (HTML autocontido, sem dependências externas) usada pelo
Dr. Mario Augusto Mariano (CRM-PR 34.819) no consultório, em Curitiba.
Permite selecionar vários medicamentos espalhados em categorias diferentes e
copiar todos de uma vez, formatados, para colar no prontuário do paciente.

## Arquivos desta pasta

- `receituario.html` — a ferramenta (HTML + CSS + JS num único arquivo, offline)
- `medicamentos.json` — lista de categorias e medicamentos (aba "Medicamentos")
- `contatos.json` — especialistas/encaminhamentos (aba "Contatos / Encaminhamentos")
- `pa.json` — medicamentos usados no pronto atendimento
- `REGRAS.md` — este arquivo

Trate os `.json` e o `.html` como a fonte de verdade. A cada alteração
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
   - Duas abas: "Medicamentos" e "Contatos / Encaminhamentos"
   - Busca em tempo real (ignorando acentos), categorias expansíveis/recolhíveis
   - Seleção múltipla entre categorias, mantendo a ordem de clique
   - Painel lateral "Receita em montagem" com cabeçalho fixo **USO CONTÍNUO**,
     itens numerados, botões de mover (▲▼) e remover (×)
   - Botão "Copiar receita" (copia USO CONTÍNUO + medicamentos formatados),
     com fallback caso a Clipboard API falhe
   - Paleta clínica (verde-azulado/teal, fundo claro), tudo funcionando offline
3. **Ao adicionar/editar um medicamento**, seguir o padrão dos existentes:
   nome em maiúsculas com marca(s) entre parênteses e dose, depois as linhas de
   posologia exatamente como o Mario prescreve (manter avisos como "Este
   medicamento não pode ser partido" como estão, sem reformular).
4. **Após gerar o HTML**, verificar que: o JSON embutido no `<script>` é válido,
   categorias/itens novos aparecem nas abas corretas, e busca/cópia funcionam.
5. **Atualizar também os `.json`** sempre que a estrutura de dados mudar, para
   manter tudo sincronizado nas próximas conversas.
6. Se o pedido for ambíguo (ex: "muda a dose do Losartana" sem dizer qual
   categoria/apresentação), **perguntar antes de editar** — é receita médica.

## Fora do escopo

Não prestar aconselhamento clínico nem sugerir doses — apenas organizar e
formatar o texto que o Mario fornece. Qualquer conteúdo clínico (dose,
indicação, interação) vem sempre dele.

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
