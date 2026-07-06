# Pendências e ideias — sistemas

Lista viva do que ficou para depois. Sem prazo; revisitar quando fizer sentido.

**Sobre a organização deste arquivo:** as seções estão agrupadas por
assunto/sistema, não por ordem cronológica de quando foram discutidas. Uma
mesma informação pode aparecer em mais de uma seção quando isso ajuda a
entender aquele contexto sem precisar pular para outra parte do documento.

---

## 1. Pessoas envolvidas (glossário)

- **Mario** — o próprio, cardiologista, dono da MP Serviços Médicos.
  **Administrador** e **Médico** (laudo ECG e MAPA) no site.
- **Léo** — amigo cardiologista. **Não é usuário do site de Mario** — está
  construindo sua própria plataforma de laudos em paralelo, e manda ideias/
  soluções que já funcionam no sistema dele. Suas referências técnicas
  (WhatsApp Business Platform, geração de PDF, PAdES/ICP-Brasil) estão
  registradas neste documento como "referência do amigo cardiologista".
- **Gi (Dra. Gislaini)** — **Médica**, laudo apenas exames de Holter.

---

## 2. Estratégia de execução e forma de trabalho

**Contexto:** sem pressa. O sistema atual (LaudoSyn) atende a demanda hoje —
este projeto é para ganhar personalização e se livrar da mensalidade, não
uma urgência operacional.

**Como desenvolver:**
- Tudo feito localmente no Mac de Mario, com o Claude Code logado pela
  assinatura **Pro** (não precisa de API Console/cobrança por token — ver
  detalhe em "Notas técnicas soltas").
- Modelo padrão: **Sonnet**. Trocar para **Opus** só em tarefas pontuais de
  raciocínio pesado (arquitetura, bugs difíceis), via `/model`.
- Se o ritmo de trabalho esbarrar nos limites de uso do Pro com frequência,
  avaliar assinar o **Max temporariamente** só durante a fase mais pesada de
  construção — decisão ajustável mês a mês, não definitiva.
- Publicação no VPS Integrator feita a partir do Mac (comandos remotos via
  Claude Code), sem precisar logar o Claude Code dentro do próprio servidor.

**Como fragmentar o trabalho:**
- Quando a construção começar de verdade, montar um **cronograma em etapas
  bem definidas** — cada etapa pensada para caber dentro das janelas de uso
  do Pro (5h corridas / limite semanal), minimizando gasto de tokens.
- Preferir muitas etapas pequenas e testáveis a poucas etapas grandes.
- Se o limite de uso acabar no meio de uma etapa, decidir na hora entre
  aguardar o reset ou comprar créditos extra — sem pressão para decidir isso
  de antemão.

**Status:** o Claude Code já está instalado, autenticado e testado com
sucesso na pasta `~/sistemas` (ver "Notas técnicas soltas"). O próximo passo
de fato é montar o cronograma de construção do `site/` quando Mario quiser
começar essa fase.

---

## 3. Site — visão geral

**Contexto:** hoje Mario paga um sistema de terceiros (LaudoSyn) que faz
esse fluxo. A ideia é construir um substituto próprio, em `~/sistemas/site/`.

**O site não é uma coisa só — são três sistemas com login e acesso
próprios:**
- **Sistema Administrador** — só Mario (ver seção 5)
- **Sistema Parceiros** — as clínicas que enviam exames (ver seção 6)
- **Sistema Laudos** — Mario e Gi laudando exames (ver seção 7)

