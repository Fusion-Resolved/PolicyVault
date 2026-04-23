const CACHE_NAME = 'policyvault-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // For Supabase API calls — network only (always fresh data)
  if (url.hostname.includes('supabase.co') || url.hostname.includes('supabase.io')) {
    event.respondWith(fetch(request));
    return;
  }

  // For Google Fonts and CDN resources — network first, cache fallback
  if (url.hostname.includes('googleapis.com') || url.hostname.includes('gstatic.com') || url.hostname.includes('unpkg.com') || url.hostname.includes('jsdelivr.net') || url.hostname.includes('babel')) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) =>
        cache.match(request).then((cached) => {
          const networkFetch = fetch(request).then((response) => {
            cache.put(request, response.clone());
            return response;
          });
          return cached || networkFetch;
        })
      )
    );
    return;
  }

  // For the app shell — cache first, network fallback
  event.respondWith(
    caches.match(request).then((cached) => {
      return cached || fetch(request).catch(() => caches.match('/index.html'));
    })
  );
});
