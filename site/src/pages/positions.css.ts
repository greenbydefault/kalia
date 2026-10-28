import type { APIRoute } from 'astro';
import { buildPositionsCss } from '../data/positions-css';

/** Statisch beim Build erzeugt: dist/positions.css. Siehe data/positions-css.ts. */
export const GET: APIRoute = () =>
  new Response(buildPositionsCss(), { headers: { 'Content-Type': 'text/css; charset=utf-8' } });
