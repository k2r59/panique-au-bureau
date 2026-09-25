// Keep the Godot drawing buffer stable while the software keyboard animates.
(() => {
  const canvas = document.getElementById('canvas');
  const viewport = window.visualViewport;
  let stableHeight = Math.round(viewport?.height || innerHeight);
  let stableWidth = document.documentElement.clientWidth;
  let keyboardSession = false;
  let frame = 0;
  const done = document.createElement('button');
  done.id = 'keyboard-done';
  done.type = 'button';
  done.textContent = 'Terminé ✓';
  done.setAttribute('aria-label', 'Fermer le clavier');
  done.hidden = true;
  document.body.append(done);
  let dismissing = false;
  function dismiss() {
    if (dismissing) return;
    dismissing = true;
    if (isInput(document.activeElement)) document.activeElement.blur();
    done.hidden = true;
    window.paniqueDismissKeyboard?.();
    dismissing = false;
    schedule();
  }
  done.addEventListener('pointerdown', event => event.preventDefault());
  done.addEventListener('click', dismiss);
  document.addEventListener('keydown', event => {
    if (isInput(event.target) && (event.key === 'Enter' || event.key === 'Escape') && !event.isComposing) {
      event.preventDefault(); event.stopImmediatePropagation(); dismiss();
    }
  }, true);
  const isInput = element => element && /^(INPUT|TEXTAREA)$/.test(element.tagName);
  function resize() {
    frame = 0;
    const width = Math.min(768, document.documentElement.clientWidth);
    const visibleHeight = Math.round(viewport?.height || innerHeight);
    const rotated = Math.abs(document.documentElement.clientWidth - stableWidth) > 80;
    if (rotated) { keyboardSession = false; stableWidth = document.documentElement.clientWidth; }
    // Retain the baseline until the keyboard has fully retracted, even after blur.
    if (keyboardSession && !isInput(document.activeElement) && visibleHeight >= stableHeight - 60) keyboardSession = false;
    if (!keyboardSession) stableHeight = visibleHeight;
    const height = keyboardSession ? stableHeight : visibleHeight;
    const scale = Math.min(width / 390, height / 844);
    const fieldBottom = (height - 844 * scale) / 2 + 510 * scale;
    const lift = keyboardSession ? Math.max(0, fieldBottom - visibleHeight + 24) : 0;
    canvas.style.top = `${(viewport?.offsetTop || 0) - lift}px`;
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    done.hidden = !isInput(document.activeElement) || !keyboardSession || stableHeight - visibleHeight < 100;
    done.style.top = `${(viewport?.offsetTop || 0) + visibleHeight - 48}px`;
    done.style.right = `${Math.max(12, (document.documentElement.clientWidth - width) / 2 + 12)}px`;
    const ratio = devicePixelRatio || 1;
    const w = Math.round(width * ratio), h = Math.round(height * ratio);
    if (canvas.width !== w) canvas.width = w;
    if (canvas.height !== h) canvas.height = h;
    document.documentElement.style.setProperty('--splash-scale', Math.min(width / 390, height / 844));
    const splash = document.getElementById('status');
    if (splash) splash.style.height = `${height}px`;
  }
  function schedule() { if (!frame) frame = requestAnimationFrame(resize); }
  document.addEventListener('focusin', event => {
    if (isInput(event.target)) {
      keyboardSession = true;
      // Resize only after Safari reports the keyboard geometry, not on focus.
    }
  });
  document.addEventListener('focusout', () => { done.hidden = true; schedule(); });
  window.addEventListener('resize', schedule);
  viewport?.addEventListener('resize', () => {
    if (isInput(document.activeElement) && stableHeight - viewport.height > 100) keyboardSession = true;
    schedule();
  });
  viewport?.addEventListener('scroll', schedule);
  resize();
})();
