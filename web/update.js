// Check on launch/resume; never reload an active round or a profile being edited.
(() => {
  if (!('serviceWorker' in navigator)) return;
  let screen = 'loading', pending = false, reloading = false;
  let hadController = !!navigator.serviceWorker.controller;
  let lastCheck = 0;
  const apply = () => {
    if (!pending || reloading || screen !== 'home' || document.hidden) return;
    reloading = true;
    location.reload();
  };
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    pending = hadController;
    hadController = true;
    apply();
  });
  addEventListener('panique-screen', event => { screen = event.detail; apply(); });
  async function check() {
    if (document.hidden || Date.now() - lastCheck < 60000) return;
    try {
      const registration = await navigator.serviceWorker.getRegistration();
      if (registration) {
        lastCheck = Date.now();
        await registration.update();
      }
    } catch { /* Keep the installed version available offline. */ }
    apply();
  }
  addEventListener('pageshow', check);
  document.addEventListener('visibilitychange', check);
  navigator.serviceWorker.ready.then(check).catch(() => {});
})();
