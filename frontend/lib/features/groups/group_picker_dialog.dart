import 'package:flutter/material.dart';
import 'data/group.dart';
import '../../design_system/components/ui/row/app_settings_row.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';

/// Selector de grupo en diálogo: lista los grupos y devuelve el
/// `groupId` elegido (`null` si se cancela). Lo usa Home ("Add Expense")
/// y Balances (entrada sin grupo desde el bottom nav). No llama a la
/// API — los grupos se cargan antes de abrirlo.
class GroupPickerDialog extends StatelessWidget {
  const GroupPickerDialog({
    super.key,
    required this.groups,
    this.memberCounts = const {},
  });

  final List<Group> groups;

  /// groupId -> cantidad de miembros. Si falta para un grupo, la fila
  /// no muestra el trailing "N members".
  final Map<String, int> memberCounts;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups) ...[
            AppSettingsRow(
              icon: const Icon(
                Icons.groups,
                color: AppMd3Colors.primaryContainer,
                size: 20,
              ),
              label: group.groupName,
              trailing: memberCounts.containsKey(group.groupId)
                  ? Text(
                      '${memberCounts[group.groupId]} member'
                      '${memberCounts[group.groupId] == 1 ? '' : 's'}',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate400,
                      ),
                    )
                  : null,
              onTap: () => Navigator.pop(context, group.groupId),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
