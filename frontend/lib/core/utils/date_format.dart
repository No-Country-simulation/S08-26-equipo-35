const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formatea una fecha como "Jul 14, 2024", sin agregar el paquete `intl`
/// solo para esto. Si más adelante necesitas formatos más completos
/// (locales, horas, etc.), ahí sí vale la pena migrar a `intl`.
String formatShortDate(DateTime date) {
  return '${_shortMonths[date.month - 1]} ${date.day}, ${date.year}';
}
