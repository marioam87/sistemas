# PROJETO.md — Roteiro de Implementação do Site

Lista viva, organizada por **ordem de construção** (o que bloqueia o quê).
Sem prazo fixo — revisitar quando fizer sentido, mas seguir a ordem das
fases evita construir algo que depende de decisão ainda não tomada.

**Como usar este arquivo com o Claude Code:** cada fase tem uma lista de
tarefas. Ao pedir para trabalhar "na próxima etapa", o Claude Code deve
seguir a ordem das fases e marcar os itens concluídos (`- [ ]` → `- [x]`)
diretamente aqui.

---

## 0. Pessoas envolvidas (glossário)

- **Mario** — o próprio, cardiologista, dono da MP Serviços Médicos.
  **Administrador** e **Médico** (laudo ECG e MAPA) no site.
- **Léo** — amigo cardiologista. **Não é usuário do site de Mario** — está
  construindo sua própria plataforma de laudos em paralelo, e manda ideias/
  soluções que já funcionam no sistema dele. Suas referências técnicas
  (WhatsApp Business Platform, geração de PDF, PAdES/ICP-Brasil) estão
  registradas neste documento como "referência do amigo cardiologista".
- **Gi (Dra. Gislaini)** — **Médica**, laudo apenas exames de Holter.

---

## 1. Forma de trabalho (Claude Code)

**Contexto:** sem pressa. O sistema atual (LaudoSyn) atende a demanda hoje —
este projeto é para ganhar personalização e se livrar da mensalidade, não
uma urgência operacional.

**Como desenvolver:**
- Tudo feito localmente no Mac de Mario, com o Claude Code logado pela
  assinatura **Pro** (não precisa de API Console/cobrança por token).
- Modelo padrão: **Sonnet**. Trocar para **Opus** só em tarefas pontuais de
  raciocínio pesado (arquitetura, bugs difíceis), via `/model`.
- Se o ritmo de trabalho esbarrar nos limites de uso do Pro com frequência,
  avaliar assinar o **Max temporariamente** só durante a fase mais pesada de
  construção — decisão ajustável mês a mês, não definitiva.
- Publicação no VPS Integrator feita a partir do Mac (comandos remotos via
  Claude Code), sem precisar logar o Claude Code dentro do próprio servidor.
- **Autenticação do Claude Code:** login normal da assinatura Pro/Max (o
  mesmo do claude.ai) — não a API Console (`console.anthropic.com`, cobrança
  por token, usada por terceiros para automação 24/7 dentro de servidor).

**Como fragmentar o trabalho:**
- Montar cada fase abaixo em **etapas bem definidas e testáveis**, pensadas
  para caber dentro das janelas de uso do Pro (5h corridas / limite
  semanal), minimizando gasto de tokens.
- Preferir muitas etapas pequenas e testáveis a poucas etapas grandes.
- Se o limite de uso acabar no meio de uma etapa, decidir na hora entre
  aguardar o reset ou comprar créditos extra — sem pressão para decidir isso
  de antemão.

**Status:** Claude Code já instalado, autenticado e testado com sucesso
(03/07/2026), lendo corretamente os `CLAUDE.md` das subpastas em
`~/sistemas`.

**Subagents especializados (recomendado para as áreas críticas do
projeto):** criar revisores dedicados que rodam automaticamente sobre
código das áreas mais sensíveis, em vez de depender só de revisão manual:
- [ ] `security-reviewer` → roda em cima de qualquer código que toque
  assinatura PAdES/Bird ID ou dado de paciente (ver Fase 3).
- [ ] `pdf-reviewer` → valida geração/concatenação de PDF antes de dar como
  pronto (ver Fases 2.1, 2.2 e 2.3 — montagem do PDF final por
  concatenação).

**Git worktrees (para trabalho em paralelo):** se em algum momento for
preciso trabalhar em duas frentes do site ao mesmo tempo (ex.: módulo
Administrador — Fase 4 — e módulo Parceiros — Fase 5 — simultaneamente),
usar Git worktrees para rodar duas sessões do Claude Code sem uma pisar na
outra (cada worktree é uma pasta própria, mesma repo, branches diferentes).

---

## Roteiro de construção

### Fase 0 — Decisões bloqueantes (antes de codar)

Essas decisões travam parte do trabalho de outras fases (nome fantasia trava
logo/domínio/etiqueta; ver dependências indicadas).