Os três compartilham a mesma tela de entrada (ver seção 4, "Autenticação e
login").

**Tipos de exame:**
- Hoje (escopo inicial): **ECG** (Eletrocardiograma), **MAPA**, **Holter**
- Futuros, sem data definida, entram na fila depois do escopo inicial:
  **Ecocardiograma transtorácico (ECOTT)** e **Doppler de carótidas e
  vertebrais (DCV)**. Modelos de referência de estrutura de laudo já
  guardados na gaveta (sem dado de paciente), para uso futuro no desenho do
  template de cada um (mesmo padrão JSON → template → PDF do MAPA):
  - `site/referencias/ecott/ecott - modelo laudo.docx`
  - `site/referencias/dcv/dcv - modelo laudo.pdf`

**Como o sistema atual (LaudoSyn) funciona hoje** (referência a replicar/
substituir):
1. Recebe PDF de eletrocardiograma
2. Recebe PDF de MAPA
3. Recebe arquivo `.dat` do Holter Contec (ECG bruto do exame)
4. Mario baixa o `.dat`, faz o laudo do Holter à parte
5. Envia o laudo em PDF de volta ao sistema
6. Parceiros (clínicas) baixam o exame já laudado
7. Backup de todos os exames na nuvem (AWS)

**Lembrete de sempre — LGPD:** requisito desde o início do projeto, não
ajuste posterior (já registrado no `site/CLAUDE.md`). O site lida com dado
de saúde de pacientes de terceiros (parceiros) — atenção redobrada em toda
decisão de arquitetura.

**Infraestrutura já decidida:**
- Disponibilidade 24h sem depender de computador ligado → **VPS Integrator**
  como provedor, sistema operacional **Linux** (padrão de mercado, sem
  relação com Mac/Windows usados em casa)
- Backup automático dos exames na nuvem (AWS, como já é feito hoje)

---

## 4. Autenticação e login (compartilhado pelos três sistemas)

Uma única tela de login serve para os três sistemas — não são sites
separados; é um único ponto de entrada que direciona para o sistema certo
conforme o usuário/senha usados.

**Layout da tela, de cima para baixo:**
1. Logo da empresa (depende do nome fantasia, ver seção 12)
2. Campo de texto: **Usuário**
3. Campo de texto: **Senha**
4. Botão **Entrar**
5. Botão **Esqueci a senha**

**Regra de senha:** 6 a 8 caracteres, com letras e números, pelo menos
1 letra maiúscula e 1 caractere especial.

**Fluxo de "Esqueci a senha" (por questão de segurança):** a senha nunca é
armazenada de forma legível nem visível para o administrador (prática
padrão — senhas ficam guardadas de forma criptografada e irreversível, o
"hash"). Em vez do administrador "ver a senha nova":
- O usuário esquece a senha → recebe um link/código para **criar uma senha
  nova**, sem ninguém (nem o admin) ver qual ele escolheu.
- Se o administrador precisar destravar alguém manualmente, ele **atribui
  uma senha temporária** (não vê a senha que a pessoa escolheria) — e ela
  troca no primeiro acesso seguinte.
  Isso preserva a necessidade prática de Mario (ajudar alguém travado sem
  acesso) sem guardar senhas de forma exposta.

**Contas previstas no lançamento (login único, roteado por perfil):**
| Sistema | Quem | Nº de contas |
|---|---|---|
| Administrador | Mario | 1 |
| Laudos | Mario + Gi (cada um com login próprio) | 2 |
| Parceiros | Idealprev, Policlínica Sítio Cercado, Policlínica Tatuquara, Rio Azul (uma conta por clínica) | 4 |

---

## 5. Sistema Administrador

Só Mario tem acesso. Funções previstas:
- Cadastro de novos parceiros
- Ajuste de horário de trabalho dos colaboradores (ex.: Gi)
- Fluxo de caixa dos exames: feito / pago / pagamento pendente
- Informações de acesso da AWS (Amazon, backup)
- Seção **"Termos"** (ver seção 11 — mesmos documentos também aparecem no
  Sistema Parceiros)

~~Ajuste de horários de envio/recebimento de exames~~ — descartado, ver
seção 9 ("Simplificações decididas").

**Referência do sistema atual (screenshots, não é para copiar o visual):**
Dashboard com cards (exames não laudados / laudados por tipo em gráfico de
rosca — ECG, Holter, MAPA / exames repetidos, com filtro de período), e
menus: Cadastros, Configurações, Financeiro, Modelos, Relatórios, Sistema.

---

## 6. Sistema Parceiros

**Quem usa:** as clínicas que enviam exames para laudo — **Idealprev**,
**Policlínica Sítio Cercado**, **Policlínica Tatuquara**, **Rio Azul**. Cada
parceiro só enxerga os próprios exames; não vê nada dos outros parceiros
nem dos outros sistemas.

**O que um parceiro faz:**
- Envia um pedido de exame (formulário de upload)
- Recebe uma notificação quando o laudo fica pronto (ver seção 10 —
  Notificações via WhatsApp)
- Baixa o exame já laudado
- Pode ver a seção **"Termos"** (ver seção 11 — mesmos documentos também
  aparecem no Sistema Administrador)

**Botão "Repetir exame":** se um médico aciona esse botão (ver seção 7), o
exame volta para o parceiro que enviou a solicitação, e fica pendente até
que seja reajustado/reenviado por ele.
→ Pergunta em aberto: fica registrado algum motivo da repetição (campo de
observação), ou é só um botão sem justificativa?

**Referência do sistema atual (screenshots, não é para copiar o visual) —
tela "Pedidos" (envio de exame):** campos Exame, Convênio, Nome do
Paciente, CPF, Data de Nascimento, Data/Hora de instalação do exame,
**Marcapasso** (Sim/Não — campo clínico relevante identificado), **Tipo do
Pedido** (ex.: "Normal" — outros tipos a confirmar, ex.: Urgente?), upload
do arquivo do exame, upload de anotações (com opção "cliente não preencheu
as anotações").

**Referência do sistema atual — tela "Laudos Finalizados":** lista para
download. O sistema atual **projeta** um botão de WhatsApp ao lado do
e-mail, mas **não é funcional** — é só visual, não dispara nada de fato. No
site novo, WhatsApp real substitui o e-mail (ver seção 10).

---

## 7. Sistema Laudos

**Quem usa:** Mario e Gi, cada um com login próprio — mas **cada um só
recebe e laudo um tipo de exame:**
- **Gi:** apenas **Holter**
- **Mario:** **ECG** e **MAPA**

A fila de exames a laudar deve ser **filtrada por usuário logado** — Gi não
vê exames de ECG/MAPA na fila dela, e Mario não vê exames de Holter na dele.

**Notificação de pedido novo (entrada):** quando um parceiro envia um
pedido, o médico responsável é avisado na hora por WhatsApp (ver seção 10
para a arquitetura completa):
- **ECG ou MAPA** → avisa **Mario**, no número **+55 41 99908-4472**
- **Holter** → avisa **Gi**, no número **+55 41 99995-1121**

**Botões em toda página de laudo (ECG, MAPA, Holter):** "Enviar laudo" e
"Repetir exame" (este último devolve o exame ao parceiro, ver seção 6).

**Área de exames laudados:** todos os exames já laudados listados juntos,
em ordem cronológica (mais recente primeiro), numa área separada. Caixa de
busca simples por nome do paciente, no topo da lista.

**Referência do sistema atual (screenshots, não é para copiar o visual):**
- Tela "Laudar" (fila de trabalho): o sistema atual divide em "Dentro do
  horário de trabalho" / "Fora do horário de trabalho" — **não será
  replicado** (ver seção 9, sem limite de horário). Fica só como fila única.
- Tela "Laudos Finalizados": mesma lista do parceiro, com ações extras de
  editar/excluir que o parceiro não tem.
- Tela "Laudos Repetir": lista dos exames marcados para repetição.

### 7.1 MAPA — fluxo do laudo

Estrutura do PDF final (montado por concatenação, técnica padrão):
```
Pág 1:    Etiqueta da empresa + identificação do paciente + QR code
Pág 2-3:  Laudo em PDF (inicia com o NOME DO EXAME por extenso — ver
          abaixo — seguido do texto do laudo médico). Carimbo +
          assinatura digital SOBREPOSTOS no rodapé da última página
          (mesma técnica que já centraliza o carimbo hoje no
          gerar_laudo_v7.js — só acrescenta a assinatura ao lado)
Pág 4+:   Exame completo bruto (arquivo original do aparelho — Contec
          ou Micromed)
```

**Nome do exame no cabeçalho:** MONITORIZAÇÃO AMBULATORIAL DA PRESSÃO
ARTERIAL (por extenso, não a sigla).

Pendente de ajuste quando o site estiver pronto: o `gerar_laudo_v7.js` (e
equivalentes) passa a entregar o PDF já iniciando com o nome do exame,
antes do corpo do laudo — esse é o arquivo que Mario vai anexar no site
como "laudo bruto".

Contexto do fluxo atual (LaudoSyn), que está sendo substituído: hoje o
sistema gera a etiqueta+identificação+QR automaticamente, e Mario cola o
texto do laudo (feito no Word) numa área do site, perdendo a formatação
(tabelas, destaques) do PDF original. O fluxo novo resolve isso anexando o
PDF já formatado, em vez de colar texto.

Ideia opcional (não essencial): marcadores de navegação (bookmarks) no PDF
final, para pular entre identificação/laudo/exame bruto em arquivos longos.

### 7.2 Holter — fluxo do laudo (diferente do MAPA)

```
Pág 1:    Etiqueta da empresa + identificação do paciente + QR code
          (igual ao MAPA)
Pág 2:    Texto do laudo — Gi escreve no Word e COLA na caixa de texto
          livre do site. Termina com CARIMBO CENTRALIZADO (sem
          assinatura digital ao lado, ver abaixo).
Pág 3+:   PDF enviado pelo campo de upload — Gi baixa o .dat do Holter,
          monta ELA MESMA um PDF com as informações do exame e exemplos
          de trechos de traçado alterados, e sobe esse PDF pronto. O
          texto da página 2 é lançado JUNTO com os gráficos desse PDF
          (não é o .dat bruto que sobe, é o PDF já montado por ela).
```

**Nome do exame no cabeçalho:** HOLTER 24h.

**Diferenças importantes em relação ao MAPA:**
- **Sem autenticação/assinatura digital** por enquanto (decisão inicial,
  pode mudar no futuro).
- O laudo é **texto colado na caixa livre** (escrito primeiro no Word), não
  um PDF anexado.
- **Quem laudo é a Gi**, não o Mario — o carimbo usado aqui é o dela,
  **não** o `carimbo.png` de Mario já guardado em `clinica/mapa/assets/`.

**Pendência:** Mario vai enviar o arquivo do carimbo da Gi. Sugestão de
local: criar `clinica/holter/` na gaveta quando for organizar isso.

**Pergunta em aberto:** formato de entrega do `.dat` do Holter no site — se
precisa de visualizador embutido ou só download.

### 7.3 ECG (Eletrocardiograma) — layout e arquitetura

**Novidade em relação ao sistema atual:** laudar ECG diretamente no site
(hoje isso não existe no LaudoSyn).

**Nome do exame no cabeçalho:** ELETROCARDIOGRAMA.

**Layout da tela de laudo:** dividida em duas colunas.
- **Esquerda:** o PDF do eletro aberto, com opção de ampliar (zoom).
- **Direita:** área de confecção do laudo (detalhes de como funciona essa
  parte ainda não descritos — a detalhar).

**Arquitetura de geração do PDF do laudo — referência do amigo
cardiologista:** fluxo geral é dados estruturados (JSON) → template
(arquivo separado, com variáveis) → renderização (script preenche o
template) → PDF final. É o **mesmo padrão que já funciona no MAPA**
(`gerar_laudo_v7.js`: docx + LibreOffice) — não precisa trocar de
tecnologia, a menos que o layout exija algo que o Word não resolva bem.

Bibliotecas alternativas existentes (caso o padrão atual não seja
suficiente): WeasyPrint (HTML+CSS→PDF, flexível), ReportLab (controle
pixel-perfeito, mais trabalhoso), wkhtmltopdf (projeto parado, evitar).

Boas práticas a manter: template sempre em arquivo separado da lógica de
geração, nomes de campo documentados (como no `PROMPT_NOVO_LAUDO.md` do
MAPA), tudo versionado na gaveta. Negrito condicional (valor fora da
referência) já é convenção estabelecida em `clinica/labs/CLAUDE.md` —
reaplicar a mesma lógica no laudo de ECG.

**Nota importante — descartado:** medição automática de intervalos de ECG
a partir de imagem/PDF do traçado (FC, RR, PR, QRS, ÂQRS, QT, QTc, ST) foi
avaliada e **descartada** — não é confiável, exige calibração
pixel↔tempo/amplitude e detecção exata de ondas que não dá para fazer com
segurança clínica a partir de uma imagem estática. Se algum dia for
revisitado, só via algoritmo de processamento de sinal sobre o dado
digital bruto do aparelho (nunca leitura visual de imagem), e mesmo assim
precisaria de validação de um especialista.

### 7.4 Futuro: Ecocardiograma (ECOTT) e Doppler de Carótidas (DCV)

Sem data definida — entram na fila depois do escopo inicial (ECG, MAPA,
Holter). Modelos de referência de estrutura já guardados (ver seção 3).

---

## 8. Seção "Termos" (aparece no Sistema Administrador e no Sistema Parceiros)

Ambos os sistemas terão uma seção chamada **"Termos"**, exibindo os
arquivos já preparados em `site/termos/`:
- `HOLTER - orientações.docx`
- `MAPA - orientações.docx`
- `relatório de atividades.docx`
- `termo de autorização dos dados.docx`
- `termo de responsabilidade.docx`

São modelos/formulários genéricos (sem dado de paciente).

**Detalhes ainda em aberto:**
- Cada perfil vê os 5 documentos, ou um subconjunto?
- É só visualização/download, ou também upload de versão assinada?
- Entra como subseção dentro de uma tela já mapeada (ex.: Cadastros,
  Configurações) ou como item novo no menu?

---

## 9. Notificações via WhatsApp

**Duas direções de notificação, ambas por WhatsApp (não e-mail):**

1. **Saída — parceiro avisado quando o laudo fica pronto.** Combinar com
   cada clínica um número de WhatsApp de destino (ver seção 6). Isso muda
   o comportamento do sistema atual, que usa e-mail (e tem um botão de
   WhatsApp só visual, não funcional).
2. **Entrada — médico avisado quando chega um pedido novo** (ver seção 7):
   ECG/MAPA avisam Mario (+55 41 99908-4472), Holter avisa Gi
   (+55 41 99995-1121).

**Arquitetura técnica — referência do amigo cardiologista:** usar a
**WhatsApp Business Platform oficial da Meta** (não bibliotecas
não-oficiais). Componentes necessários:
- Conta Meta Business (Business Manager)
- Um número de telefone verificado — o número ÚNICO que Mario opera, de
  onde partem todas as notificações (não é "um número por clínica" do lado
  de quem envia — cada clínica só precisa de um número para RECEBER)
- Token de acesso (autenticação das chamadas à API)
- Webhook — endereço do próprio sistema que a Meta chama quando alguém
  responde uma mensagem

**Limitações a considerar no desenho:**
- **Janela de 24h:** só é possível mandar mensagem de texto livre a quem
  escreveu nas últimas 24h; fora disso, só com template pré-aprovado
- **Templates de mensagem:** iniciar uma notificação (ex.: "seu laudo está
  pronto", "novo pedido recebido") exige um modelo pré-aprovado pela Meta
- **Aprovação de templates:** cada modelo passa por revisão da Meta antes
  de poder ser usado (horas a poucos dias)

---

## 10. Assinatura digital, carimbo e QR Code

**Assinatura digital:** Mario já usa o **Bird ID** hoje. Integrar ao fluxo
novo, além do carimbo visual que já existe (`clinica/mapa/assets/
carimbo.png`) — a assinatura digital é uma camada extra, com validade
jurídica, diferente do carimbo (que é só imagem).

**Padrão técnico de referência — amigo cardiologista:** o padrão correto de
assinatura digital em PDF no Brasil é **PAdES** (PDF Advanced Electronic
Signatures) com **cadeia ICP-Brasil** — não é "colar uma imagem de
assinatura", é assinatura criptográfica com validade jurídica real.
→ Pergunta em aberto: o Bird ID tem API/integração para assinar
programaticamente, ou é um processo manual (assinar fora e subir o PDF já
assinado)? Confirmar se gera assinatura nesse formato.

**Onde entra no PDF final:** carimbo + assinatura digital sobrepostos, lado
a lado, no rodapé da última página do laudo (ver seção 7.1, estrutura do
MAPA). Não se aplica ao Holter por enquanto (ver seção 7.2).

**Roteiro de validação — referência do amigo cardiologista** (guardar para
quando a integração estiver pronta para testes):
1. **Assinar um PDF de teste no VPS** e conferir a assinatura PAdES + cadeia
   ICP-Brasil diretamente (verificação técnica).
2. **Validação oficial:** levar o PDF a
   [validar.iti.gov.br](https://validar.iti.gov.br) — validador oficial do
   governo brasileiro — para confirmar que a assinatura é reconhecida.
3. **Teste final de ponta a ponta:** pelo celular, direto no domínio do
   site, laudar um ECG e um MAPA de teste, e conferir se o PDF final sai
   assinado, com timbre e fontes corretas, na hora.

**QR Code:** cada exame laudado gera um QR Code próprio; o paciente
escaneia e o PDF é salvo automaticamente no celular/computador dele.
→ Pergunta em aberto: o QR aponta para um link de download, ou tenta
embutir o PDF direto? (limite de dados de um QR provavelmente não comporta
um PDF inteiro — o caminho mais realista é link).

---

## 11. Simplificações decididas (em relação ao sistema atual)

- **Sem limite de horário de envio/recebimento de exames.** O sistema atual
  tem esse controle no painel administrador (divisão "dentro/fora do
  horário de trabalho"); Mario decidiu não replicar essa limitação no site
  novo.
- **E-mail substituído por WhatsApp** em toda notificação (ver seção 9).

---

## 12. Identidade visual e domínio

- [ ] **Escolher um nome fantasia.** Decidido: o site, a logomarca e a
  comunicação dos laudos vão usar um **nome fantasia**, diferente da razão
  social "MP Serviços Médicos" (a esposa de Mario não gostou do nome para
  essa finalidade). A empresa continua sendo "MP Serviços Médicos S/S" no
  CNPJ/documentos oficiais — só o nome voltado ao público muda. Nome ainda
  não escolhido.
  → Nota técnica: para usar oficialmente vinculado ao CNPJ (recomendado,
  evita alguém registrar o mesmo nome depois), formalizar como nome
  fantasia na Junta Comercial — passo simples, normalmente resolvido pelo
  contador.
- [ ] **Criar um logo** para o nome fantasia (ainda a escolher). Vai ser
  usado na etiqueta/cabeçalho dos laudos (hoje a etiqueta usa só texto —
  CNPJ, endereço, contato — sem marca visual).
- [ ] **Comprar o domínio.** As opções sugeridas anteriormente (baseadas em
  "MP Serviços Médicos") ficam **em suspenso** até o nome fantasia ser
  definido — o domínio deve seguir o nome fantasia, não a razão social.
  `mpservicosmedicos.com.br` segue confirmado como disponível (verificado
  em 03/07/2026), mas provavelmente não será o escolhido.

---

## 13. Perguntas em aberto (consolidado)

- [ ] Dá para migrar/puxar o histórico de exames do LaudoSyn para o site
  novo? Sistema atual desenvolvido pela **Infinnitum Tecnologia** (Curitiba,
  desde 2006). Contato: contato@infinnitum.com.br · (41) 9 9648-1623.
  Perguntar diretamente: exportação em CSV/JSON, ou API disponível?
- [ ] Formato de entrega do `.dat` do Holter no site — visualizador
  embutido ou só download? (seção 7.2)
- [ ] Bird ID tem API para assinar programaticamente, ou é processo manual?
  Confirma formato PAdES/ICP-Brasil? (seção 10)
- [ ] QR Code: link de download, ou tentar embutir o PDF? (seção 10)
- [ ] Botão "Repetir exame": fica registrado o motivo, ou é só o botão sem
  justificativa? (seção 6)
- [ ] Seção "Termos": subconjunto por perfil? view/download só, ou também
  upload de versão assinada? Onde entra no menu? (seção 8)
- [ ] Layout da confecção do laudo de ECG (lado direito da tela) — Mario
  vai detalhar (seção 7.3)
- [ ] Prints da organização atual dos "3 sites" — aguardando envio, para
  confirmar se equivalem aos 3 sistemas já mapeados aqui

---

## 14. Backup / nuvem

- [ ] **Backup na nuvem (GitHub privado).** A gaveta é livre de dados de
  paciente, então pode ir com segurança para um repositório privado — backup
  automático + histórico na nuvem, além do pendrive. Fazer quando avançar
  na construção do site.

## 15. Organização geral da gaveta

- [ ] **README com o mapa das planilhas vivas.** Hoje são só 2 planilhas
  (guardadas fora da gaveta, com dados sensíveis). Quando forem mais, anotar
  no README onde cada `.xlsm` mora, para não se perder.

## 16. Notas técnicas soltas

- Claude Code testado e funcionando (03/07/2026), lendo corretamente os
  `CLAUDE.md` das subpastas.
- **Autenticação do Claude Code:** usar login normal da assinatura Pro/Max
  (o mesmo do claude.ai), rodando o Claude Code no Mac de Mario — não a API
  Console (`console.anthropic.com`, cobrança por token, usada por terceiros
  para automação 24/7 dentro de servidor). A publicação no VPS é feita via
  comandos remotos disparados do Mac, sem autenticar o Claude Code dentro
  do próprio servidor.
- `financeiro/milhas/create_milhas.py` aponta para um caminho de entrada
  antigo (`/mnt/user-data/uploads/...`). Ao rodar no Mac, ajustar para o
  caminho real da planilha de milhas.
- `financeiro/orcamento`: o `restore_codenames.py` não está versionado; é
  recriado quando necessário.
- `pessoal/eu-fui/gerar_eu_fui.js` (gerador DOCX) ainda não foi integrado à
  automação do `eu_fui_master.json`.
