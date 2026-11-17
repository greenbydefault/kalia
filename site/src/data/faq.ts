/**
 * FAQ. Ich-Stimme (Oliver), Familie "ihr", Warteliste "du". Regeln: lehrpfad_app/docs/intern/landing/copy-brief.md.
 * Keine Katalog-Zahlen im Text, sie veralten schneller als der Deploy. "Ganz Deutschland" nur mit Dünn-Hinweis.
 * Ungebaute Features (Events) nur im Futur, kein Store-Versprechen im Präsens.
 */
export type FaqItem = { question: string; answer: string };

export const faq: FaqItem[] = [
  {
    question: 'Was ist Kalia?',
    answer:
      'Kalia ist eine App für Ausflüge mit Kindern in die Natur. Sie zeigt euch Lehrpfade, Waldspielplätze, Baumwipfelpfade und Kinderbauernhöfe in der Nähe, mit allem, was ihr vor dem Losfahren wissen wollt: wie weit, wie lange, ob Eintritt anfällt. Damit die Planung fünf Minuten dauert und nicht den halben Vormittag.',
  },
  {
    question: 'Was gibt es außer den Wegen?',
    answer:
      'Eine ganze Menge rund um den Ausflug. Kalia zeigt euch Cafés, Hofläden, Badestellen und Museen in der Nähe, damit ihr wisst, wo es danach Kuchen gibt. Unterwegs entdecken eure Kinder Pflanzen und Tiere, die genau dort vorkommen, markieren sie als gesehen und bauen sich so ihre eigene Sammlung auf. Bald kommen Veranstaltungen in der Nähe dazu, zum Beispiel ein Kinderfest am Wochenende.',
  },
  {
    question: 'Wo gibt es Lehrpfade in Kalia?',
    answer:
      'In ganz Deutschland, und es werden regelmäßig mehr. Ich pflege laufend neue Orte ein, deshalb ist die Karte in manchen Gegenden schon voll und in anderen noch dünn. Schaut oben auf der Karte, was bei euch schon drin ist. Danach geht es in Europa weiter.',
  },
  {
    question: 'Wie lang sind die Wege?',
    answer:
      'Ganz unterschiedlich. Viele sind kurze Runden unter 2 km, die auch kleine Beine schaffen. Dazu kommen längere Touren für größere Kinder und alle, die gern weiter laufen. Länge und Dauer stehen bei jedem Ort, so seht ihr vorher, was zu eurem Tag passt.',
  },
  {
    question: 'Was kostet Kalia?',
    answer:
      'Das entscheide ich noch, auf der Warteliste erfahrt ihr es zuerst. Die Ausflüge selbst kosten meistens nichts. Eintritt nehmen vor allem Baumwipfelpfade, und das steht dann beim Ort.',
  },
  {
    question: 'Brauche ich ein Konto?',
    answer:
      'Nein. Ihr könnt Orte finden, losgehen, merken und Arten sammeln, ohne euch anzumelden. Das bleibt alles auf eurem Handy. Ein Konto braucht ihr erst, wenn ihr Fotos teilen, einen Ort bewerten oder einen neuen Pfad einreichen wollt.',
  },
  {
    question: 'Was ist anders als bei Komoot oder Outdooractive?',
    answer:
      'Komoot und Outdooractive sind gut, wenn ihr eine Wanderung oder Radtour plant. Kalia ist für den Moment davor: Das Kind ist angezogen, ihr wollt raus, aber keine 14 km laufen. Dann zeigt Kalia, was in der Nähe zu euch passt und was es dort zu entdecken gibt.',
  },
  {
    question: 'Wann gibt es Kalia?',
    answer:
      'Ich baue und teste gerade. Kalia kommt in den App Store und zu Google Play. Trag dich auf die Warteliste ein, dann sage ich dir Bescheid, sobald du die App installieren kannst.',
  },
  {
    question: 'Was passiert mit meiner E-Mail-Adresse?',
    answer:
      'Ich schreibe dir, wenn Kalia im Store ist. Dazwischen nur, wenn es wirklich etwas zu zeigen gibt, keinen Newsletter im Zwei-Wochen-Takt. Abmelden geht jederzeit über den Link in jeder Mail. Details stehen in der Datenschutzerklärung.',
  },
  {
    question: 'Ein Pfad fehlt. Kann ich ihn melden?',
    answer:
      'Ja, gern. In der App lauft ihr den Pfad einfach ab, Kalia zeichnet den Weg auf und ihr markiert die Stationen. Ich prüfe die Meldung und nehme den Pfad auf.',
  },
];
