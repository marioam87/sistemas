/* ============================================================
   BACKUP / RESTAURAÇÃO — treinos_mario.html
   Módulo autocontido. Cole este bloco antes de </body>,
   dentro de uma tag <script>, ou salve como arquivo separado
   e inclua com <script src="backup-treinos.js"></script>.

   Não depende de nada do app. Só lê e escreve no localStorage.
   ============================================================ */

(function () {
  'use strict';

  // ---------- CONFIGURAÇÃO ----------
  // Deixe null para exportar TODAS as chaves do localStorage.
  // Ou liste os prefixos das suas chaves, ex: ['treinos_', 'calendario_']
  const PREFIXOS = null;

  const APP_NOME = 'treinos-mario';
  const FORMATO_VERSAO = 1;

  // ---------- COLETA ----------
  function chavesRelevantes() {
    const todas = Object.keys(localStorage);
    if (!PREFIXOS) return todas;
    return todas.filter(k => PREFIXOS.some(p => k.startsWith(p)));
  }

  function montarBackup() {
    const dados = {};
    for (const k of chavesRelevantes()) {
      dados[k] = localStorage.getItem(k);
    }
    return {
      app: APP_NOME,
      formato: FORMATO_VERSAO,
      geradoEm: new Date().toISOString(),
      dispositivo: navigator.userAgent,
      totalChaves: Object.keys(dados).length,
      dados
    };
  }

  function nomeArquivo() {
    const d = new Date();
    const p = n => String(n).padStart(2, '0');
    return `treinos-backup-${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}.json`;
  }

  // ---------- EXPORTAR ----------
  async function exportar() {
    const backup = montarBackup();

    if (backup.totalChaves === 0) {
      avisar('Nada para exportar — não há dados salvos neste dispositivo.');
      return;
    }

    const texto = JSON.stringify(backup, null, 2);
    const arquivo = new File([texto], nomeArquivo(), { type: 'application/json' });

    // Caminho 1: Web Share API — é o que funciona bem no iOS em modo standalone.
    // Abre a folha de compartilhamento (Arquivos, iCloud Drive, Mail, WhatsApp...).
    if (navigator.canShare && navigator.canShare({ files: [arquivo] })) {
      try {
        await navigator.share({
          files: [arquivo],
          title: 'Backup dos treinos'
        });
        return;
      } catch (e) {
        if (e.name === 'AbortError') return; // usuário cancelou, tudo bem
        // qualquer outro erro: cai para o próximo caminho
      }
    }

    // Caminho 2: download direto (desktop e Safari fora do modo standalone)
    try {
      const url = URL.createObjectURL(arquivo);
      const a = document.createElement('a');
      a.href = url;
      a.download = nomeArquivo();
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
      return;
    } catch (e) {
      // cai para o último caminho
    }

    // Caminho 3: mostra o JSON para copiar à mão
    mostrarTextoParaCopiar(texto);
  }

  // ---------- IMPORTAR ----------
  function importar() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'application/json,.json';
    input.style.display = 'none';
    document.body.appendChild(input);

    input.addEventListener('change', () => {
      const arquivo = input.files && input.files[0];
      input.remove();
      if (!arquivo) return;

      const leitor = new FileReader();
      leitor.onload = () => aplicarBackup(String(leitor.result));
      leitor.onerror = () => avisar('Não foi possível ler o arquivo. Tente novamente.');
      leitor.readAsText(arquivo);
    });

    input.click();
  }

  function aplicarBackup(texto) {
    let backup;
    try {
      backup = JSON.parse(texto);
    } catch (e) {
      avisar('Arquivo inválido: não é um JSON legível.');
      return;
    }

    if (!backup || typeof backup.dados !== 'object' || backup.dados === null) {
      avisar('Arquivo inválido: não parece ser um backup deste app.');
      return;
    }

    if (backup.app && backup.app !== APP_NOME) {
      const segue = confirm(
        `Este backup foi gerado por outro app ("${backup.app}").\n\nRestaurar mesmo assim?`
      );
      if (!segue) return;
    }

    const chaves = Object.keys(backup.dados);
    const data = backup.geradoEm
      ? new Date(backup.geradoEm).toLocaleString('pt-BR')
      : 'data desconhecida';

    const confirma = confirm(
      `Restaurar backup de ${data}?\n\n` +
      `${chaves.length} ${chaves.length === 1 ? 'registro' : 'registros'} serão gravados.\n` +
      `Os dados atuais deste dispositivo serão substituídos.\n\n` +
      `Uma cópia de segurança do estado atual fica guardada automaticamente.`
    );
    if (!confirma) return;

    // Rede de segurança: guarda o estado atual antes de sobrescrever.
    try {
      sessionStorage.setItem('__backup_pre_restauracao', JSON.stringify(montarBackup()));
    } catch (e) {
      // sessionStorage cheio ou indisponível — segue mesmo assim
    }

    let gravadas = 0;
    for (const k of chaves) {
      const v = backup.dados[k];
      if (typeof v === 'string') {
        try {
          localStorage.setItem(k, v);
          gravadas++;
        } catch (e) {
          avisar(`Armazenamento cheio. ${gravadas} registros foram gravados antes da falha.`);
          return;
        }
      }
    }

    alert(`Backup restaurado: ${gravadas} registros. A página vai recarregar.`);
    location.reload();
  }

  // ---------- AUXILIARES ----------
  function avisar(msg) {
    alert(msg);
  }

  function mostrarTextoParaCopiar(texto) {
    const fundo = document.createElement('div');
    fundo.style.cssText =
      'position:fixed;inset:0;background:rgba(0,0,0,.75);z-index:99999;' +
      'display:flex;flex-direction:column;gap:12px;padding:20px;' +
      'padding-top:calc(20px + env(safe-area-inset-top));' +
      'padding-bottom:calc(20px + env(safe-area-inset-bottom));';

    const titulo = document.createElement('p');
    titulo.textContent = 'Copie este texto e salve em um arquivo .json';
    titulo.style.cssText = 'color:#fff;margin:0;font:600 15px/1.4 system-ui,sans-serif;';

    const area = document.createElement('textarea');
    area.value = texto;
    area.readOnly = true;
    area.style.cssText =
      'flex:1;width:100%;box-sizing:border-box;border-radius:10px;border:0;' +
      'padding:12px;font:12px/1.4 ui-monospace,monospace;resize:none;';

    const fechar = document.createElement('button');
    fechar.textContent = 'Fechar';
    fechar.style.cssText =
      'padding:14px;border:0;border-radius:10px;background:#fff;' +
      'font:600 15px system-ui,sans-serif;cursor:pointer;';
    fechar.onclick = () => fundo.remove();

    fundo.append(titulo, area, fechar);
    document.body.appendChild(fundo);
    area.focus();
    area.select();
  }

  // ---------- API PÚBLICA ----------
  // Ligue seus botões a estas funções:
  //   <button onclick="Backup.exportar()">Exportar backup</button>
  //   <button onclick="Backup.importar()">Restaurar backup</button>
  window.Backup = {
    exportar,
    importar,
    // Útil no console: Backup.inspecionar() mostra o que seria exportado
    inspecionar: () => montarBackup()
  };
})();
