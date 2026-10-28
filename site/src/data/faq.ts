/**
 * FAQ. Texte sind Entwurf nach dem Copy-Brief (Design hatte nur Platzhalter "Wie sagt ihr").
 * Nichts behaupten, was es nicht gibt: kein Store, kein "deutschlandweit".
 */
export type FaqItem = { question: string; answer: string };

export const faq: FaqItem[] = [
  {
    question: 'Was ist Kalia?',
    answer:
      'Eine App für Ausflüge mit Kindern: Lehrpfade, Waldspielplätze und kurze Runden in der Nähe, mit Karte, Stationen und Arten zum Anfassen.',
  },
  {
    question: 'Wann gibt es Kalia?',
    answer:
      'Wir bauen gerade. Trag dich auf die Warteliste ein, dann schreiben wir dir, wenn du Kalia nutzen kannst.',
  },
  {
    question: 'Wo gibt es Lehrpfade in Kalia?',
    answer:
      'Wir fangen im Nordosten an, in Brandenburg und an der Müritz. Die Karte wächst von dort aus.',
  },
  {
    question: 'Brauche ich ein Konto?',
    answer: 'Nein. Du kannst Kalia ohne Konto nutzen.',
  },
  {
    question: 'Was kostet Kalia?',
    answer: 'Dazu gibt es noch keine Entscheidung. Auf der Warteliste erfährst du es als Erste oder Erster.',
  },
  {
    question: 'Was passiert mit meiner E-Mail-Adresse?',
    answer:
      'Wir nutzen sie nur, um dir zu schreiben, wenn es Kalia gibt oder wirklich etwas zu sehen ist. Mehr steht in der Datenschutzerklärung.',
  },
];
