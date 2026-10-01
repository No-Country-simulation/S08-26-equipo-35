import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/features/balances/data/balance_summary.dart';

/// base válida de un per-group, para pisar sólo el campo que se prueba.
Map<String, dynamic> _perGroupJson({
  Object? owed = '10.50',
  Object? toReceive = '25.00',
  Object? net = '14.50',
  Object? pendingCount = 2,
  Object? isSettled = false,
  bool includeIsSettled = true,
}) {
  return {
    'group_id': 'g-1',
    'group_name': 'Trip',
    'owed': owed,
    'to_receive': toReceive,
    'net': net,
    'pending_count': pendingCount,
    if (includeIsSettled) 'is_settled': isSettled,
  };
}

Map<String, dynamic> _globalJson({
  Object? totalOwed = '30.00',
  Object? totalToReceive = '50.00',
  Object? net = '20.00',
  List<Map<String, dynamic>>? perGroup,
}) {
  return {
    'user_id': 'u-1',
    'total_owed': totalOwed,
    'total_to_receive': totalToReceive,
    'net': net,
    'group_count': 1,
    'per_group': perGroup ?? [_perGroupJson()],
  };
}

void main() {
  group('PerGroupUserSummary.fromJson', () {
    test('parsea el caso normal', () {
      final g = PerGroupUserSummary.fromJson(_perGroupJson());

      expect(g.groupId, 'g-1');
      expect(g.groupName, 'Trip');
      expect(g.owed, 10.50);
      expect(g.toReceive, 25.00);
      expect(g.net, 14.50);
      expect(g.pendingCount, 2);
      expect(g.isSettled, isFalse);
    });

    test('montos numéricos (no string) también se parsean', () {
      // La API manda strings, pero un num no debe romper el parseo.
      final g = PerGroupUserSummary.fromJson(
        _perGroupJson(owed: 10.5, net: -4),
      );

      expect(g.owed, 10.5);
      expect(g.net, -4.0);
    });

    test('net negativo se conserva (debo yo)', () {
      final g = PerGroupUserSummary.fromJson(_perGroupJson(net: '-33.25'));

      expect(g.net, -33.25);
    });

    test('is_settled ausente cae a false, no a null', () {
      final g = PerGroupUserSummary.fromJson(
        _perGroupJson(includeIsSettled: false),
      );

      expect(g.isSettled, isFalse);
    });

    test('campos ausentes no revientan', () {
      final g = PerGroupUserSummary.fromJson({'group_id': 'g-9'});

      expect(g.groupId, 'g-9');
      expect(g.groupName, '');
      expect(g.owed, 0);
      expect(g.pendingCount, 0);
    });

    test('montos con formato inválido no revientan', () {
      final g = PerGroupUserSummary.fromJson(
        _perGroupJson(owed: 'no-es-un-numero'),
      );

      expect(g.owed, 0);
    });
  });

  group('UserGlobalSummary.fromJson', () {
    test('parsea el caso normal', () {
      final s = UserGlobalSummary.fromJson(_globalJson());

      expect(s.userId, 'u-1');
      expect(s.totalOwed, 30.00);
      expect(s.totalToReceive, 50.00);
      expect(s.net, 20.00);
      expect(s.groupCount, 1);
      expect(s.perGroup, hasLength(1));
      expect(s.perGroup.first.net, 14.50);
    });

    test('per_group vacío no rompe', () {
      final s = UserGlobalSummary.fromJson(_globalJson(perGroup: []));

      expect(s.perGroup, isEmpty);
    });

    test('per_group ausente no rompe', () {
      final s = UserGlobalSummary.fromJson(_globalJson()..remove('per_group'));

      expect(s.perGroup, isEmpty);
    });

    test('byGroupId indexa por group_id', () {
      final s = UserGlobalSummary.fromJson(_globalJson(perGroup: [
        _perGroupJson(),
        {..._perGroupJson(), 'group_id': 'g-2', 'net': '3.00'},
      ]));

      expect(s.byGroupId.keys, containsAll(<String>['g-1', 'g-2']));
      expect(s.byGroupId['g-2']!.net, 3.00);
      expect(s.byGroupId['no-existe'], isNull);
    });

    test('byGroupId sobre per_group vacío queda vacío', () {
      final s = UserGlobalSummary.fromJson(_globalJson(perGroup: []));

      expect(s.byGroupId, isEmpty);
    });
  });

  group('GroupBalanceSummary.fromJson', () {
    Map<String, dynamic> summaryJson() => {
          'group_id': 'g-1',
          'total_expenses': '500.00',
          'total_settled_amount': '200.00',
          'total_pending_amount': '100.00',
          'pending_count': 3,
          'member_count': 4,
          'is_settled': false,
          'balances': [
            {
              'user_id': 'u-1',
              'name': 'Ana',
              'paid': '250.00',
              'owed': '125.00',
              'net_balance': '125.00',
            },
          ],
          'suggested_transfers': [
            {
              'debtor_user_id': 'u-2',
              'debtor_name': 'Beto',
              'creditor_user_id': 'u-1',
              'creditor_name': 'Ana',
              'amount': '50.00',
            },
          ],
        };

    test('parsea el caso normal', () {
      final s = GroupBalanceSummary.fromJson(summaryJson());

      expect(s.groupId, 'g-1');
      expect(s.totalExpenses, 500.00);
      expect(s.totalSettledAmount, 200.00);
      expect(s.totalPendingAmount, 100.00);
      expect(s.pendingCount, 3);
      expect(s.memberCount, 4);
      expect(s.isSettled, isFalse);
      expect(s.balances, hasLength(1));
      expect(s.balances.first.name, 'Ana');
      expect(s.balances.first.netBalance, '125.00');
    });

    test('parsea las transferencias sugeridas', () {
      final s = GroupBalanceSummary.fromJson(summaryJson());

      expect(s.suggestedTransfers, hasLength(1));
      expect(s.suggestedTransfers.first.amount, '50.00');
      expect(s.suggestedTransfers.first.debtorName, 'Beto');
    });

    test('balances y suggested_transfers ausentes quedan vacíos', () {
      final s = GroupBalanceSummary.fromJson(summaryJson()
        ..remove('balances')
        ..remove('suggested_transfers'));

      expect(s.balances, isEmpty);
      expect(s.suggestedTransfers, isEmpty);
    });

    test('is_settled true se parsea', () {
      final s = GroupBalanceSummary.fromJson(
        summaryJson()..['is_settled'] = true,
      );

      expect(s.isSettled, isTrue);
    });

    test('miembros con un item no-dict se ignoran sin romper', () {
      final s = GroupBalanceSummary.fromJson(
        summaryJson()..['balances'] = ['basura', null],
      );

      expect(s.balances, isEmpty);
    });
  });
}