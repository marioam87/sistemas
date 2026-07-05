# Pendências e ideias — sistemas

Lista viva do que ficou para depois. Sem prazo; revisitar quando fizer sentido.

## Pessoas envolvidas (glossário — atualizado em 03/07/2026)

- **Mario** — o próprio, cardiologista, dono da MP Serviços Médicos.
  **Administrador** e **Médico** (laudo ECG e MAPA).
- **Léo** — amigo cardiologista. **Não é usuário do sistema de Mario** —
  está construindo sua própria plataforma de laudos em paralelo, e manda
  ideias/soluções que já funcionam no sistema dele. Suas referências
  técnicas (WhatsApp Business Platform, geração de PDF, PAdES/ICP-Brasil)
  estão registradas neste documento como "referência do amigo cardiologista".
- **Gi (Dra. Gislaini)** — **Médica**, laudo apenas exames de Holter.

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

- [ ] **Escolher um nome fantasia.** Decidido em 04/07/2026: o site, a
  logomarca e a comunicação dos laudos vão usar um **nome fantasia**,
  diferente da razão social "MP Serviços Médicos" (a esposa de Mario não
  gostou do nome para essa finalidade). A empresa continua sendo "MP
  Serviços Médicos S/S" no CNPJ/documentos oficiais — só o nome voltado ao
  público muda. Nome ainda não escolhido.
  → Nota técnica: para usar oficialmente vinculado ao CNPJ (recomendado,
  evita alguém registrar o mesmo nome depois), formalizar como nome
  fantasia na Junta Comercial — passo simples, normalmente resolvido pelo
  contador.
- [ ] **Criar um logo** para o nome fantasia (que ainda será escolhido).
  Vai ser usado na etiqueta/cabeçalho dos laudos (hoje a etiqueta usa só
  texto — CNPJ, endereço, contato — sem marca visual).
- [ ] **Comprar o domínio.** As opções sugeridas anteriormente (baseadas em
  "MP Serviços Médicos") ficam **em suspenso** até o nome fantasia ser
  definido — o domínio deve seguir o nome fantasia escolhido, não a razão
  social. `mpservicosmedicos.com.br` segue confirmado como disponível, mas
  provavelmente não será o escolhido.

## Plataforma de exames — escopo inicial (levantado em 03/07/2026)

Contexto: hoje Mario paga um sistema de terceiros que faz este fluxo. A ideia
é construir um substituto próprio (`~/sistemas/site/`).

### Como o sistema atual funciona (referência a replicar)

1. Recebe PDF de eletrocardiograma
2. Recebe PDF de MAPA
3. Recebe arquivo `.dat` do Holter Contec (ECG bruto do exame)
4. Mario baixa o `.dat`, faz o laudo do Holter à parte
5. Envia o laudo em PDF de volta ao sistema
6. Parceiros (clínicas) baixam o exame já laudado
7. Backup de todos os exames na nuvem (AWS)

### O que o sistema novo precisa ter, no mínimo

- [ ] Disponibilidade 24h — não pode depender de um computador do Mario ligado.
      **Decidido: usar a VPS Integrator como provedor.** Sistema operacional
      do servidor será Linux (padrão de mercado, mais simples e barato — não
      tem relação com Mac/Windows usados em casa).
- [ ] Upload de PDF (ECG e MAPA) e de arquivo `.dat` (Holter Contec)
- [ ] Área para baixar o `.dat` do Holter e subir o laudo em PDF
- [ ] Área de download para os parceiros baixarem o exame laudado
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
Pág 2:    Texto do laudo — Gi escreve no Word e COLA na caixa de
          texto livre da plataforma (mesmo padrão que Mario usa hoje no
          sistema atual para o MAPA). Termina com CARIMBO CENTRALIZADO
          (sem assinatura digital ao lado, ver abaixo).
Pág 3+:   PDF enviado pelo campo de upload — Gi baixa o .dat do
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
- **Quem laudo o Holter é a Gi**, não o Mario — então o carimbo
  usado aqui é o dela, **não** o `carimbo.png` de Mario que já está em
  `clinica/mapa/assets/`.

**Pendência:** Mario vai enviar o arquivo do carimbo da Gi para
guardar (local sugerido quando existir: uma pasta própria do Holter, ainda
não criada na gaveta — criar `clinica/holter/` quando for organizar isso).

### Estrutura de acesso — três sistemas (definido em 03/07/2026)

Não é uma coisa só: são **três sistemas com acessos diferentes**, chamados
de **Sistema Parceiros**, **Sistema Laudos** e **Sistema Administrador**
(nomenclatura padronizada — ver também seção "Tela de login").

**1. Sistema Parceiros** (empresas que enviam exames)
Parceiros atuais: **Idealprev**, **Policlínica Sítio Cercado**,
**Policlínica Tatuquara**, **Rio Azul**. Cada parceiro só enxerga os
próprios exames: envia exames para laudo e baixa os laudos prontos. Não vê
nada dos outros parceiros nem dos outros sistemas.

**2. Sistema Laudos** (Mario + Gi)
É o sistema que estamos desenhando nas seções acima deste documento — onde
os exames são laudados (MAPA, Holter, ECG).

