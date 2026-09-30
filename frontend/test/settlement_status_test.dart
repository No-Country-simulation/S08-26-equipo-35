import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/core/utils/settlement_status.dart';

void main() {
  group('settlementStatusOf', () {
    test('reconoce los valores del enum de la API', () {
      expect(settlementStatusOf('PENDING'), SettlementStatusKind.pending);
      expect(settlementStatusOf('PAID'), SettlementStatusKind.settled);
      expect(settlementStatusOf('CANCELLED'), SettlementStatusKind.cancelled);
    });

    test('es case-insensitive y tolera espacios', () {
      expect(settlementStatusOf('paid'), SettlementStatusKind.settled);
      expect(settlementStatusOf('Paid'), SettlementStatusKind.settled);
      expect(settlementStatusOf(' cancelled '),
          SettlementStatusKind.cancelled);
    });

    test('acepta el "settled" legacy de respuestas viejas', () {
      expect(settlementStatusOf('settled'), SettlementStatusKind.settled);
    });

    test('un valor desconocido se trata como pendiente', () {
      // Lado conservador: nunca esconder una deuda por un status raro.
      expect(settlementStatusOf('raro'), SettlementStatusKind.pending);
      expect(settlementStatusOf(''), SettlementStatusKind.pending);
      expect(settlementStatusOf(null), SettlementStatusKind.pending);
    });
  });

  group('isPendingStatus', () {
    test('excluye PAID y CANCELLED — el bug que arregla', () {
      // Antes el código comparaba solo contra 'PAID', así que un CANCELLED
      // se contaba como pendiente (y se podía "confirmar").
      expect(isPendingStatus('PENDING'), isTrue);
      expect(isPendingStatus('PAID'), isFalse);
      expect(isPendingStatus('paid'), isFalse);
      expect(isPendingStatus('settled'), isFalse);
      expect(isPendingStatus('CANCELLED'), isFalse);
      expect(isPendingStatus('cancelled'), isFalse);
    });
  });

  group('isClosedStatus', () {
    test('true para saldado y cancelado', () {
      expect(isClosedStatus('PAID'), isTrue);
      expect(isClosedStatus('CANCELLED'), isTrue);
      expect(isClosedStatus('PENDING'), isFalse);
    });
  });
}