- [ ] **Escolher o nome fantasia.** Decidido: o site, a logomarca e a
  comunicação dos laudos vão usar um **nome fantasia**, diferente da razão
  social "MP Serviços Médicos". A empresa continua "MP Serviços Médicos S/S"
  no CNPJ/documentos oficiais — só o nome voltado ao público muda.
  → Nota técnica: para usar oficialmente vinculado ao CNPJ (recomendado,
  evita alguém registrar o mesmo nome depois), formalizar como nome
  fantasia na Junta Comercial — passo simples, normalmente resolvido pelo
  contador.
  *(bloqueia: logo, domínio, etiqueta do laudo)*
- [ ] **Criar o logo** para o nome fantasia. Vai ser usado na etiqueta/
  cabeçalho dos laudos (hoje a etiqueta usa só texto — CNPJ, endereço,
  contato — sem marca visual).
  *(depende de: nome fantasia)*
- [ ] **Comprar o domínio.** As opções sugeridas anteriormente (baseadas em
  "MP Serviços Médicos") ficam **em suspenso** até o nome fantasia ser
  definido — o domínio deve seguir o nome fantasia, não a razão social.
  `mpservicosmedicos.com.br` segue confirmado como disponível (verificado
  em 03/07/2026), mas provavelmente não será o escolhido.
  *(depende de: nome fantasia)*
- [ ] **Montar o cronograma em etapas** quando a construção começar de
  verdade — ver "Forma de trabalho" acima para os critérios (etapas
  pequenas, testáveis, dentro das janelas de uso do Pro).

---

### Fase 1 — Fundação

**Visão geral do site (contexto):** hoje Mario paga um sistema de terceiros
(LaudoSyn) que faz esse fluxo. A ideia é construir um substituto próprio, em
`~/sistemas/site/`. O site não é uma coisa só — são três sistemas com login
e acesso próprios (Administrador, Parceiros, Laudos — ver Fases 3, 4 e 2),
compartilhando a mesma tela de entrada.

**Tipos de exame:**
- Escopo inicial: **ECG**, **MAPA**, **Holter**
- Futuros, sem data definida (ver seção 2.4 dentro da Fase 2): **ECOTT** e
  **DCV**. Modelos de referência já guardados na gaveta (sem dado de
  paciente):
  - `site/referencias/ecott/ecott - modelo laudo.docx`
  - `site/referencias/dcv/dcv - modelo laudo.pdf`

**Como o sistema atual (LaudoSyn) funciona hoje** (referência a
replicar/substituir):
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
- [ ] Setup **VPS Integrator** — disponibilidade 24h sem depender de
  computador ligado, sistema operacional **Linux**.
- [ ] Configurar **backup automático dos exames na nuvem (AWS)**, como já é
  feito hoje.

#### 1.1 Autenticação e login (compartilhado pelos três sistemas)

- [ ] Implementar tela de login única, que direciona para o sistema certo
  conforme usuário/senha.

**Layout da tela, de cima para baixo:**
1. Logo da empresa (depende do nome fantasia — Fase 0)
2. Campo de texto: **Usuário**
3. Campo de texto: **Senha**
4. Botão **Entrar**
5. Botão **Esqueci a senha**

**Regra de senha:** 6 a 8 caracteres, com letras e números, pelo menos
1 letra maiúscula e 1 caractere especial.

**Fluxo de "Esqueci a senha":** a senha nunca é armazenada de forma legível
nem visível para o administrador (senha guardada de forma criptografada e
irreversível — "hash"). Em vez do administrador "ver a senha nova":
- O usuário esquece a senha → recebe um link/código para **criar uma senha
  nova**, sem ninguém (nem o admin) ver qual ele escolheu.
- Se o administrador precisar destravar alguém manualmente, ele **atribui
  uma senha temporária** (não vê a senha que a pessoa escolheria) — e ela
  troca no primeiro acesso seguinte.

**Contas previstas no lançamento (login único, roteado por perfil):**
| Sistema | Quem | Nº de contas |
|---|---|---|
| Administrador | Mario | 1 |
| Laudos | Mario + Gi (cada um com login próprio) | 2 |
| Parceiros | Idealprev, Policlínica Sítio Cercado, Policlínica Tatuquara, Rio Azul (uma conta por clínica) | 4 |

---

### Fase 2 — Sistema Laudos (núcleo do produto)

**Quem usa:** Mario e Gi, cada um com login próprio — mas **cada um só
recebe e laudo um tipo de exame:**
- **Gi:** apenas **Holter**
- **Mario:** **ECG** e **MAPA**

