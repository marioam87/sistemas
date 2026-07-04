# Pendências e ideias — sistemas

Lista viva do que ficou para depois. Sem prazo; revisitar quando fizer sentido.

## Estratégia de execução da plataforma de exames (consolidado em 03/07/2026)

**Contexto:** sem pressa. O sistema atual (LaudoSyn) atende a demanda hoje —
este projeto é para ganhar personalização e se livrar da mensalidade, não
uma urgência operacional. Isso muda como vamos trabalhar:

**Como vamos desenvolver:**
- Tudo feito localmente no Mac de Mario, com o Claude Code logado pela
  assinatura **Pro** (não precisa de API Console/cobrança por token — ver
  decisão detalhada nas notas técnicas mais abaixo).
- Modelo padrão: **Sonnet**. Trocar para **Opus** só em tarefas pontuais de
  raciocínio pesado (arquitetura, bugs difíceis), via `/model`.
- Se o ritmo de trabalho esbarrar nos limites de uso do Pro com frequência,
  avaliar assinar o **Max temporariamente** só durante a fase mais pesada de
  construção — não é uma decisão definitiva, é ajustável mês a mês.
- Publicação no VPS Integrator feita a partir do Mac (comandos remotos via
  Claude Code), sem precisar logar o Claude Code dentro do próprio servidor.

**Como vamos fragmentar o trabalho:**
- Quando começarmos no Claude Code, o primeiro passo é montar um
  **cronograma de implementação em etapas bem definidas** — cada etapa
  pensada para caber dentro das janelas de uso do Pro (5h corridas / limite
  semanal), minimizando gasto de tokens por etapa.
- Preferir muitas etapas pequenas e testáveis a poucas etapas grandes — mais
  fácil de pausar, retomar, e não perder o que já funciona.
- Se o limite de uso acabar no meio de uma etapa, Mario decide na hora entre
  aguardar o reset ou comprar créditos extra — sem pressão para decidir isso
  de antemão.

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

## Identidade visual

- [ ] **Criar um logo para a empresa MP Serviços Médicos.** Vai ser usado na
  etiqueta/cabeçalho dos laudos (hoje a etiqueta usa só texto — CNPJ,
  endereço, contato — sem marca visual).
- [ ] **Pensar e comprar um domínio** para a plataforma. Opções sugeridas
  em 03/07/2026 (nenhuma escolhida ainda):
  1. `mpservicosmedicos.com.br` — nome direto da empresa
  2. `mpsaude.com.br` — curto, fácil de lembrar
  3. `laudosmp.com.br` — reforça a função (laudos)
  4. `mpcardio.com.br` — foco na especialidade
  5. `mariomariano.med.br` — extensão `.med.br`, exclusiva para médicos
     registrados no CFM (exige comprovar CRM); passa mais credibilidade
     institucional

## Plataforma de exames — escopo inicial (levantado em 03/07/2026)

Contexto: hoje Mario paga um sistema de terceiros que faz este fluxo. A ideia
é construir um substituto próprio (`~/sistemas/plataforma-exames/`).

### Como o sistema atual funciona (referência a replicar)

1. Recebe PDF de eletrocardiograma
2. Recebe PDF de MAPA
3. Recebe arquivo `.dat` do Holter Contec (ECG bruto do exame)
4. Mario baixa o `.dat`, faz o laudo do Holter à parte
5. Envia o laudo em PDF de volta ao sistema
6. Contratantes (clínicas/parceiros) baixam o exame já laudado
7. Backup de todos os exames na nuvem (AWS)

### O que o sistema novo precisa ter, no mínimo

- [ ] Disponibilidade 24h — não pode depender de um computador do Mario ligado.
      **Decidido: usar a VPS Integrator como provedor.** Sistema operacional
      do servidor será Linux (padrão de mercado, mais simples e barato — não
      tem relação com Mac/Windows usados em casa).
