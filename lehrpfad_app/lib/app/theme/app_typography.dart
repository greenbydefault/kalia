/// Design-Tokens der App. Einzige Stelle für Font-Familien.
///
/// Die ganze App nutzt [family]. Call-Sites rühren `fontFamily` nicht an;
/// `TextPainter` ohne Theme-Vererbung setzen [family] explizit.
abstract final class AppTypography {
  static const family = 'Hanken Grotesk';
}
