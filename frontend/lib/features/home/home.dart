import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/badges/balance_badge.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/cards/group_card.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/icon_boxes/app_icon_box.dart';
import '../../design_system/components/ui/row/meta_row.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../design_system/navigations/app_bottom_nav_bar.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_ui.dart';
import '../../router/app_router.dart';
import '../auth/data/auth_repository.dart';
import '../balances/data/balance_summary.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
import '../groups/data/group.dart';
import '../groups/group_picker_dialog.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';

/// Resumen ya calculado de un grupo: el grupo en sÃ­ + cuÃ¡ntos miembros
/// tiene + el balance neto del usuario + el Ãºltimo gasto agregado.
class _GroupSummary {
  const _GroupSummary({
    required this.group,
    required this.memberCount,
    required this.netBalance,
    this.lastExpense,
  });

  final Group group;
  final int memberCount;

  /// null = no se pudo calcular (ej. no hay userId de sesiÃ³n disponible) â€”
  /// distinto de 0, que significa "saldado de verdad".
  final double? netBalance;
  final Expense? lastExpense;
}

class _HomeData {
  const _HomeData({
    required this.groups,
    required this.overallNet,
    this.iOwe = 0,
    this.owedToMe = 0,
    this.pendingCount = 0,
  });
  final List<_GroupSummary> groups;
  final double? overallNet;

  /// Suma de deudas pendientes (status != PAID) donde soy deudor.
  final double iOwe;

  /// Suma de deudas pendientes donde soy acreedor.
  final double owedToMe;