**3. Sistema Administrador** (só Mario, como dono/administrador da empresa)
Inclui:
- Cadastro de novos parceiros
- ~~Ajuste de horários de envio de exames~~ (removido — ver decisão de não
  limitar horário de envio/recebimento, mais abaixo)
- Ajuste de horário de trabalho dos colaboradores (ex.: Gi)
- Fluxo de caixa dos exames: feito / pago / pagamento pendente
- Informações de acesso da AWS (Amazon, backup)

**Notificação ao parceiro (decisão em 03/07/2026 — muda em relação ao
sistema atual):** em vez de e-mail, notificar por **WhatsApp**. Combinar
com cada clínica **um número de WhatsApp de destino** (o número que a
clínica usa para receber a notificação de laudo pronto).

**Notificação ao médico de novo pedido recebido (definido em 04/07/2026):**
quando um parceiro envia um pedido de exame, o médico responsável recebe
um aviso por WhatsApp na hora, segmentado por tipo de exame:
- **ECG ou MAPA** → avisa **Mario**, no número **+55 41 99908-4472**
- **Holter** → avisa **Gi**, no número **+55 41 99995-1121**

Isso é notificação de ENTRADA (pedido novo chegando), complementar à
notificação de SAÍDA já registrada acima (parceiro avisado quando o laudo
fica pronto).

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
  pronto", ou "novo pedido recebido") exige um modelo pré-aprovado pela
  Meta, não texto livre
- **Aprovação de templates:** cada modelo passa por revisão da Meta antes
  de poder ser usado (horas a poucos dias)

Não usar e-mail para essa notificação — WhatsApp substitui completamente.

**Simplificação decidida:** o sistema novo **não vai limitar horário de
envio/recebimento de exames** (o sistema atual tem esse controle no painel
administrador — Mario decidiu não replicar essa limitação).

**Pendência:** Mario vai enviar prints da organização atual desses "3 sites"
(provavelmente os 3 sistemas acima, ou os 3 portais dos parceiros — verificar
quando os prints chegarem).

### Tela de login (definida em 03/07/2026)

Layout, de cima para baixo:
1. Logo da empresa (MP Serviços Médicos) — depende da pendência de criar o
   logo, ver seção "Identidade visual"
2. Campo de texto: **Usuário**
3. Campo de texto: **Senha**
4. Botão **Entrar**
5. Botão **Esqueci a senha**

**Regra de senha:** 6 a 8 caracteres, com letras e números, pelo menos
1 letra maiúscula e 1 caractere especial.

**Fluxo de "Esqueci a senha" (ajustado por questão de segurança em
03/07/2026):** a senha nunca é armazenada de forma legível nem visível para
o administrador (prática de segurança padrão — senhas ficam guardadas de
forma criptografada e irreversível, o chamado "hash"). Em vez de o
administrador "ver a senha nova", o fluxo é:
- O usuário esquece a senha → recebe um link/código para **criar uma senha
  nova**, sem ninguém (nem o admin) ver qual ele escolheu.
- Se o administrador (Mario) precisar destravar alguém manualmente, ele
  **atribui uma senha temporária** para a pessoa (não vê a senha que ela
  escolheria) — e ela troca no primeiro acesso seguinte.

Isso preserva a necessidade prática de Mario (poder ajudar alguém travado
sem acesso), sem guardar senhas de forma exposta — importante porque a
plataforma lida com dado de saúde de terceiros (ver lembrete de LGPD já
registrado).

**Login único, acesso roteado por perfil (definido em 03/07/2026):** a
mesma tela de login serve para os três sistemas — não são sites
separados, é um único ponto de entrada que direciona para o sistema certo
conforme o usuário/senha usados. Nomenclatura padronizada (ver também
"Estrutura de acesso — três sistemas", mais abaixo):

- **Sistema Administrador** — só Mario. Um único login.
- **Sistema Laudos** — onde os exames são laudados. Dois médicos
  habilitados por enquanto: Mario e Gi, **cada um com seu próprio login**.
- **Sistema Parceiros** — uma clínica envia exames e recebe laudos por
  aqui. **Cada clínica tem seu próprio login** (Idealprev, Policlínica
  Sítio Cercado, Policlínica Tatuquara, Rio Azul).

Resumo de contas previstas no lançamento: 1 login de Sistema Administrador
(Mario), 2 logins de Sistema Laudos (Mario + Gi), 4 logins de Sistema
Parceiros (um por clínica).

**Divisão de exames dentro do Sistema Laudos (definida em 03/07/2026):**
apesar de os dois terem login no mesmo sistema, cada um só recebe e laudo
um tipo de exame:
- **Gi:** apenas **Holter**
- **Mario:** **ECG** (eletrocardiograma) e **MAPA**

Ou seja, a fila de exames a laudar deve ser filtrada por usuário logado —
Gi não vê exames de ECG/MAPA na fila dela, e Mario não vê exames de Holter
na dele.

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

