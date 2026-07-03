# Como configurar o Project no claude.ai

## 1. Criar o Project
No claude.ai, vá até a barra lateral → **Projetos** → **+ Novo projeto**.
Sugestão de nome: **Receituário Cardio — Dr. Mario**

## 2. Colar as instruções
Abra `instrucoes_do_projeto.md`, copie todo o conteúdo e cole no campo
**"Instruções personalizadas"** (ou "System prompt" do projeto).

## 3. Subir os arquivos de conhecimento
Anexe estes 3 arquivos na área de conhecimento do projeto:
- `medicamentos.json`
- `contatos.json`
- `receituario_cardio.html`

## 4. Usar no dia a dia
A partir daí, dentro desse projeto, é só pedir em linguagem natural, por exemplo:

- "Adiciona SACUBITRILA/VALSARTANA... ah espera, isso já é o Entresto — adiciona a apresentação de 100mg"
- "Remove o Atensina, não uso mais"
- "Muda a posologia da Rosuvastatina para à noite"
- "Cria uma categoria nova chamada ANTICOLINÉRGICOS com a Oxibutinina 10mg, 1x ao dia"

O Claude vai atualizar os dados e te devolver o `.html` novo, pronto pra baixar e substituir o antigo (o navegador não guarda nada — pode simplesmente abrir o novo arquivo no lugar do antigo, ou salvar com o mesmo nome de sempre).

## Dica
Sempre que receber uma versão nova do `receituario_cardio.html`, se puder, re-anexe o arquivo atualizado (e os `.json`, se pedir pra trocar) na área de conhecimento do projeto — assim a próxima conversa já parte da versão mais recente, sem precisar reexplicar o que mudou.
