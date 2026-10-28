import { gsap } from 'gsap';
import { prefersReducedMotion } from './motion';

/**
 * Hörprobe (AudioPlayer.astro). Ein Player pro [data-audio], immer spielt nur einer.
 * Daten kommen aus dem Markup (data-peaks, data-duration), die Dateien aus data/audio.ts.
 * Bewegung: Play/Pause-Icon tauscht per GSAP (power2.out, 0.2 s), Balken füllen sich mit dem Fortschritt.
 * Anzeige rechts = Restzeit. Zeigt zu Beginn die Länge, bis der Browser die echte kennt.
 */

const UNPLAYED = 0.35;
const SEEK_STEP = 5; // Prozent pro Pfeiltaste

type Player = {
  root: HTMLElement;
  audio: HTMLAudioElement;
  /** Pausiert (ohne Zurücksetzen) */
  pause: () => void;
  /** Pausiert und setzt alles auf Anfang */
  reset: () => void;
};

const players: Player[] = [];
let active: Player | null = null;

const mmss = (sec: number) => {
  const s = Math.max(0, Math.ceil(sec));
  return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
};

function create(root: HTMLElement): Player | null {
  const audio = root.querySelector<HTMLAudioElement>('audio');
  const toggle = root.querySelector<HTMLButtonElement>('[data-audio-toggle]');
  const wave = root.querySelector<HTMLElement>('[data-audio-wave]');
  const time = root.querySelector<HTMLElement>('[data-audio-time]');
  const iconPlay = root.querySelector<SVGElement>('[data-audio-icon-play]');
  const iconPause = root.querySelector<SVGElement>('[data-audio-icon-pause]');
  if (!audio || !toggle || !wave || !time || !iconPlay || !iconPause) return null;

  const peaks = (root.dataset.peaks ?? '').split(',').map(Number).filter((n) => n > 0);
  const label = toggle.getAttribute('aria-label')?.replace(/ anhören$/, '') ?? '';
  let fallbackDuration = Number(root.dataset.duration) || 0;
  let playing = false;
  let lit = 0; // Anzahl gefüllter Balken

  const bars = peaks.map((h) => {
    const bar = document.createElement('span');
    bar.className = 'audio__bar';
    bar.dataset.audioBar = '';
    bar.style.height = `${Math.round(h * 100)}%`;
    wave.append(bar);
    return bar;
  });

  const dur = () => (Number.isFinite(audio.duration) && audio.duration > 0 ? audio.duration : fallbackDuration);
  const ratio = () => (dur() ? Math.min(1, audio.currentTime / dur()) : 0);
  const speed = (d: number) => (prefersReducedMotion() ? 0 : d);

  gsap.set(iconPause, { opacity: 0, scale: 0.4, transformOrigin: '50% 50%' });
  gsap.set(iconPlay, { opacity: 1, scale: 1, transformOrigin: '50% 50%' });

  function paintBars() {
    const n = Math.round(ratio() * bars.length);
    if (n === lit) return;
    const from = Math.min(n, lit);
    const to = Math.max(n, lit);
    gsap.to(bars.slice(from, to), {
      opacity: n > lit ? 1 : UNPLAYED,
      duration: speed(0.15),
      overwrite: 'auto',
    });
    lit = n;
  }

  function paintTime() {
    time!.textContent = mmss(dur() - audio!.currentTime);
    const pct = Math.round(ratio() * 100);
    wave!.setAttribute('aria-valuenow', String(pct));
    wave!.setAttribute('aria-valuetext', `${mmss(audio!.currentTime)} von ${mmss(dur())}`);
  }

  const tick = () => {
    paintBars();
    paintTime();
  };

  function setPlaying(next: boolean, instant = false) {
    if (playing === next && !instant) return;
    playing = next;
    toggle!.setAttribute('aria-label', `${label} ${next ? 'pausieren' : 'anhören'}`);
    const d = instant ? 0 : speed(0.2);
    gsap.to(iconPlay, { opacity: next ? 0 : 1, scale: next ? 0.4 : 1, duration: d, ease: 'power2.out', overwrite: 'auto' });
    gsap.to(iconPause, { opacity: next ? 1 : 0, scale: next ? 1 : 0.4, duration: d, ease: 'power2.out', overwrite: 'auto' });
    if (next) gsap.ticker.add(tick);
    else gsap.ticker.remove(tick);
  }

  const player: Player = {
    root,
    audio,
    pause: () => audio.pause(),
    reset: () => {
      audio.pause();
      audio.currentTime = 0;
      setPlaying(false, true);
      if (active === player) active = null;
      gsap.killTweensOf(bars, 'opacity');
      gsap.set(bars, { opacity: UNPLAYED });
      lit = 0;
      paintTime();
    },
  };

  audio.addEventListener('play', () => {
    if (active && active !== player) active.pause();
    active = player;
    setPlaying(true);
  });
  audio.addEventListener('pause', () => {
    setPlaying(false);
    tick();
  });
  audio.addEventListener('ended', () => player.reset());
  audio.addEventListener('loadedmetadata', () => {
    fallbackDuration = dur();
    paintTime();
  });

  toggle.addEventListener('click', () => {
    if (audio.paused) void audio.play().catch(() => setPlaying(false));
    else audio.pause();
  });

  function seek(r: number) {
    if (!dur()) return;
    audio!.currentTime = Math.min(1, Math.max(0, r)) * dur();
    tick();
  }

  wave.addEventListener('click', (event) => {
    const box = wave.getBoundingClientRect();
    seek((event.clientX - box.left) / box.width);
  });

  wave.addEventListener('keydown', (event) => {
    const step = SEEK_STEP / 100;
    if (event.key === 'ArrowRight') seek(ratio() + step);
    else if (event.key === 'ArrowLeft') seek(ratio() - step);
    else if (event.key === 'Home') seek(0);
    else if (event.key === 'End') seek(1);
    else return;
    event.preventDefault();
  });

  paintTime();
  return player;
}

export function initAudioPlayers() {
  document.querySelectorAll<HTMLElement>('[data-audio]').forEach((root) => {
    const player = create(root);
    if (player) players.push(player);
  });
}

/** Hält alle Player in `container` an (ohne Zurücksetzen). Für den Moment, in dem eine Karte zugeht. */
export function pauseAudioIn(container: Element) {
  players.filter((p) => container.contains(p.root)).forEach((p) => p.pause());
}

/** Hält alle Player in `container` an und setzt sie auf Anfang. */
export function resetAudioIn(container: Element) {
  players.filter((p) => container.contains(p.root)).forEach((p) => p.reset());
}
