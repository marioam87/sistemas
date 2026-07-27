// Service worker do "Atividade Física" — cacheia o essencial (o próprio
// app) pra abrir mesmo sem sinal na academia. NÃO cacheia links do YouTube
// (não dá — precisa de rede) nem nada externo além das fontes do Google.
//
// IMPORTANTE: sempre que fizer deploy de uma mudança relevante no
// index.html, aumente CACHE_VERSION aqui (mesmo padrão do APP_VERSION lá no
// index.html). Sem isso, o service worker pode continuar servindo a versão
// antiga em cache pro usuário, mesmo depois do git push.
const CACHE_VERSION = 'v2026-07-27';
const CACHE_NAME = 'atividade-fisica-' + CACHE_VERSION;

const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))
      )
    )
  );
  self.clients.claim();
});

// Estratégia: network-first pro index.html (pra sempre tentar pegar a versão
// mais nova quando há sinal), caindo pro cache quando offline. Cache-first
// pros outros arquivos do app shell (mudam raramente).
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return; // não mexe em fontes externas (Google Fonts, YouTube etc.)

  const isAppShellPage = event.request.mode === 'navigate' || url.pathname.endsWith('index.html');

  if (isAppShellPage) {
    event.respondWith(
      fetch(event.request)
        .then((resp) => {
          const clone = resp.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          return resp;
        })
        .catch(() => caches.match(event.request).then((r) => r || caches.match('./index.html')))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