- [ ] Upload de PDF (ECG e MAPA) e de arquivo `.dat` (Holter Contec)
- [ ] Área para baixar o `.dat` do Holter e subir o laudo em PDF
- [ ] Área de download para os contratantes baixarem o exame laudado
- [ ] Backup automático dos exames na nuvem (AWS, como já é feito hoje)
- [ ] **Novidade em relação ao sistema atual:** área para laudar
      eletrocardiogramas diretamente no site (hoje isso não existe lá)
- [ ] **Assinatura digital em todo exame laudado** — Mario já usa o **Bird ID**
      hoje; integrar ao fluxo novo (além do carimbo que já existe pronto em
      `clinica/mapa/assets/carimbo.png`, usado como imagem — a assinatura
      digital é uma camada extra, com validade jurídica, não é a mesma coisa
      que o carimbo visual)
- [ ] **QR Code por exame** — cada exame laudado gera um QR Code próprio; o
      paciente escaneia e o PDF é salvo automaticamente no celular/computador
      dele (definir: o QR aponta para um link de download, ou já dispara o
      download direto?)

### Fluxo de montagem do laudo final (desenhado em 03/07/2026)

Hoje, no sistema atual (LaudoSyn), o fluxo é: sistema gera automaticamente
a etiqueta da empresa + identificação do paciente + QR code, e Mario cola o
texto do laudo (feito no Word) numa área do site, perdendo a formatação
(tabelas, destaques) do PDF original.

No sistema novo, o formato desejado é um único PDF final, montado por
**concatenação de PDFs em ordem** (tecnologia padrão, sem complexidade):

1. Página(s) geradas automaticamente pelo sistema: etiqueta da empresa +
   identificação do paciente + QR code de rastreabilidade (igual ao atual)
2. O **laudo em PDF já formatado** (tabelas, destaques), gerado pelo fluxo
   próprio (ex.: `clinica/mapa/gerar_laudo_v7.js`) e **anexado como arquivo**
   — não mais colado como texto
3. Na última página do laudo: **carimbo + assinatura digital lado a lado**
   (depende da resposta sobre API do Bird ID, ver item acima)
4. Na sequência: o **PDF completo do exame original**, anexado ao final

Resultado: um único arquivo PDF, com a etiqueta/identificação no início, o
laudo formatado em seguida (assinado), e o exame bruto completo depois.

### Estrutura compacta recomendada (definida em 03/07/2026)

Decidido: usar sobreposição em vez de página dedicada para carimbo+assinatura,
para reduzir o número de páginas do arquivo final.

```
Pág 1:    Etiqueta da empresa + identificação do paciente + QR code
Pág 2-3:  Laudo em PDF (inicia com o NOME DO EXAME — ex.: "MAPA - Contec" —
          seguido do texto do laudo médico). Carimbo + assinatura digital
          ficam SOBREPOSTOS no rodapé da última página do laudo, lado a
          lado (mesma técnica que já centraliza o carimbo hoje no
          gerar_laudo_v7.js — só acrescenta a assinatura ao lado)
Pág 4+:   Exame completo bruto (arquivo original do aparelho — Contec ou
          Micromed)
```

Pendente de ajuste quando o sistema estiver pronto: o fluxo de geração do
laudo (`gerar_laudo_v7.js` e equivalentes) passa a entregar o PDF já
iniciando com o nome/tipo do exame, antes do corpo do laudo — esse é o
arquivo que Mario vai anexar na plataforma como "laudo bruto".

Nome do exame a usar no cabeçalho (MAPA): **MONITORIZAÇÃO AMBULATORIAL DA
PRESSÃO ARTERIAL** (por extenso, não a sigla).

Nome do exame a usar no cabeçalho (Holter): **HOLTER 24h**.

Nome do exame a usar no cabeçalho (Eletrocardiograma): **ELETROCARDIOGRAMA**.

Ideia opcional (não essencial): adicionar marcadores de navegação (bookmarks)
no PDF final, para facilitar pular entre identificação/laudo/exame bruto em
arquivos longos.

### Fluxo do Holter (definido em 03/07/2026) — diferente do MAPA

