(() => {
  const key = 'panique.install.snooze';
  const standalone = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
  const ios = /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const android = /Android/i.test(navigator.userAgent);
  let deferred, ready = false, screen = 'home', shown = false, timer;
  const dismissed = () => { try { return Number(localStorage.getItem(key)) > Date.now(); } catch { return false; } };
  const snooze = () => { try { localStorage.setItem(key, String(Date.now() + 30 * 86400000)); } catch {} };
  const dialog = document.createElement('dialog');
  dialog.id = 'install-dialog';
  dialog.setAttribute('aria-labelledby', 'install-title');
  dialog.innerHTML = `<button id="install-close" aria-label="Fermer">×</button><img class="install-icon" src="index.icon.png" alt=""><p class="install-eyebrow">TON BUREAU HANTÉ, À PORTÉE DE MAIN</p><h2 id="install-title">Invite les fantômes<br>sur ton écran d’accueil</h2><p class="install-description">Retrouve le jeu d’un toucher, dans sa propre fenêtre. Gratuit, tout simplement.</p><ol class="install-steps" hidden></ol><button id="install-action">INSTALLER LE JEU</button><button id="install-later">Pas maintenant</button>`;
  document.body.append(dialog);
  const action = dialog.querySelector('#install-action');
  const steps = dialog.querySelector('.install-steps');
  const share = '<svg width="18" height="22" viewBox="0 0 24 28" fill="none" stroke="currentColor" stroke-width="2" aria-label="Partager"><path d="M12 18V2m-5 5 5-5 5 5M6 11H3v14h18V11h-3"/></svg>';
  function close() { snooze(); dialog.close(); document.getElementById('canvas')?.focus(); }
  dialog.querySelector('#install-close').onclick = close;
  dialog.querySelector('#install-later').onclick = close;
  dialog.addEventListener('cancel', () => { snooze(); });
  function schedule() {
    clearTimeout(timer);
    if (!ready || shown || standalone() || dismissed() || screen !== 'home' || !(ios || android)) return;
    timer = setTimeout(() => {
      if (screen !== 'home' || standalone() || document.hidden) return;
      if (!deferred) {
        steps.hidden = false;
        steps.innerHTML = ios
          ? `<li><span>Dans Safari, ouvre le menu puis <b>Partager</b> ${share}.</span></li><li><span>Choisis <b>Sur l’écran d’accueil</b>.</span></li><li><span>Garde <b>Ouvrir comme app web</b> si proposé, puis <b>Ajouter</b>.</span></li>`
          : '<li><span>Ouvre le menu <b>⋮</b> du navigateur.</span></li><li><span>Choisis <b>Installer l’application</b> ou <b>Ajouter à l’écran d’accueil</b>.</span></li>';
        action.textContent = 'C’EST COMPRIS';
      }
      shown = true;
      dialog.showModal();
      action.focus();
    }, 1800);
  }
  action.onclick = async () => {
    if (!deferred) { close(); return; }
    const prompt = deferred; deferred = null;
    dialog.close();
    try { await prompt.prompt(); await prompt.userChoice; } catch {} finally { snooze(); }
  };
  addEventListener('beforeinstallprompt', event => {
    event.preventDefault(); deferred = event;
    if (dialog.open) { steps.hidden = true; action.textContent = 'INSTALLER LE JEU'; }
    schedule();
  });
  addEventListener('appinstalled', () => { deferred = null; shown = true; snooze(); if (dialog.open) dialog.close(); });
  addEventListener('panique-ready', () => { ready = true; schedule(); });
  addEventListener('panique-screen', event => { screen = event.detail; if (screen !== 'home') { clearTimeout(timer); if (dialog.open) dialog.close(); } else schedule(); });
})();
