import 'package:flutter/material.dart';
import '../groups/data/group_detail.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/row/app_settings_row.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';

/// Selector de pagador de un gasto: lista los miembros del grupo y
/// devuelve el `userId` elegido (`null` si se cancela). Lo usan Log
/// Expense (al crear) y Expense Details (al editar). No llama a la API
/// — los miembros se cargan antes de abrirlo.
///
/// Los nombres/iniciales llegan como callbacks para reusar el mismo
/// fallback de cada pantalla ("You" / "Member ab12cd34").
class PayerPickerDialog extends StatelessWidget {
  const PayerPickerDialog({
    super.key,
    required this.members,
    required this.selectedUserId,
    required this.displayName,
    required this.initials,
  });

  final List<GroupMember> members;
  final String? selectedUserId;
  final String Function(String userId) displayName;
  final String Function(String userId) initials;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pagado por'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final member in members) ...[
            AppSettingsRow(
              icon: AppAvatar(initials: initials(member.userId), size: 24),
              label: displayName(member.userId),
              trailing: member.userId == selectedUserId
                  ? const Icon(
                      Icons.check_circle,
                      color: AppSemanticColors.positiveText,
                      size: 20,
                    )
                  : null,
              onTap: () => Navigator.pop(context, member.userId),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