- [ ] Implementar fila de exames a laudar **filtrada por usuário logado**
  (Gi não vê ECG/MAPA na fila dela; Mario não vê Holter na dele).
- [ ] Implementar notificação de pedido novo (entrada) por WhatsApp — ver
  arquitetura completa na Fase 7:
  - **ECG ou MAPA** → avisa **Mario**, no número **+55 41 99908-4472**
  - **Holter** → avisa **Gi**, no número **+55 41 99995-1121**
- [ ] Botões em toda página de laudo (ECG, MAPA, Holter): **"Enviar laudo"**
  e **"Repetir exame"** (este último devolve o exame ao parceiro — ver Fase
  5). **Decidido:** ao clicar em "Repetir exame", fica registrado o motivo
  da repetição — não é só o botão sem justificativa. Implementar campo de
  observação/motivo junto ao botão.
- [ ] Área de exames laudados: lista cronológica (mais recente primeiro),
  numa área separada, com caixa de busca simples por nome do paciente.

**Referência do sistema atual (screenshots, não é para copiar o visual):**
- Tela "Laudar" (fila de trabalho): sistema atual divide em "Dentro/Fora do
  horário de trabalho" — **não será replicado** (ver Fase 8, simplificações
  decididas). Fica só como fila única.
- Tela "Laudos Finalizados": mesma lista do parceiro, com ações extras de
  editar/excluir que o parceiro não tem.
- Tela "Laudos Repetir": lista dos exames marcados para repetição.

#### 2.1 MAPA — fluxo do laudo

> Usar o subagent `pdf-reviewer` (ver "Forma de trabalho") para validar a
> montagem/concatenação do PDF antes de dar a etapa como pronta.

- [ ] Implementar montagem do PDF final por concatenação:
```
Pág 1:    Etiqueta da empresa + identificação do paciente + QR code
Pág 2-3:  Laudo em PDF (inicia com o NOME DO EXAME por extenso, seguido
          do texto do laudo médico). Carimbo + assinatura digital
          SOBREPOSTOS no rodapé da última página (mesma técnica que já
          centraliza o carimbo hoje no gerar_laudo_v7.js — só acrescenta
          a assinatura ao lado)
Pág 4+:   Exame completo bruto (arquivo original do aparelho — Contec
          ou Micromed)
```
- **Nome do exame no cabeçalho:** MONITORIZAÇÃO AMBULATORIAL DA PRESSÃO
  ARTERIAL (por extenso, não a sigla).
- [ ] Ajustar `gerar_laudo_v7.js` (e equivalentes) para entregar o PDF já
  iniciando com o nome do exame, antes do corpo do laudo — esse é o arquivo
  que Mario vai anexar no site como "laudo bruto".
- Contexto do fluxo atual (LaudoSyn) sendo substituído: hoje o sistema gera
  a etiqueta+identificação+QR automaticamente, e Mario cola o texto do
  laudo (feito no Word) numa área do site, perdendo a formatação (tabelas,
  destaques) do PDF original. O fluxo novo resolve isso anexando o PDF já
  formatado, em vez de colar texto.
- Ideia opcional (não essencial): marcadores de navegação (bookmarks) no
  PDF final, para pular entre identificação/laudo/exame bruto em arquivos
  longos.

#### 2.2 Holter — fluxo do laudo (diferente do MAPA)

- [ ] Implementar montagem do PDF final:
```
Pág 1:    Etiqueta da empresa + identificação do paciente + QR code
          (igual ao MAPA)
Pág 2:    Texto do laudo — Gi escreve no Word e COLA na caixa de texto
          livre do site. Termina com CARIMBO CENTRALIZADO (sem
          assinatura digital ao lado).
Pág 3+:   PDF enviado pelo campo de upload — Gi baixa o .dat do Holter,
          monta ELA MESMA um PDF com as informações do exame e exemplos
          de trechos de traçado alterados, e sobe esse PDF pronto. O
          texto da página 2 é lançado JUNTO com os gráficos desse PDF
          (não é o .dat bruto que sobe, é o PDF já montado por ela).
```
- **Nome do exame no cabeçalho:** HOLTER 24h.
- **Diferenças importantes em relação ao MAPA:**
  - Sem autenticação/assinatura digital por enquanto (decisão inicial, pode
    mudar no futuro).
  - O laudo é texto colado na caixa livre (escrito primeiro no Word), não
    um PDF anexado.
  - Quem laudo é a Gi, não o Mario — o carimbo usado aqui é o dela, **não**
    o `carimbo.png` de Mario já guardado em `clinica/mapa/assets/`.
