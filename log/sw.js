// 웹 푸시: 앱·브라우저가 닫혀 있어도 OS가 이 워커를 깨워 알림을 띄운다 (보내는 쪽은 notify 함수)
self.addEventListener('activate', e => e.waitUntil(clients.claim()));

self.addEventListener('push', e => {
  const { title = '제주 가족 기록', body = '', post, cmt } = e.data?.json() ?? {};
  e.waitUntil(self.registration.showNotification(title, { body, icon: 'icon-192.png', data: { post, cmt } }));
});

// 알림을 누르면 그 글로 (댓글 알림이면 댓글을 펼쳐서). 열린 화면이 있으면 그 화면에 알려 바로 옮기고, 없으면 ?post= 로 새로 연다
// (열린 창을 navigate()로 옮기는 건 폰 브라우저에서 잘 안 먹어서 메시지로)
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const { post, cmt } = e.notification.data ?? {};
  const url = new URL(post ? `./?post=${post}${cmt ? '&cmt=1' : ''}` : './', self.registration.scope).href;
  e.waitUntil(clients.matchAll({ type: 'window', includeUncontrolled: true }).then(async ([win]) => {
    if (!win) return clients.openWindow(url);
    await win.focus();
    win.postMessage({ post, cmt });
  }));
});