O Holter usa a mesma ideia de etiqueta + identificação do paciente na
página 1, mas o restante do fluxo é diferente:

```
Pág 1:    Etiqueta da empresa + identificação do paciente + QR code
          (igual ao MAPA)
Pág 2:    Texto do laudo — Gislaini escreve no Word e COLA na caixa de
          texto livre da plataforma (mesmo padrão que Mario usa hoje no
          sistema atual para o MAPA). Termina com CARIMBO CENTRALIZADO
          (sem assinatura digital ao lado, ver abaixo).
Pág 3+:   PDF enviado pelo campo de upload — Gislaini baixa o .dat do
          Holter, monta ELA MESMA um PDF com as informações do exame e
          exemplos de trechos de traçado alterados, e sobe esse PDF
          pronto. O texto da página 2 é lançado JUNTO com os gráficos
          desse PDF (não é o .dat bruto que sobe, é o PDF já montado
          por ela a partir do .dat).
```

Diferenças importantes em relação ao MAPA:
- **Sem autenticação/assinatura digital** nos laudos de Holter, por enquanto
  (decisão inicial — pode mudar no futuro).
- O laudo é **texto colado na caixa livre da plataforma** (escrito primeiro
  no Word), não um PDF anexado como no MAPA.
- **Quem laudo o Holter é a Dra. Gislaini**, não o Mario — então o carimbo
  usado aqui é o dela, **não** o `carimbo.png` de Mario que já está em
  `clinica/mapa/assets/`.

**Pendência:** Mario vai enviar o arquivo do carimbo da Dra. Gislaini para
guardar (local sugerido quando existir: uma pasta própria do Holter, ainda
não criada na gaveta — criar `clinica/holter/` quando for organizar isso).

### Estrutura de acesso — três áreas do sistema (definido em 03/07/2026)

O sistema não é uma coisa só: são **três áreas com acessos diferentes**.

**1. Área do Contratante** (empresas que enviam exames)
Contratantes atuais: **Idealprev**, **Policlínica Sítio Cercado**,
**Policlínica Tatuquara**, **Rio Azul**. Cada contratante só enxerga os
próprios exames: envia exames para laudo e baixa os laudos prontos. Não vê
nada dos outros contratantes nem da área de laudo/administrativa.

**2. Área de Laudo** (Mario + Dra. Gislaini)
É a área que estamos desenhando nas seções acima deste documento — onde os
exames são laudados (MAPA, Holter, ECG).

**3. Área Administrativa** (só Mario, como dono/administrador da empresa)
Inclui:
- Cadastro de novos contratantes
- Ajuste de horários de envio de exames
- Ajuste de horário de trabalho dos colaboradores (ex.: Gislaini)
- Fluxo de caixa dos exames: feito / pago / pagamento pendente
- Informações de acesso da AWS (Amazon, backup)

**Notificação ao contratante (decisão em 03/07/2026 — muda em relação ao
sistema atual):** em vez de e-mail, notificar por **WhatsApp**. Combinar
com cada clínica **um número de WhatsApp de destino** (o número que a
clínica usa para receber a notificação de laudo pronto).

**Arquitetura de WhatsApp — referência do amigo cardiologista (03/07/2026):**
usar a **WhatsApp Business Platform oficial da Meta** (não bibliotecas
não-oficiais). Componentes necessários:
- Conta Meta Business (Business Manager)
- Um número de telefone verificado — é o número ÚNICO que Mario opera,
  de onde partem todas as notificações (não é "um número por clínica" do
  lado de quem envia — cada clínica só precisa ter um número para RECEBER)
- Token de acesso (para autenticar as chamadas à API)
- Webhook — endereço do próprio sistema que a Meta chama quando alguém
  responde uma mensagem

Limitações a considerar no desenho:
- **Janela de 24h:** só é possível mandar mensagem de texto livre a quem
  escreveu nas últimas 24h; fora disso, só com template pré-aprovado