- [ ] **Pendência:** Mario vai enviar o arquivo do carimbo da Gi. Sugestão
  de local: criar `clinica/holter/` na gaveta quando for organizar isso.
- **Decidido:** o `.dat` do Holter no site é **só download** — sem
  visualizador embutido.

#### 2.3 ECG (Eletrocardiograma) — layout e arquitetura

**Novidade em relação ao sistema atual:** laudar ECG diretamente no site
(hoje isso não existe no LaudoSyn).

- **Nome do exame no cabeçalho:** ELETROCARDIOGRAMA.
- [ ] Implementar layout da tela de laudo, dividida em duas colunas:
  - **Esquerda:** o PDF do eletro aberto, com opção de ampliar (zoom).
  - **Direita:** área de confecção do laudo — → Pergunta em aberto: Mario
    ainda vai detalhar como funciona essa parte.
- [ ] Implementar geração do PDF do laudo seguindo o padrão **dados
  estruturados (JSON) → template (arquivo separado, com variáveis) →
  renderização (script preenche o template) → PDF final** — o mesmo padrão
  que já funciona no MAPA (`gerar_laudo_v7.js`: docx + LibreOffice). Não
  precisa trocar de tecnologia, a menos que o layout exija algo que o Word
  não resolva bem.
  - Bibliotecas alternativas, caso o padrão atual não seja suficiente:
    WeasyPrint (HTML+CSS→PDF, flexível), ReportLab (controle
    pixel-perfeito, mais trabalhoso), wkhtmltopdf (projeto parado, evitar).
  - Boas práticas a manter: template sempre em arquivo separado da lógica
    de geração, nomes de campo documentados (como no
    `PROMPT_NOVO_LAUDO.md` do MAPA), tudo versionado na gaveta. Negrito
    condicional (valor fora da referência) já é convenção estabelecida em
    `clinica/labs/CLAUDE.md` — reaplicar a mesma lógica no laudo de ECG.

**Nota importante — descartado:** medição automática de intervalos de ECG a
partir de imagem/PDF do traçado (FC, RR, PR, QRS, ÂQRS, QT, QTc, ST) foi
avaliada e **descartada** — não é confiável, exige calibração
pixel↔tempo/amplitude e detecção exata de ondas que não dá pra fazer com
segurança clínica a partir de imagem estática. Se revisitado no futuro, só
via algoritmo de processamento de sinal sobre o dado digital bruto do
aparelho (nunca leitura visual de imagem), com validação de especialista.

#### 2.4 Futuro: Ecocardiograma (ECOTT) e Doppler de Carótidas (DCV)

Sem data definida — entram na fila depois do escopo inicial (ECG, MAPA,
Holter). Modelos de referência de estrutura já guardados (ver Fase 1).

---

### Fase 3 — Assinatura digital, carimbo e QR Code

*(transversal — usada dentro dos fluxos de laudo da Fase 2, mas com
integração técnica própria)*