**Sistema Administrador (referência do sistema atual)** — mais seções do
que já tínhamos registrado: Dashboard (cards: exames não laudados / laudados
por tipo em gráfico de rosca — Eletrocardiograma, Holter, Mapa / exames
repetidos, com filtro de período), Cadastros, **Configurações**, Financeiro,
**Modelos**, **Relatórios**, Sistema.

**Sistema Parceiros (referência do sistema atual):**
- Tela "Pedidos" (envio de exame): campos Exame, Convênio, Nome do Paciente,
  CPF, Data de Nascimento, Data/Hora de instalação do exame, **Marcapasso**
  (Sim/Não), **Tipo do Pedido** (ex.: "Normal" — outros tipos a confirmar,
  ex.: Urgente?), upload do arquivo do exame, upload de anotações (com opção
  "cliente não preencheu as anotações").
- Tela "Laudos Finalizados": lista para download. O sistema atual **projeta**
  um botão de WhatsApp ao lado do e-mail (ver imagem), mas **não é funcional**
  — é só visual, não dispara nada de fato. No sistema novo, WhatsApp real
  substitui o e-mail (ver decisão de notificação acima).

**Sistema Laudos (Mario/Gi) — referência do sistema atual:**
- Tela "Laudar" (fila de trabalho): o sistema atual divide em "Dentro do
  horário de trabalho" / "Fora do horário de trabalho". **Não será replicado**
  — Mario decidiu não limitar horário de envio/recebimento no sistema novo
  (ver simplificação acima). Fica só como fila única de exames a laudar.
- Tela "Laudos Finalizados": mesma lista, com ações extras de editar/excluir
  (que o parceiro não tem).
- Tela "Laudos Repetir": lista dos exames marcados para repetição.

**Campo novo identificado:** cada exame carrega um flag de **Marcapasso**
(Sim/Não) — campo clínico relevante que não estava registrado ainda.

### Perguntas em aberto (decidir mais adiante)

- [ ] Dá para migrar/puxar o histórico de exames do site atual para o novo?
      Sistema atual: **LaudoSyn** (app.laudosyn.com.br), desenvolvido pela
      **Infinnitum Tecnologia** (Curitiba, desde 2006).
      Contato: contato@infinnitum.com.br · (41) 9 9648-1623
      → Perguntar diretamente: exportação em CSV/JSON, ou API disponível?
- [ ] Formato de entrega do `.dat` do Holter — se precisa de visualizador
      embutido ou só download
- [ ] Bird ID tem API/integração para assinar programaticamente, ou é um
      processo manual (assinar fora e depois subir o PDF já assinado)?
      **Detalhe técnico de referência (amigo cardiologista, 03/07/2026):**
      o padrão correto de assinatura digital em PDF no Brasil é **PAdES**
      (PDF Advanced Electronic Signatures) com **cadeia ICP-Brasil** — não
      é só "colar uma imagem de assinatura", é uma assinatura
      criptográfica com validade jurídica de verdade. Confirmar se o
      Bird ID gera assinatura nesse formato.
- [ ] QR Code: gerar em cima do link de download do exame, ou embutir o PDF
      direto no QR? (limite de dados de um QR pode não comportar o PDF inteiro
      — provavelmente o caminho é link)
- [ ] **Área de exames laudados** — todos os exames já laudados listados
      juntos, em ordem cronológica (mais recente primeiro), numa área
      separada. Caixa de busca simples por nome do paciente, no topo da
      lista.
- [ ] **Botões "Enviar laudo" e "Repetir exame"** em todas as páginas de
      laudo (ECG, MAPA, Holter). Se "Repetir exame" for acionado, o exame
      **volta para o parceiro que enviou a solicitação** e fica pendente até
      que seja reajustado/reenviado por ele.
      → Pergunta em aberto: fica registrado algum motivo da repetição (campo
      de observação), ou é só um botão sem justificativa?
      (a dúvida sobre aviso ao parceiro já foi resolvida — vai ser por
      WhatsApp, ver seção de notificação acima)

### Método de validação da assinatura digital — referência do amigo
cardiologista (03/07/2026)

Quando chegar a hora de testar a assinatura digital de verdade, este é o
roteiro de validação em três etapas que o amigo de Mario usou:

1. **Assinar um PDF de teste no VPS** e conferir a assinatura **PAdES** +
   cadeia **ICP-Brasil** diretamente (verificação técnica).
2. **Validação oficial:** levar esse PDF ao site
   [validar.iti.gov.br](https://validar.iti.gov.br) — validador **oficial
   do governo brasileiro** para assinaturas digitais — para confirmar que
   a assinatura é reconhecida como válida.
3. **Teste final "de ponta a ponta":** pelo celular, direto no domínio da
   plataforma, laudar um ECG e um MAPA de teste, e conferir se o PDF final
   sai assinado, com timbre e fontes corretas, na hora.

Guardar este roteiro para quando a integração de assinatura estiver pronta
para testes.

### Lembrete de sempre

LGPD é requisito desde o início, não ajuste posterior (já registrado no
`site/CLAUDE.md`). Este projeto lida com dado de saúde de
pacientes de terceiros (parceiros) — atenção redobrada.

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

- Claude Code testado e funcionando em 03/07/2026, lendo corretamente os
  CLAUDE.md das subpastas.
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
