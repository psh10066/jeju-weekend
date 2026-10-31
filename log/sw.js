// 웹 푸시: 앱·브라우저가 닫혀 있어도 OS가 이 워커를 깨워 알림을 띄운다 (보내는 쪽은 notify 함수)
self.addEventListener('activate', e => e.waitUntil(clients.claim()));

self.addEventListener('push', e => {
  const { title = '제주 가족 기록', body = '', post } = e.data?.json() ?? {};
  e.waitUntil(self.registration.showNotification(title, { body, icon: 'icon-192.png', data: { post } }));
});

// 알림을 누르면 그 글(?post=)로. 열린 창이 있으면 그 창을 옮기고, 없으면 새로 연다
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const { post } = e.notification.data ?? {};
  const url = new URL(post ? `./?post=${post}` : './', self.registration.scope).href;
  e.waitUntil(clients.matchAll({ type: 'window' }).then(async ([win]) => {
    if (!win) return clients.openWindow(url);
    await win.focus();
    return win.navigate(url).catch(() => clients.openWindow(url));
  }));
});
