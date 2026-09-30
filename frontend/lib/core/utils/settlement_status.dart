/// Estado de deudas y pagos, según el contrato de la API.
///
/// `DebtResponse.status` es un enum del OpenAPI: `PENDING | PAID | CANCELLED`.
/// `SettlementResponse.status` viene como string libre, así que se mapea al
/// mismo conjunto. Un solo lugar decide qué es "pendiente" — antes cada
/// pantalla comparaba contra 'PAID' por su cuenta y una deuda o un pago
/// `CANCELLED` se contaba como pendiente.
enum SettlementStatusKind {
  /// La deuda sigue impaga / el pago espera confirmación.
  pending,

  /// Saldada: un pago fue confirmado.
  settled,

  /// Rechazado o perdonado. Una deuda cancelada ya no se debe; un pago
  /// cancelado no se puede volver a confirmar, hay que registrar otro.
  cancelled,
}

/// Interpreta el `status` crudo de la API.
///
/// Acepta minúsculas y el `settled` legacy; cualquier valor desconocido
/// (incluido `null` o `''`) se trata como [SettlementStatusKind.pending],
/// que es el lado conservador: nunca esconder una deuda por un valor raro.
SettlementStatusKind settlementStatusOf(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'paid':
    case 'settled':
      return SettlementStatusKind.settled;
    case 'cancelled':
      return SettlementStatusKind.cancelled;
    default:
      return SettlementStatusKind.pending;
  }
}

/// `true` solo para [SettlementStatusKind.pending] — excluye `PAID` **y**
/// `CANCELLED`.
bool isPendingStatus(String? raw) =>
    settlementStatusOf(raw) == SettlementStatusKind.pending;

/// `true` para saldado o cancelado, es decir, "ya no hay nada pendiente acá".
bool isClosedStatus(String? raw) =>
    settlementStatusOf(raw) != SettlementStatusKind.pending;
