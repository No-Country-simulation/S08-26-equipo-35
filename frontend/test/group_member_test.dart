import 'package:flutter_test/flutter_test.dart';
import 'package:splitflow/features/groups/data/group_detail.dart';

/// Tests de `GroupMember` / `GroupDetail` — el modelo de
/// `GET /groups/{id_group}/members` y del `members` embebido en
/// `GET /groups/detail/{id_group}`.
///
/// No hay tests de `GroupRepository`: `ApiClient` es estática y lee
/// `dotenv` y `AuthSession` por dentro, así que no es inyectable sin
/// refactor aparte. Estos tests cubren la parte que sí es testeable sin red,
/// que es el parseo — donde la spec manda `user_id` y `joined_at` obligatorios.
void main() {
  group('GroupMember.fromJson', () {
    test('parsea user_id y joined_at', () {
      final member = GroupMember.fromJson({
        'user_id': 'a3f1c2d4-0000-4000-8000-000000000001',
        'joined_at': '2026-03-14T18:30:00Z',
      });

      expect(member.userId, 'a3f1c2d4-0000-4000-8000-000000000001');
      expect(member.joinedAt, DateTime.utc(2026, 3, 14, 18, 30));
    });

    test('acepta el timestamp con offset, no sólo UTC', () {
      final member = GroupMember.fromJson({
        'user_id': 'u1',
        'joined_at': '2026-03-14T18:30:00+03:00',
      });

      expect(member.joinedAt.toUtc(), DateTime.utc(2026, 3, 14, 15, 30));
    });

    test('lanza si falta user_id (la spec lo marca requerido)', () {
      expect(
        () => GroupMember.fromJson({'joined_at': '2026-03-14T18:30:00Z'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('lanza si joined_at no es una fecha parseable', () {
      expect(
        () => GroupMember.fromJson({'user_id': 'u1', 'joined_at': 'ayer'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('GroupDetail.fromJson', () {
    GroupDetail buildDetail(List<dynamic> members) {
      return GroupDetail.fromJson({
        'group_id': 'g1',
        'group_name': 'Crew & Friends',
        'status': 'active',
        'created_at': '2026-01-02T00:00:00Z',
        'members': members,
      });
    }

    test('parsea el grupo con su lista de miembros', () {
      final detail = buildDetail([
        {
          'user_id': 'u1',
          'joined_at': '2026-01-03T00:00:00Z',
        },
        {
          'user_id': 'u2',
          'joined_at': '2026-01-04T00:00:00Z',
        },
      ]);

      expect(detail.groupId, 'g1');
      expect(detail.groupName, 'Crew & Friends');
      expect(detail.status, GroupStatus.active);
      expect(detail.members, hasLength(2));
      expect(detail.members[0].userId, 'u1');
      expect(detail.members[1].userId, 'u2');
    });

    test('status "settled" se distingue de "active"', () {
      final detail = GroupDetail.fromJson({
        'group_id': 'g1',
        'group_name': 'Viaje',
        'status': 'settled',
        'created_at': '2026-01-02T00:00:00Z',
        'members': <dynamic>[],
      });

      expect(detail.status, GroupStatus.settled);
    });

    test('members vacío es un grupo sin miembros, no un error', () {
      expect(buildDetail(<dynamic>[]).members, isEmpty);
    });
  });
}
