const _shortMonths = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Formatea una fecha como "14 jul 2024", sin agregar el paquete `intl`
/// solo para esto. Si más adelante necesitas formatos más completos
/// (locales, horas, etc.), ahí sí vale la pena migrar a `intl`.
///
/// Día primero y sin coma, que es la convención en español. Antes producía
/// "Jul 14, 2024", que es el orden y la puntuación del inglés.
String formatShortDate(DateTime date) {
  return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
}