  /// Cantidad de deudas pendientes que me involucran (en todos los grupos).
  final int pendingCount;
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<_HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadHomeData();
  }

  void _retry() {
    setState(() {
      _dataFuture = _loadHomeData();
    });
  }

  Future<void> _showCreateGroupDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateGroupDialog(),
    );

    if (created == true && mounted) {
      _retry();
    }
  }

  /// Trae los grupos y el balance del usuario en todos ellos, y por grupo
  /// su detalle (miembros) y sus gastos.
  ///
  /// El balance sale de UN solo pedido â€” `GET /users/me/balance-summary`
  /// devuelve `net` global y el `net` de cada grupo en `per_group`. Antes
  /// esta pantalla armaba lo mismo en el cliente: `GET /debts/me` + un
  /// `calculateNetBalance` POR grupo, o sea 3N+1 pedidos.
  ///
  /// `groupDetail` sigue siendo necesario por grupo: el summary global no
  /// incluye `member_count`, y lo usan la etiqueta "N members" de cada
  /// tarjeta y el `GroupPickerDialog`.
  ///
  /// El loop por grupo es secuencial a propÃ³sito para no saturar de golpe
  /// un backend gratuito de Render â€” si tu API aguanta mÃ¡s carga, se puede
  /// paralelizar con Future.wait sobre la lista completa de grupos.
  Future<_HomeData> _loadHomeData() async {
    final groups = await GroupRepository.instance.listGroups();

    // Si el summary falla, la pantalla igual muestra los grupos: los net
    // quedan null (badge "unknown") en vez de caer en el error general.
    UserGlobalSummary? summary;
    try {
      summary = await AuthRepository.instance.getMyBalanceSummary();
    } on ApiException {
      summary = null;
    }

    final netsByGroup = summary?.byGroupId ?? const <String, PerGroupUserSummary>{};

    final summaries = <_GroupSummary>[];
    for (final group in groups) {
      // El balance no depende de estos pedidos, asÃ­ que sobrevive aunque
      // el grupo falle: se conserva en vez de volver a null.
      final net = netsByGroup[group.groupId]?.net;
      try {
        final results = await Future.wait([
          GroupRepository.instance.groupDetail(group.groupId),
          ExpenseRepository.instance.listGroupExpenses(group.groupId),
        ]);
        final detail = results[0] as GroupDetail;
        final expenses = results[1] as List<Expense>;

        Expense? last;
        for (final e in expenses) {
          if (last == null || e.createdAt.isAfter(last.createdAt)) last = e;
        }

        summaries.add(
          _GroupSummary(
            group: group,
            memberCount: detail.members.length,
            netBalance: net,
            lastExpense: last,
          ),
        );
      } catch (_) {
        summaries.add(
          _GroupSummary(
            group: group,
            memberCount: 0,
            netBalance: net,
          ),
        );
      }
    }

    return _HomeData(
      groups: summaries,
      overallNet: summary?.net,
      iOwe: summary?.totalOwed ?? 0,
      owedToMe: summary?.totalToReceive ?? 0,
      pendingCount: summary == null
          ? 0
          : summary.perGroup.fold(0, (acc, g) => acc + g.pendingCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      appBar: AppTopBar(
        title: 'Inicio',
        leading: const AppIconBox(
          icon: Icon(Icons.call_split, color: Colors.white, size: 18),
          background: AppMd3Colors.primaryContainer,
          size: 32,
          radius: BorderRadius.all(Radius.circular(8)),
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: FutureBuilder<_HomeData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final hasError = snapshot.hasError;
          final data = snapshot.data;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(
                      isLoading: loading,
                      overallNet: data?.overallNet,
                      groupCount: data?.groups.length,
                      onNewGroup: () => _showCreateGroupDialog(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AppFilterChip(
                            label: 'Todos',
                            selected: true,
                            onTap: () {},
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppFilterChip(
                            label: 'Viajes',
                            selected: false,
                            onTap: () {},
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppFilterChip(
                            label: 'Apartamento',
                            selected: false,
                            onTap: () {},
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppFilterChip(
                            label: 'Social',
                            selected: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (hasError)
                      _ErrorState(onRetry: _retry)
                    else if (data == null || data.groups.isEmpty)
                      const _EmptyState()
                    else ...[
                      SectionHeader(
                        title: 'Grupos activos',
                        count: data.groups.length,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: AppMd3Colors.primaryContainer,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final summary in data.groups) ...[
                        _buildGroupCard(context, summary),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _settlementsBanner(
                      loading: loading,
                      hasError: hasError,
                      data: data,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              Positioned(
                right: AppSpacing.marginMobile,
                bottom: AppSpacing.md,
                child: AppButton(
                  label: 'Agregar gasto',
                  leadingIcon: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                  expand: false,
                  onPressed: (data == null || data.groups.isEmpty)
                      ? null
                      : () async {
                          // Capturado antes de cualquier await para no
                          // usar el BuildContext a travÃ©s de un gap.
                          final navigator = Navigator.of(context);
                          // Con 1 solo grupo no hay nada que elegir: va
                          // directo. Con varios, pide el grupo en un
                          // diÃ¡logo antes de abrir Log Expense.
                          String? groupId = data.groups.first.group.groupId;
                          if (data.groups.length > 1) {
                            groupId = await showDialog<String>(
                              context: context,
                              builder: (_) => GroupPickerDialog(
                                groups: [
                                  for (final s in data.groups) s.group,
                                ],
                                memberCounts: {
                                  for (final s in data.groups)
                                    s.group.groupId: s.memberCount,
                                },
                              ),
                            );
                          }
                          if (groupId == null) return;
                          if (!mounted) return;
                          final created = await navigator.pushNamed(
                            AppRoutes.logExpense,
                            arguments: groupId,
                          );
                          if (created == true) _retry();
                        },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: const [
          AppBottomNavItem(icon: Icons.groups, label: 'Grupos'),
          AppBottomNavItem(icon: Icons.receipt_long, label: 'Actividad'),
          AppBottomNavItem(
            icon: Icons.account_balance_wallet,
            label: 'Saldos',
          ),
          AppBottomNavItem(icon: Icons.person, label: 'Perfil'),
        ],
        currentIndex: 0,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  /// Banner de settlements pendientes:
  /// - mientras carga, mensaje neutro;
  /// - si hubo error, no se puede afirmar nada;
  /// - con deudas pendientes, cuÃ¡nto debes y cuÃ¡nto te deben (GET /debts/me);
  /// - sin deudas, el mensaje de "todo en orden".
  Widget _settlementsBanner({
    required bool loading,
    required bool hasError,
    required _HomeData? data,
  }) {
    if (hasError) {
      return const AppInfoBanner(
        icon: Icon(
          Icons.help_outline,
          color: AppSemanticColors.slate400,
        ),
        title: 'Saldos no disponibles',
        description: 'No pudimos cargar tus saldos pendientes.',
        background: AppSemanticColors.slate100,
      );
    }

    if (loading || data == null) {
      return const AppInfoBanner(
        icon: Icon(
          Icons.hourglass_empty,
          color: AppMd3Colors.primaryContainer,
        ),
        title: 'Revisando saldos…',
        description: 'Buscando saldos pendientes en tus grupos.',
        background: AppMd3Colors.surfaceContainerLow,
      );
    }

    if (data.pendingCount == 0) {
      return const AppInfoBanner(
        icon: Icon(
          Icons.celebration,
          color: AppMd3Colors.primaryContainer,
        ),
        title: "You're in good shape!",
        description: 'No hay saldos urgentes por hoy.',
      );
    }

    return AppInfoBanner(
      icon: const Icon(
        Icons.account_balance_wallet,
        color: AppSemanticColors.negativeText,
      ),
      title: 'Saldos pendientes',
      background: AppSemanticColors.negativeContainer,
      descriptionWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.iOwe > 0)
            Text(
              'Debes \$${data.iOwe.toStringAsFixed(2)}',
              style: AppTypography.bodySm(
                color: AppSemanticColors.negativeText,
              ),
            ),
          if (data.owedToMe > 0)
            Text(
              'Te deben \$${data.owedToMe.toStringAsFixed(2)}',
              style: AppTypography.bodySm(
                color: AppSemanticColors.positiveText,
              ),
            ),
          Text(
            '${data.pendingCount} pending settlement${data.pendingCount == 1 ? '' : 's'}',
            style: AppTypography.bodySm(color: AppSemanticColors.slate600),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, _GroupSummary summary) {
    final net = summary.netBalance;
    final BalanceBadgeStatus status;
    final String amountLabel;
    final String? caption;

    if (net == null) {
      status = BalanceBadgeStatus.unknown;
      amountLabel = '—';
      caption = null;
    } else if (net > 0.005) {
      status = BalanceBadgeStatus.owed;
      amountLabel = '+\$${net.toStringAsFixed(2)}';
      caption = 'te deben';
    } else if (net < -0.005) {
      status = BalanceBadgeStatus.owe;
      amountLabel = '-\$${net.abs().toStringAsFixed(2)}';
      caption = 'debes';
    } else {
      status = BalanceBadgeStatus.settled;
      amountLabel = '\$0.00';
      caption = 'saldado';
    }

    final metaText = summary.lastExpense != null
        ? 'Último: ${summary.lastExpense!.title} (\$${summary.lastExpense!.totalAmount.toStringAsFixed(2)})'
        : 'Todavía no hay gastos';

    return GroupCard(
      // Ãcono genÃ©rico: la API no tiene campo de Ã­cono/color por grupo.
      icon: const Icon(Icons.groups, color: AppMd3Colors.primaryContainer),
      iconBackground: AppMd3Colors.surfaceContainer,
      title: summary.group.groupName,
      memberAvatars:
          const [], // sin fotos/nombres: no hay endpoint de usuarios por id
      memberCountLabel:
          '${summary.memberCount} member${summary.memberCount == 1 ? '' : 's'}',
      balanceAmountLabel: amountLabel,
      balanceStatus: status,
      balanceCaption: caption,
      metaIcon: const Icon(
        Icons.receipt_long,
        size: 16,
        color: AppSemanticColors.slate400,
      ),
      metaText: metaText,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.groupDetails,
        arguments: summary.group.groupId,
      ).then((_) => _retry()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppSemanticColors.negativeText,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No pudimos cargar tus grupos.',
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Reintentar', expand: false, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.groups_outlined,
            color: AppSemanticColors.slate400,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Todavía no tienes grupos. Crea el primero para empezar.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd(color: AppSemanticColors.slate600),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de resumen superior. Muestra "â€”" mientras carga; una vez que
/// `overallNet` llega, ya es el balance real sumado de todos los grupos.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isLoading,
    this.overallNet,
    this.groupCount,
    this.onNewGroup,
  });

  final bool isLoading;
  final double? overallNet;
  final int? groupCount;
  final VoidCallback? onNewGroup;

  @override
  Widget build(BuildContext context) {
    final bool unknown = !isLoading && overallNet == null;
    final net = overallNet ?? 0;
    final isOwed = net >= 0;
    final amountLabel = (isLoading || unknown)
        ? '—'
        : '${isOwed ? '+' : '-'}\$${net.abs().toStringAsFixed(2)}';
    final statusLabel = unknown
        ? 'Balance general'
        : (isOwed ? 'En total, te deben' : 'En total, debes');
    final countLabel = groupCount == null
        ? 'En tus grupos activos'
        : 'En $groupCount grupo${groupCount == 1 ? '' : 's'} activo${groupCount == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppSemanticColors.positiveContainer,
        borderRadius: AppRadius.xlRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: AppRadius.fullRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOwed ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 14,
                        color: AppSemanticColors.positiveText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: AppTypography.bodySm(
                          color: AppSemanticColors.positiveText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  amountLabel,
                  style: AppTypography.displayCurrency(
                    color: AppSemanticColors.slate900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppSemanticColors.positive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs2),
                    Text(
                      countLabel,
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _NewGroupAction(onTap: onNewGroup),
        ],
      ),
    );
  }
}

class _NewGroupAction extends StatelessWidget {
  const _NewGroupAction({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: AppRadius.lgRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppMd3Colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs2),
            Text(
              'Nuevo grupo',
              style: AppTypography.labelMd(color: AppSemanticColors.slate900),
            ),
          ],
        ),
      ),
    );
  }
}

void _onNavTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      break;
    case 1:
      Navigator.pushReplacementNamed(context, AppRoutes.history);
      break;
    case 2:
      Navigator.pushReplacementNamed(context, AppRoutes.balances);
      break;
    default:
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
      break;
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para el grupo.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await GroupRepository.instance.createGroup(name);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(error);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo grupo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Nombre del grupo',
            hintText: 'Ej. Viaje a Barcelona',
            controller: _nameController,
            prefixIcon: const Icon(Icons.group_add),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySm(color: AppSemanticColors.negativeText),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _handleCreate,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
