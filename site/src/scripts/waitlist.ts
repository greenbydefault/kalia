/**
 * Das Formular ist sichtbar, sendet aber noch nichts (Rechtsträger und Mail-Absender offen).
 * Zum Anschließen: fetch an den Endpunkt statt der Meldung unten.
 */
export function initWaitlist() {
  const form = document.querySelector<HTMLFormElement>('[data-waitlist]');
  const status = document.querySelector<HTMLElement>('[data-waitlist-status]');
  const input = form?.querySelector<HTMLInputElement>('input[type="email"]');
  if (!form || !status || !input) return;

  const say = (text: string, state: 'info' | 'error') => {
    status.textContent = text;
    status.dataset.state = state;
    input.setAttribute('aria-invalid', String(state === 'error'));
  };

  input.addEventListener('input', () => {
    if (input.getAttribute('aria-invalid') === 'true') say('', 'info');
  });

  form.addEventListener('submit', (event) => {
    event.preventDefault();
    if (!input.checkValidity()) {
      say('Bitte gib eine gültige E-Mail-Adresse ein.', 'error');
      input.focus();
      return;
    }
    say('Die Warteliste ist noch nicht geöffnet. Schau bald wieder vorbei.', 'info');
  });
}
