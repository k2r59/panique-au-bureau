// Keep the Godot drawing buffer stable while the software keyboard animates.
(() => {
  const canvas = document.getElementById('canvas');
  const viewport = window.visualViewport;
  let stableHeight = Math.round(viewport?.height || innerHeight);
  let stableWidth = document.documentElement.clientWidth;
  let keyboardSession = false;
  let frame = 0;
  const isInput = element => element && /^(INPUT|TEXTAREA)$/.test(element.tagName);
  function resize() {
    frame = 0;
    const width = Math.min(768, document.documentElement.clientWidth);
    const visibleHeight = Math.round(viewport?.height || innerHeight);
    const rotated = Math.abs(document.documentElement.clientWidth - stableWidth) > 80;
    if (rotated) { keyboardSession = false; stableWidth = document.documentElement.clientWidth; }
    // Retain the baseline until the keyboard has fully retracted, even after blur.
    if (keyboardSession && visibleHeight >= stableHeight - 60) keyboardSession = false;
    if (!keyboardSession) stableHeight = visibleHeight;
    const height = keyboardSession ? stableHeight : visibleHeight;
    const scale = Math.min(width / 390, height / 844);
    const fieldBottom = (height - 844 * scale) / 2 + 510 * scale;
    const lift = keyboardSession ? Math.max(0, fieldBottom - visibleHeight + 24) : 0;
    canvas.style.top = `${(viewport?.offsetTop || 0) - lift}px`;
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
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
  document.addEventListener('focusout', schedule);
  window.addEventListener('resize', schedule);
  viewport?.addEventListener('resize', () => {
    if (isInput(document.activeElement) && stableHeight - viewport.height > 100) keyboardSession = true;
    schedule();
  });
  viewport?.addEventListener('scroll', schedule);
  resize();
})();
