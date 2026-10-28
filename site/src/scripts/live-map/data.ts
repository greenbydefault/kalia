import { tagLabels, typLabels } from '../../data/live-map';

export type TrailPin = {
  id: string;
  name: string;
  typ: string;
  typLabel: string;
  region: string;
  ort: string;
  km: number;
  min: number;
  stationen: number;
  tags: string[];
  lat: number;
  lon: number;
};

type Row = {
  id: string;
  name: string;
  typ: string;
  region: string | null;
  ort: string | null;
  laenge_km: number | null;
  dauer_min: number | null;
  tags: string[] | null;
  start_lat: number | null;
  start_lon: number | null;
  stations: { count: number }[] | null;
};

const SELECT = 'id,name,typ,region,ort,laenge_km,dauer_min,tags,start_lat,start_lon,stations(count)';

/**
 * Sichtbare Trails live aus Supabase (anon, Publishable Key). Bewusst ohne `route` (schwer, hier unnötig).
 * Wirft bei fehlender Konfiguration, Netzfehler und Timeout, der Aufrufer zeigt dann den ruhigen Hinweis.
 */
export async function fetchTrails(signal?: AbortSignal): Promise<TrailPin[]> {
  const url = import.meta.env.PUBLIC_SUPABASE_URL as string | undefined;
  const key = import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY as string | undefined;
  if (!url || !key) throw new Error('Supabase nicht konfiguriert');

  const timeout = new AbortController();
  const timer = setTimeout(() => timeout.abort(), 12000);
  signal?.addEventListener('abort', () => timeout.abort());

  try {
    const res = await fetch(
      `${url}/rest/v1/trails?select=${SELECT}&sichtbar=eq.true&start_lat=not.is.null&start_lon=not.is.null&order=id`,
      { headers: { apikey: key }, signal: timeout.signal },
    );
    if (!res.ok) throw new Error(`Supabase ${res.status}`);
    const rows = (await res.json()) as Row[];
    return rows.map(toPin);
  } finally {
    clearTimeout(timer);
  }
}

function toPin(r: Row): TrailPin {
  return {
    id: r.id,
    name: r.name,
    typ: r.typ,
    typLabel: typLabels[r.typ] ?? 'Lehrpfad',
    region: r.region ?? '',
    ort: r.ort ?? '',
    km: r.laenge_km ?? 0,
    min: r.dauer_min ?? 0,
    stationen: r.stations?.[0]?.count ?? 0,
    tags: (r.tags ?? []).filter((t) => t in tagLabels),
    lat: r.start_lat as number,
    lon: r.start_lon as number,
  };
}