> ⚠️ Área crítica — usar o subagent `security-reviewer` (ver "Forma de
> trabalho") em todo código desta fase antes de considerar pronto.

- [ ] Integrar **Bird ID** (já usado por Mario hoje) ao fluxo novo, além do
  carimbo visual já existente (`clinica/mapa/assets/carimbo.png`) — a
  assinatura digital é camada extra, com validade jurídica, diferente do
  carimbo (que é só imagem).

**Padrão técnico de referência — amigo cardiologista:** o padrão correto de
assinatura digital em PDF no Brasil é **PAdES** (PDF Advanced Electronic
Signatures) com **cadeia ICP-Brasil** — assinatura criptográfica com
validade jurídica real, não "colar uma imagem de assinatura".
→ **Pergunta em aberto:** o Bird ID tem API/integração para assinar
programaticamente, ou é processo manual (assinar fora e subir o PDF já
assinado)? Confirmar se gera assinatura nesse formato.

- [ ] Posicionar carimbo + assinatura digital sobrepostos, lado a lado, no
  rodapé da última página do laudo (ver Fase 2.1). Não se aplica ao Holter
  por enquanto (ver Fase 2.2).

**Roteiro de validação** (guardar para quando a integração estiver pronta
para testes):
1. [ ] Assinar um PDF de teste no VPS e conferir a assinatura PAdES +
   cadeia ICP-Brasil diretamente (verificação técnica).
2. [ ] Validação oficial: levar o PDF a
   [validar.iti.gov.br](https://validar.iti.gov.br) — validador oficial do
   governo brasileiro.
3. [ ] Teste final de ponta a ponta: pelo celular, direto no domínio do
   site, laudar um ECG e um MAPA de teste, e conferir se o PDF final sai
   assinado, com timbre e fontes corretas, na hora.

- [ ] Implementar **QR Code** por exame laudado — o paciente escaneia e o
  PDF é salvo automaticamente no celular/computador dele.
  → **Pergunta em aberto:** o QR aponta para um link de download, ou tenta
  embutir o PDF direto? (limite de dados de um QR provavelmente não
  comporta um PDF inteiro — o caminho mais realista é link).

---

### Fase 4 — Sistema Administrador

Só Mario tem acesso.

- [ ] Cadastro de novos parceiros
- [ ] Ajuste de horário de trabalho dos colaboradores (ex.: Gi)
- [ ] Fluxo de caixa dos exames: feito / pago / pagamento pendente
- [ ] Informações de acesso da AWS (Amazon, backup)
- [ ] Seção **"Termos"** (ver Fase 6 — mesmos documentos também aparecem no
  Sistema Parceiros)

~~Ajuste de horários de envio/recebimento de exames~~ — descartado, ver
Fase 8 ("Simplificações decididas").

**Referência do sistema atual (screenshots, não é para copiar o visual):**
Dashboard com cards (exames não laudados / laudados por tipo em gráfico de
rosca — ECG, Holter, MAPA / exames repetidos, com filtro de período), e
menus: Cadastros, Configurações, Financeiro, Modelos, Relatórios, Sistema.

---

### Fase 5 — Sistema Parceiros

**Quem usa:** as clínicas que enviam exames para laudo — **Idealprev**,
**Policlínica Sítio Cercado**, **Policlínica Tatuquara**, **Rio Azul**. Cada
parceiro só enxerga os próprios exames; não vê nada dos outros parceiros
nem dos outros sistemas.

- [ ] Formulário de envio de pedido de exame (upload). **Decidido:** a área
  de envio tem **dois botões separados**:
  - um para envio do **PDF do exame ou arquivo `.dat`** (o exame em si)
  - outro para **envio de arquivos em geral** (ex.: o "relatório de
    atividades" da pasta Termos — ver Fase 6)
- [ ] Notificação quando o laudo fica pronto (ver Fase 7 — WhatsApp)
- [ ] Download do exame já laudado
- [ ] Seção **"Termos"** (ver Fase 6)
- [ ] Implementar menu do Sistema Parceiros, nesta ordem: **Laudar** ·
  **Laudos Recebidos** · **Exames a Repetir** · **Termos**

**Botão "Repetir exame":** se um médico aciona esse botão (Fase 2), o
exame volta para o parceiro que enviou a solicitação, e fica pendente até
ser reajustado/reenviado por ele.

**Referência do sistema atual (screenshots, não é para copiar o visual) —
tela "Pedidos" (envio de exame):** campos Exame, Convênio, Nome do
Paciente, CPF, Data de Nascimento, Data/Hora de instalação do exame,
**Marcapasso** (Sim/Não — campo clínico relevante identificado), **Tipo do
Pedido** (ex.: "Normal" — outros tipos a confirmar, ex.: Urgente?), upload
do arquivo do exame, upload de anotações (com opção "cliente não preencheu
as anotações").

**Referência do sistema atual — tela "Laudos Finalizados":** lista para
download. O sistema atual **projeta** um botão de WhatsApp ao lado do
e-mail, mas **não é funcional** — só visual, não dispara nada de fato. No
site novo, WhatsApp real substitui o e-mail (ver Fase 7).

---

### Fase 6 — Seção "Termos" (Administrador + Parceiros)

Ambos os sistemas terão uma seção chamada **"Termos"**, exibindo os
arquivos já preparados em `site/termos/`:
- `HOLTER - orientações.docx`
- `MAPA - orientações.docx`
- `relatório de atividades.docx`
- `termo de autorização dos dados.docx`
- `termo de responsabilidade.docx`

São modelos/formulários genéricos (sem dado de paciente).

**Decidido:**
- [ ] "Termos" aparece nos **dois sistemas** (Administrador e Parceiros),
  só para **download** dos arquivos.
- [ ] **No Sistema Parceiros:** entra como item de menu, na ordem: Laudar ·
  Laudos Recebidos · Exames a Repetir · **Termos** (ver Fase 5).
- [ ] **No Sistema Administrador:** entra como **último item do menu**.
- [ ] Na área de envio de exames do parceiro, o "relatório de atividades"
  (um dos 5 arquivos de Termos) tem seu próprio botão de upload, separado
  do botão de envio do exame/`.dat` (ver Fase 5).

---

### Fase 7 — Notificações via WhatsApp

**Duas direções de notificação, ambas por WhatsApp (não e-mail):**

1. **Saída** — parceiro avisado quando o laudo fica pronto (ver Fase 5).
   Combinar com cada clínica um número de WhatsApp de destino. Isso muda o
   comportamento do sistema atual, que usa e-mail (com botão de WhatsApp
   só visual, não funcional).
2. **Entrada** — médico avisado quando chega um pedido novo (ver Fase 2):
   ECG/MAPA avisam Mario (+55 41 99908-4472), Holter avisa Gi
   (+55 41 99995-1121).

**Arquitetura técnica — referência do amigo cardiologista:** usar a
**WhatsApp Business Platform oficial da Meta** (não bibliotecas
não-oficiais). Componentes necessários:
- [ ] Conta Meta Business (Business Manager)
- [ ] Um número de telefone verificado — o número ÚNICO que Mario opera, de
  onde partem todas as notificações (cada clínica só precisa de um número
  para RECEBER, não é "um número por clínica" do lado de quem envia)
- [ ] Token de acesso (autenticação das chamadas à API)
- [ ] Webhook — endereço do próprio sistema que a Meta chama quando alguém
  responde uma mensagem

**Limitações a considerar no desenho:**
- **Janela de 24h:** só é possível mandar mensagem de texto livre a quem
  escreveu nas últimas 24h; fora disso, só com template pré-aprovado.
- **Templates de mensagem:** iniciar uma notificação (ex.: "seu laudo está
  pronto", "novo pedido recebido") exige um modelo pré-aprovado pela Meta.
- **Aprovação de templates:** cada modelo passa por revisão da Meta antes
  de poder ser usado (horas a poucos dias) — [ ] submeter templates com
  antecedência.

---

### Fase 8 — Simplificações decididas (escopo negativo — não implementar)

- **Sem limite de horário de envio/recebimento de exames.** O sistema atual
  tem esse controle no painel administrador (divisão "dentro/fora do
  horário de trabalho"); decidido não replicar essa limitação no site novo.
- **E-mail substituído por WhatsApp** em toda notificação (ver Fase 7).

---

### Fase 9 — Migração e organização (específico do site)

- [ ] **Migração do histórico do LaudoSyn:** dá para migrar/puxar o
  histórico de exames? Sistema atual desenvolvido pela **Infinnitum
  Tecnologia** (Curitiba, desde 2006). Contato: contato@infinnitum.com.br ·
  (41) 9 9648-1623. Perguntar diretamente: exportação em CSV/JSON, ou API
  disponível?
- [ ] **Backup na nuvem (GitHub privado)** do conteúdo da pasta do site
  (livre de dados de paciente) — backup automático + histórico na nuvem,
  além do pendrive. Fazer quando avançar na construção do site.

---

## Perguntas em aberto (consolidado)

- [ ] Dá para migrar/puxar o histórico de exames do LaudoSyn? (Fase 9)
- [ ] Bird ID tem API para assinar programaticamente, ou é processo manual?
  Confirma formato PAdES/ICP-Brasil? (Fase 3)
- [ ] QR Code: link de download, ou tentar embutir o PDF? (Fase 3)
- [ ] Layout da confecção do laudo de ECG (lado direito da tela) — Mario
  vai detalhar (Fase 2.3)
- [ ] Prints da organização atual dos "3 sites" — aguardando envio, para
  confirmar se equivalem aos 3 sistemas já mapeados aqui

**Respondidas recentemente:**
- [x] Formato de entrega do `.dat` do Holter → só download (Fase 2.2)
- [x] Botão "Repetir exame" → registra motivo + botão (Fase 2)
- [x] Seção "Termos" → aparece em Admin (último item do menu) e Parceiros
  (item do menu), só download; upload de arquivos gerais tem botão próprio
  na área de envio (Fase 5 e 6)
