/**
 * Inline-SVGs für Tabs und Chips. Die Dateien nutzen `currentColor`, die Farbe kommt vom umgebenden Text.
 * Originale aus dem Entwurf liegen unter landingpage/ICONS/.
 */
import suchen from './suchen.svg?raw';
import hinkommen from './hinkommen.svg?raw';
import zuhoeren from './zuhoeren.svg?raw';
import sammeln from './sammeln.svg?raw';

export const icons = { suchen, hinkommen, zuhoeren, sammeln };
export type IconName = keyof typeof icons;
