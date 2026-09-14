import 'package:flutter/material.dart';
import '../avatars/avatar_badge.dart';
import '../tags/app_tag.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_tokens.dart';
import '../../../tokens/app_typography.dart';

/// Tarjeta con las dos partes de una transferencia: avatar+nombre+rol a
/// cada lado, conectados por una flecha con label ("Direct"). Usada en
/// "Mark Payment" y reutilizable en cualquier otra pantalla de settlement
/// entre dos personas.
class TransferPartiesCard extends StatelessWidget {
  const TransferPartiesCard({
    super.key,
    required this.fromAvatar,
    required this.fromName,
    required this.fromRole,
    required this.toAvatar,
    required this.toName,
    required this.toRole,
    required this.connectorLabel,
  });

  final AvatarBadge fromAvatar;
  final String fromName;
  final String fromRole; // ej. "Payer"
  final AvatarBadge toAvatar;
  final String toName;
  final String toRole; // ej. "Recipient"
  final String connectorLabel; // ej. "Direct"

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.xlRadius,
        boxShadow: AppShadows.level1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Party(avatar: fromAvatar, name: fromName, role: fromRole),
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppMd3Colors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppMd3Colors.primaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppMd3Colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    connectorLabel,
                    style: AppTypography.bodySm(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _Party(avatar: toAvatar, name: toName, role: toRole),
        ],
      ),
    );
  }
}

class _Party extends StatelessWidget {
  const _Party({required this.avatar, required this.name, required this.role});

  final AvatarBadge avatar;
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        avatar,
        const SizedBox(height: AppSpacing.xs),
        Text(
          name,
          style: AppTypography.titleMd(color: AppSemanticColors.slate900),
        ),
        const SizedBox(height: AppSpacing.xs2),
        AppTag(
          label: role,
          background: AppMd3Colors.surfaceContainer,
          foreground: AppSemanticColors.slate600,
          uppercase: false,
        ),
      ],
    );
  }
}