- **Templates de mensagem:** iniciar uma notificação (ex.: "seu laudo está
  pronto") exige um modelo pré-aprovado pela Meta, não texto livre
- **Aprovação de templates:** cada modelo passa por revisão da Meta antes
  de poder ser usado (horas a poucos dias)

Não usar e-mail para essa notificação — WhatsApp substitui completamente.

**Simplificação decidida:** o sistema novo **não vai limitar horário de
envio/recebimento de exames** (o sistema atual tem esse controle no painel
administrador — Mario decidiu não replicar essa limitação).

**Pendência:** Mario vai enviar prints da organização atual desses "3 sites"
(provavelmente as 3 áreas acima, ou os 3 portais dos contratantes — verificar
quando os prints chegarem).

### Layout da tela de laudo — Eletrocardiograma (definido em 03/07/2026)

Tela dividida em duas colunas:
- **Esquerda:** o PDF do eletro aberto, com opção de ampliar (zoom) o
  traçado.
- **Direita:** área de confecção do laudo (detalhes de como funciona essa
  parte ainda não descritos — Mario vai detalhar depois).

**Arquitetura de geração do PDF do laudo — referência do amigo
cardiologista (03/07/2026):**

Fluxo geral: dados estruturados (JSON) → template (arquivo separado, com
variáveis) → renderização (script preenche o template) → PDF final.
É o MESMO padrão que já funciona hoje no MAPA (`gerar_laudo_v7.js`:
docx + LibreOffice) — **não precisa trocar de tecnologia**, dá pra
estender esse padrão pro ECG, a menos que o layout exija algo que o Word
não resolva bem.

Bibliotecas alternativas existentes (caso o padrão atual não seja
suficiente): WeasyPrint (HTML+CSS→PDF, flexível), ReportLab (controle
pixel-perfeito, mais trabalhoso), wkhtmltopdf (projeto parado, evitar).

Boas práticas a manter: template sempre em arquivo separado da lógica de
geração (nunca texto misturado no código), nomes de campo documentados
(como já é feito no `PROMPT_NOVO_LAUDO.md` do MAPA), tudo versionado na
gaveta. Negrito condicional (valor fora da referência) já é convenção
estabelecida em `clinica/labs/CLAUDE.md` — reaplicar a mesma lógica no
laudo de ECG.

### Referência funcional do sistema atual (screenshots recebidos em 03/07/2026)

**Importante:** isto é referência de FUNCIONALIDADE, não de layout/visual. Mario
foi explícito: quer usar como ponto de partida para pensar o sistema novo,
mas não quer reproduzir o mesmo design.

**Painel Administrador** — mais seções do que já tínhamos registrado:
Dashboard (cards: exames não laudados / laudados por tipo em gráfico de rosca
— Eletrocardiograma, Holter, Mapa / exames repetidos, com filtro de período),
Cadastros, **Configurações**, Financeiro, **Modelos**, **Relatórios**, Sistema.

**Painel do Contratante:**
- Tela "Pedidos" (envio de exame): campos Exame, Convênio, Nome do Paciente,
  CPF, Data de Nascimento, Data/Hora de instalação do exame, **Marcapasso**
  (Sim/Não), **Tipo do Pedido** (ex.: "Normal" — outros tipos a confirmar,
  ex.: Urgente?), upload do arquivo do exame, upload de anotações (com opção
  "cliente não preencheu as anotações").
- Tela "Laudos Finalizados": lista para download. O sistema atual **projeta**
  um botão de WhatsApp ao lado do e-mail (ver imagem), mas **não é funcional**
  — é só visual, não dispara nada de fato. No sistema novo, WhatsApp real
  substitui o e-mail (ver decisão de notificação acima).

**Painel Profissional (Mario/Gislaini):**
- Tela "Laudar" (fila de trabalho): o sistema atual divide em "Dentro do
  horário de trabalho" / "Fora do horário de trabalho". **Não será replicado**
  — Mario decidiu não limitar horário de envio/recebimento no sistema novo
  (ver simplificação acima). Fica só como fila única de exames a laudar.
- Tela "Laudos Finalizados": mesma lista, com ações extras de editar/excluir
  (que o contratante não tem).
- Tela "Laudos Repetir": lista dos exames marcados para repetição.

**Campo novo identificado:** cada exame carrega um flag de **Marcapasso**
(Sim/Não) — campo clínico relevante que não estava registrado ainda.

### Perguntas em aberto (decidir mais adiante)

- [ ] Dá para migrar/puxar o histórico de exames do site atual para o novo?
      Sistema atual: **LaudoSyn** (app.laudosyn.com.br), desenvolvido pela
      **Infinnitum Tecnologia** (Curitiba, desde 2006).
      Contato: contato@infinnitum.com.br · (41) 9 9648-1623
      → Perguntar diretamente: exportação em CSV/JSON, ou API disponível?
- [ ] Modelo de autenticação dos contratantes (login/senha, link único, etc.)
- [ ] Formato de entrega do `.dat` do Holter — se precisa de visualizador
      embutido ou só download
- [ ] Bird ID tem API/integração para assinar programaticamente, ou é um
      processo manual (assinar fora e depois subir o PDF já assinado)?
- [ ] QR Code: gerar em cima do link de download do exame, ou embutir o PDF
      direto no QR? (limite de dados de um QR pode não comportar o PDF inteiro
      — provavelmente o caminho é link)
- [ ] **Área de exames laudados** — todos os exames já laudados listados
      juntos, em ordem cronológica (mais recente primeiro), numa área
      separada. Caixa de busca simples por nome do paciente, no topo da
      lista.
- [ ] **Botões "Enviar laudo" e "Repetir exame"** em todas as páginas de
      laudo (ECG, MAPA, Holter). Se "Repetir exame" for acionado, o exame
      **volta para a empresa que enviou a solicitação** e fica pendente até
      que seja reajustado/reenviado por ela.
      → Pergunta em aberto: fica registrado algum motivo da repetição (campo
      de observação), ou é só um botão sem justificativa?
      (a dúvida sobre aviso ao contratante já foi resolvida — vai ser por
      WhatsApp, ver seção de notificação acima)

### Lembrete de sempre

LGPD é requisito desde o início, não ajuste posterior (já registrado no
`plataforma-exames/CLAUDE.md`). Este projeto lida com dado de saúde de
pacientes de terceiros (contratantes) — atenção redobrada.

### Descartado (já discutido — não propor de novo)

- **Medição automática de intervalos de ECG a partir de imagem/PDF do
  traçado** (FC, RR, PR, QRS, ÂQRS, QT, QTc, ST). Discutido em 03/07/2026:
  não é confiável — exige calibração pixel↔tempo/amplitude e detecção exata
  de ondas, que não dá pra fazer com segurança clínica a partir de uma imagem
  estática. Se algum dia isso for revisitado, teria que ser via algoritmo de
  processamento de sinal sobre o dado digital bruto do aparelho (ex.: o
  `.dat` do Holter), nunca por leitura visual de imagem — e mesmo assim,
  precisaria de validação de um especialista antes de confiar no cálculo.

## Notas técnicas soltas (para quando rodar local no Claude Code)

- **Autenticação do Claude Code (decidido em 03/07/2026):** usar login
  normal da assinatura Pro/Max (o mesmo do claude.ai), rodando o Claude Code
  no Mac de Mario — não a API Console (`console.anthropic.com`, cobrança por
  token, usada por terceiros para automação 24/7 dentro de servidor). A
  publicação no VPS é feita via comandos remotos disparados do Mac, sem
  precisar autenticar o Claude Code dentro do próprio servidor.
- `financeiro/milhas/create_milhas.py` aponta para um caminho de entrada antigo
  (`/mnt/user-data/uploads/...`). Ao rodar no Mac, ajustar para o caminho real
  da planilha de milhas.
- `financeiro/orcamento`: o `restore_codenames.py` não está versionado; é
  recriado quando necessário.
- `pessoal/eu-fui/gerar_eu_fui.js` (gerador DOCX) ainda não foi integrado à
  automação do `eu_fui_master.json`.
