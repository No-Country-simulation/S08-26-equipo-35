import 'package:flutter/material.dart';
import '../../design_system/components/ui/avatars/avatar_stack.dart';
import '../../design_system/components/ui/banners/app_info_banner.dart';
import '../../design_system/components/ui/buttons/app_button.dart';
import '../../design_system/components/ui/cards/app_stat_card.dart';
import '../../design_system/components/ui/cards/expense_list_row.dart';
import '../../design_system/components/ui/chips/app_filter_chip.dart';
import '../../design_system/components/ui/chips/member_chip.dart';
import '../../design_system/components/ui/headers/app_cover_header.dart';
import '../../design_system/components/ui/row/meta_row.dart';
import '../../design_system/components/ui/row/app_settings_row.dart';
import '../../design_system/components/ui/buttons/app_text_action.dart';
import '../../design_system/components/ui/titles/app_quick_action_tile.dart';
import '../../design_system/components/ui/titles/app_editable_title.dart';
import '../../design_system/navigations/app_top_bar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_tokens.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../core/utils/category_visual.dart';
import '../../core/utils/settlement_status.dart';
import '../../core/utils/date_format.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_ui.dart';
import '../../design_system/components/ui/text_fields/app_text_field.dart';
import '../../router/app_router.dart';
import '../auth/data/auth_session.dart';
import '../auth/data/user_profile.dart';
import '../expenses/data/expense.dart';
import '../expenses/data/expense_repository.dart';
import '../groups/data/group_detail.dart';
import '../groups/data/group_repository.dart';
import '../groups/domain/balance_calculator.dart';

/// Botón de volver con fondo translúcido, para que se lea sobre la imagen a
/// sangre sin depender de que la foto salga clara.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppSemanticColors.slate900, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _GroupDetailsData {
  const _GroupDetailsData({
    required this.detail,
    required this.expenses,
    required this.balances,
    required this.debts,
    required this.settlementStatus,
    this.userProfiles = const {},
    this.expensesError,
    this.settlementsError,
  });
  final GroupDetail detail;
  final List<Expense> expenses;
  final List<BalanceResponse> balances;
  final List<DebtResponse> debts;
  final GroupSettlementStatus settlementStatus;
  final Map<String, UserProfile> userProfiles; // userId -> Profile cache

  /// Error de GET /groups/{id}/expenses. El grupo sigue mostrando su
  /// cabecera y miembros; solo la lista de gastos se reemplaza por un aviso.
  final Object? expensesError;

  /// Error de /settlements y /settlements/status. Cuando viene, `balances`,
  /// `debts` y `settlementStatus` están vacíos y el bloque de balances se
  /// reemplaza por un aviso.
  final Object? settlementsError;

  bool get hasExpenses => expensesError == null;
  bool get hasSettlements => settlementsError == null;
}

/// Group Details conectado a GET /groups/detail/{id}, GET /groups/{id}/expenses,
/// GET /groups/{id}/settlements (nombres + deudas), PATCH /groups/{id}
/// (renombrar, marcar como saldado/reabrir) y DELETE /groups/{id} (borrar).
/// Además gestiona miembros con POST /groups/{id}/members (alta por email o
/// user_id) y DELETE /groups/{id}/members/{user_id} (baja).
///
/// Tras cualquier alta o baja se llama a `_retry()`, que recarga las 4
/// llamadas de la pantalla. Eso no es sólo por el `detail`: `GroupMember`
/// no tiene nombre, y el nombre de cada miembro sale de `/balances`, así que
/// sin el refetch el invitado nuevo aparecería como "Member a3f1c2...".
///
/// Sin conectar, por falta de endpoint: el código/link de invitación para
/// compartir (la API no expone un código de grupo, sólo alta por
/// email/user_id) y el quick action "Summary".
class GroupDetails extends StatefulWidget {
  const GroupDetails({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  late Future<_GroupDetailsData> _future;
  String _categoryFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Solo `groupDetail` es imprescindible: sin él no hay grupo que mostrar.
  /// Gastos y settlements van en bloques separados a propósito, porque la
  /// API puede devolver 500 en cualquiera de los dos y la pantalla degrada
  /// mostrando el resto en vez de caer en un error genérico sin contexto.
  Future<_GroupDetailsData> _load() async {
    final detail = await GroupRepository.instance.groupDetail(widget.groupId);

    var expenses = <Expense>[];
    Object? expensesError;
    try {
      expenses = await ExpenseRepository.instance.listGroupExpenses(
        widget.groupId,
      );
    } catch (error) {
      expensesError = error;
    }

    var balances = <BalanceResponse>[];
    var debts = <DebtResponse>[];
    var settlementStatus = GroupSettlementStatus(
      groupId: widget.groupId,
      isSettled: true,
      pendingCount: 0,
      totalPendingAmount: '0',
      debts: const [],
    );
    var userProfiles = <String, UserProfile>{};
    Object? settlementsError;

    try {
      final settlements = await Future.wait([
        GroupRepository.instance.getSettlements(widget.groupId),
        GroupRepository.instance.getSettlementStatus(widget.groupId),
      ]);
      final bundle = settlements[0] as GroupDebtsBundle;
      balances = bundle.balances;
      debts = bundle.debts;
      settlementStatus = settlements[1] as GroupSettlementStatus;
      // Nombres de los miembros: GET /balances (vía /settlements) trae
      // {user_id, name} de cada uno — GET /users/{id} no existe en la API.
      userProfiles = {
        for (final b in balances)
          b.userId: UserProfile(userId: b.userId, name: b.name, email: ''),
      };
    } catch (error) {
      settlementsError = error;
    }

    return _GroupDetailsData(
      detail: detail,
      expenses: expenses,
      balances: balances,
      debts: debts,
      settlementStatus: settlementStatus,
      userProfiles: userProfiles,
      expensesError: expensesError,
      settlementsError: settlementsError,
    );
  }

  /// Al recargar, el override se descarta: el `groupDetail` fresco trae el
  /// status real del servidor y tiene prioridad sobre el valor local.
  void _retry() => setState(() {
        _statusOverride = null;
        _future = _load();
      });

  /// Override local del `status` del grupo.
  ///
  /// `PATCH /groups/{id}` no devuelve el grupo actualizado (su schema es
  /// `{group_name, status}` echoes, sin el resto), así que después de
  /// marcar como saldado no hay forma barata de tener el `GroupDetail`
  /// fresco sin recargar la pantalla entera — y recargar eso son 4
  /// pedidos (detail + expenses + settlements + status). Se guarda el
  /// valor nuevo acá y se usa en vez del del servidor hasta el próximo
  /// `_retry()`. null = usar el que vino en la respuesta.
  GroupStatus? _statusOverride;

  /// Persiste el nuevo status y lo refleja al toque, sin refetch.
  Future<void> _changeStatus(
    GroupDetail detail,
    GroupStatus status,
  ) async {
    if (status == detail.status) return;

    final previous = _statusOverride;
    setState(() => _statusOverride = status);
    try {
      await GroupRepository.instance.updateGroup(
        detail.groupId,
        status: status,
      );
    } catch (error) {
      // Se revierte al valor anterior: la UI no puede quedar mostrando un
      // estado que el backend rechazó.
      if (!mounted) return;
      setState(() => _statusOverride = previous);
      showApiError(context, error);
    }
  }

  Future<void> _showRenameDialog(GroupDetail detail) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _RenameGroupDialog(detail: detail),
    );

    if (saved == true && mounted) {
      _retry();
    }
  }

  /// Abre el bottom sheet de ajustes del grupo (estado settled/active).
  /// Se llama desde el engranaje del `AppCoverHeader`.
  void _showGroupSettings(BuildContext context, GroupDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: _GroupSettingsSheet(
          detail: detail,
          effectiveStatus: _statusOverride ?? detail.status,
          onStatusChanged: (status) async {
            final navigator = Navigator.of(sheetContext);
            await _changeStatus(detail, status);
            if (navigator.mounted) navigator.pop();
          },
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(GroupDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteGroupDialog(detail: detail),
    );

    if (confirmed == true && mounted) {
      _retry();
    }
  }

  /// Alta de miembro por email o user_id.
  ///
  /// Es la acción de dos entradas distintas: el quick action "Add member" y
  /// el botón `+` al final de la fila "Crew & Friends". Termina en `_retry()`
  /// porque el invitado entra al grupo recién en el `detail` del servidor, y
  /// además su nombre no existe hasta que `/balances` lo devuelva.
  Future<void> _showAddMemberDialog(GroupDetail detail) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => _AddMemberDialog(groupId: detail.groupId),
    );

    if (added == true && mounted) {
      _retry();
    }
  }

  /// Abre la hoja de miembros, desde donde se puede dar de baja a alguien.
  ///
  /// A diferencia del alta, acá no hace falta un `_retry()` explícito: cada
  /// baja devuelve `true` por el `Navigator.pop` y quien abrió la hoja la
  /// refresca una vez al cerrarse (ver `_MembersSheet.onMemberRemoved`).
  void _showMembersSheet(GroupDetail detail, Map<String, UserProfile> userProfiles) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _MembersSheet(
        groupId: detail.groupId,
        members: detail.members,
        userProfiles: userProfiles,
        isSelf: (userId) => userId == AuthSession.instance.userId,
        onMemberRemoved: () {
          if (mounted) _retry();
        },
      ),
    );
  }

  String _displayName(String userId, [Map<String, UserProfile>? userProfiles]) {
    // Buscar en cache de perfiles de usuario si fue proporcionado
    if (userProfiles != null) {
      final cached = userProfiles[userId];
      if (cached != null) {
        return cached.name;
      }
    }
    // Fallback: si es el usuario actual
    if (userId == AuthSession.instance.userId) {
      return AuthSession.instance.userName ?? 'Vos';
    }
    // Fallback final: placeholder con UUID
    return 'Miembro ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
  }

  String _initials(String userId, [Map<String, UserProfile>? userProfiles]) {
    // Buscar en cache de perfiles de usuario usando operador nulo-safe
    final cached = userProfiles?[userId];
    
    if (cached != null) {
      return cached.name.isNotEmpty ? cached.name.substring(0, 1).toUpperCase() : 'U';
    }
    // Si es el usuario actual
    if (userId == AuthSession.instance.userId) return 'Y';
    // Fallback: iniciales del UUID
    return userId.substring(0, 2).toUpperCase();
  }

  Future<void> _openAddExpense(BuildContext context) async {
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.logExpense,
      arguments: widget.groupId,
    );
    if (created == true) _retry();
  }

  @override
  Widget build(BuildContext context) {
    // Leído **antes** del Scaffold y con el `context` de este método, que
    // está por encima de él.
    //
    // Adentro del body no sirve ni `MediaQuery.paddingOf(context).top` ni
    // `viewPaddingOf(context).top`: Scaffold quita el padding superior del
    // body cuando hay appBar (`removeTopPadding: widget.appBar != null`), y
    // `MediaQueryData.removePadding` descuenta **también** de `viewPadding`,
    // así que los dos devuelven 0. El inset hay que leerlo de acá.
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppMd3Colors.background,
      // La imagen de portada llega hasta arriba del todo, detrás del reloj y
      // de la barra. Por eso la barra va transparente y la foto lleva un velo
      // (ver `AppCoverHeader.scrim`) para que el título y los íconos se lean.
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: 'Detalles del grupo',
        backgroundColor: Colors.transparent,
        leading: _GlassIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
        trailing: const AppAvatar(initials: 'AX', size: 36),
      ),
      body: FutureBuilder<_GroupDetailsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No pudimos cargar el grupo.',
                    style: AppTypography.bodyMd(
                      color: AppSemanticColors.slate600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Reintentar',
                    expand: false,
                    onPressed: _retry,
                  ),
                ],
              ),
            );
          }

final data = snapshot.data!;
// El status puede tener un override local si el usuario recién lo cambió
// (ver `_changeStatus`): la API no devuelve el grupo actualizado.
final detail = _statusOverride == null
    ? data.detail
    : GroupDetail(
        groupId: data.detail.groupId,
        groupName: data.detail.groupName,
        status: _statusOverride!,
        createdAt: data.detail.createdAt,
        members: data.detail.members,
      );
          final expenses = data.expenses;
          final myUserId = AuthSession.instance.userId;
          final memberCount = detail.members.length;
          final settlementStatus = data.settlementStatus;

          final totalSpending = expenses.fold<double>(
            0,
            (sum, e) => sum + e.totalAmount,
          );

          // Determinar estado del balance usando datos de la API.
          // Deuda = el DEBTOR le debe al CREDITOR: si soy debtor debo yo,
          // si soy creditor me deben a mí.
          String apiBalanceLabel;
          String? apiBalanceAmount;
          Color apiBalanceBackground;
          Color apiBalanceTextColor;

          if (myUserId != null) {
            final myDebts = data.debts
                .where((d) =>
                    isPendingStatus(d.status) && d.debtorUserId == myUserId)
                .toList();
            final myCredits = data.debts
                .where((d) =>
                    isPendingStatus(d.status) && d.creditorUserId == myUserId)
                .toList();

            if (myDebts.isNotEmpty) {
              final totalOwedByMe = myDebts.fold<double>(
                0,
                (sum, d) => sum + double.parse(d.amount),
              );
              apiBalanceLabel = 'Debes';
              apiBalanceAmount = '\$${totalOwedByMe.toStringAsFixed(2)}';
              apiBalanceBackground = AppSemanticColors.negativeContainer;
              apiBalanceTextColor = AppSemanticColors.negativeText;
            } else if (myCredits.isNotEmpty) {
              final totalOwedToMe = myCredits.fold<double>(
                0,
                (sum, d) => sum + double.parse(d.amount),
              );
              apiBalanceLabel = 'Te deben';
              apiBalanceAmount = '\$${totalOwedToMe.toStringAsFixed(2)}';
              apiBalanceBackground = AppSemanticColors.positiveContainer;
              apiBalanceTextColor = AppSemanticColors.positiveText;
            } else {
              apiBalanceLabel = 'Todo saldado';
              apiBalanceBackground = AppSemanticColors.positiveContainer;
              apiBalanceTextColor = AppSemanticColors.positiveText;
            }
          } else {
            apiBalanceLabel = 'Todo saldado';
            apiBalanceBackground = AppSemanticColors.positiveContainer;
            apiBalanceTextColor = AppSemanticColors.positiveText;
          }

          final categories = <String>{
            'Todos',
            ...expenses.map((e) => e.expenseCategory),
          }.toList();
          final filtered = _categoryFilter == 'Todos'
              ? expenses
              : expenses
                  .where((e) => e.expenseCategory == _categoryFilter)
                  .toList();
          final sorted = [...filtered]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                    AppCoverHeader(
                      imageUrl:
                          'https://picsum.photos/seed/${widget.groupId}/800/400',
                      // La imagen ahora arranca en y=0, detrás de la barra.
                      // Se le suma el alto de la barra + inset para que el
                      // área visible de foto sea la misma que antes, en vez de
                      // comerse los ~80px de arriba.
                      height: 180 + topInset + AppTopBar.contentHeight,
                      floatingActionTop: topInset + AppTopBar.contentHeight,
                      // A sangre contra el borde superior: redondear sólo
                      // abajo, o queda una franja del color del fondo.
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.md),
                      ),
                      scrim: true,
                      floatingAction: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: AppSemanticColors.slate900,
                            size: 20,
                          ),
                          onPressed: () => _showGroupSettings(context, detail),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppEditableTitle(
                      title: detail.groupName,
                      onEdit: () => _showRenameDialog(detail),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Creado el ${formatShortDate(detail.createdAt)} · $memberCount miembro${memberCount == 1 ? '' : 's'}',
                      style: AppTypography.bodySm(
                        color: AppSemanticColors.slate600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppStatCard(
                      label: 'Gasto total del grupo',
                      value: '\$${totalSpending.toStringAsFixed(2)}',
                      icon: const Icon(
                        Icons.receipt_long,
                        color: AppMd3Colors.primaryContainer,
                        size: 20,
                      ),
                      iconBackground: AppSemanticColors.slate100,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Bloque de settlements. Si esas llamadas fallaron
                    // (la API viene devolviendo 500 en /settlements), se
                    // muestra el aviso y el resto de la pantalla sigue
                    // viva en vez de caer en la pantalla de error general.
                    if (!data.hasSettlements)
                      _SettlementsUnavailableNotice(
                        error: data.settlementsError!,
                        onRetry: _retry,
                      )
                    else ...[
                      const SizedBox(height: AppSpacing.sm),

                      // Balance state from API settlement data
                      if (myUserId == null)
                        const AppInfoBanner(
                          icon: Icon(
                            Icons.help_outline,
                            color: AppSemanticColors.slate400,
                          ),
                          title: 'Balance no disponible',
                          description: 'No hay sesión activa para mostrar el balance.',
                          background: AppSemanticColors.slate100,
                        )
                      else if (apiBalanceAmount != null)
                        _BalanceBanner(
                          label: apiBalanceLabel,
                          amount: apiBalanceAmount,
                          background: apiBalanceBackground,
                          textColor: apiBalanceTextColor,
                        )
                      else
                        AppInfoBanner(
                          icon: const Icon(
                            Icons.check_circle,
                            color: AppSemanticColors.positiveText,
                          ),
                          title: apiBalanceLabel,
                          description: 'No hay saldos pendientes en este grupo.',
                          background: apiBalanceBackground,
                        ),
                      const SizedBox(height: AppSpacing.sm),

                      // Settlement status badge
                      _SettlementStatusBadge(settlementStatus: settlementStatus),

                      // Debt list visualization (bundle de /settlements, que
                      // siempre trae la lista; settlementStatus.debts puede
                      // venir vacío por default en el schema)
                      if (myUserId != null && data.debts.isNotEmpty)
                        _DebtListViewer(debts: data.debts)
                      else
                        Text(
                          'No hay deudas.',
                          style: AppTypography.bodyMd(
                            color: AppSemanticColors.slate600,
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.sm),

                    // "Manage" abre la hoja de miembros (donde se dan de
                    // baja); el "+" del final de la fila da de alta. Son
                    // acciones distintas porque `POST` y `DELETE` son
                    // endpoints distintos.
                    Row(
                      children: [
                        Text(
                          'Amigos y grupo',
                          style: AppTypography.titleMd(
                            color: AppSemanticColors.slate900,
                          ),
                        ),
                        const Spacer(),
                        AppTextAction(
                          label: 'Gestionar',
                          onPressed: () =>
                              _showMembersSheet(detail, data.userProfiles),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final member in detail.members) ...[
                            MemberChip(
                              avatar: AppAvatar(
                                initials: _initials(member.userId, data.userProfiles),
                                size: 24,
                              ),
                              name: _displayName(member.userId, data.userProfiles),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          InkWell(
                            onTap: () => _showAddMemberDialog(detail),
                            borderRadius: AppRadius.mdRadius,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: AppSemanticColors.slate400,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Agregar',
                                    style: AppTypography.bodySm(
                                      color: AppSemanticColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      children: [
                        Expanded(
                          child: AppQuickActionTile(
                            icon: const Icon(
                              Icons.person_add,
                              color: AppMd3Colors.primaryContainer,
                              size: 20,
                            ),
                            iconBackground: AppMd3Colors.surfaceContainer,
                            label: 'Agregar miembro',
                            onTap: () => _showAddMemberDialog(detail),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppQuickActionTile(
                            icon: const Icon(
                              Icons.account_balance,
                              color: AppSemanticColors.positiveText,
                              size: 20,
                            ),
                            iconBackground: AppSemanticColors.positiveContainer,
                            label: 'Saldos',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.balances,
                              arguments: widget.groupId,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppQuickActionTile(
                            icon: const Icon(
                              Icons.delete,
                              color: AppSemanticColors.negativeText,
                              size: 20,
                            ),
                            iconBackground: AppSemanticColors.negativeContainer,
                            label: 'Eliminar grupo',
                            onTap: () => _showDeleteDialog(detail),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (!data.hasExpenses) ...[
                      SectionHeader(
                        title: 'Gastos recientes',
                        trailing: AppTextAction(
                          label: 'Reintentar',
                          emphasized: true,
                          onPressed: _retry,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SettlementsUnavailableNotice(
                        error: data.expensesError!,
                        onRetry: _retry,
                        title: 'Gastos no disponibles',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ] else ...[
                      SectionHeader(
                        title: 'Gastos recientes',
                        trailing: Text(
                          '${expenses.length} total',
                          style: AppTypography.bodySm(
                            color: AppSemanticColors.slate400,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final category in categories) ...[
                              AppFilterChip(
                                // La comparación y el `dotColor` usan el
                                // string crudo de la API a propósito; sólo
                                // lo que se muestra pasa por el mapeo.
                                label: category == 'Todos'
                                    ? 'Todos'
                                    : categoryDisplayLabel(category),
                                selected: _categoryFilter == category,
                                dotColor: category == 'Todos'
                                    ? null
                                    : categoryVisual(category).$3,
                                onTap: () => setState(
                                  () => _categoryFilter = category,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (sorted.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            'Todavía no hay gastos.',
                            style: AppTypography.bodyMd(
                              color: AppSemanticColors.slate600,
                            ),
                          ),
                        )
                      else
                        for (final expense in sorted) ...[
                          _buildExpenseRow(
                            context,
                            expense,
                            myUserId,
                            memberCount,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                    ],
                    // Holgura para que la última fila de gastos pueda
                    // scrollear por detrás del botón "Agregar gasto". Crece
                    // con el inset porque el botón también subió.
                    SizedBox(height: 80 + bottomInset),
                  ],
                ),
              ),
              Positioned(
                right: AppSpacing.marginMobile,
                // Esta pantalla no tiene `bottomNavigationBar`, así que el
                // body del Scaffold llega hasta el borde inferior de la
                // pantalla. Sin sumar el inset, el botón queda debajo de la
                // barra de navegación de Android.
                //
                // Ojo: en `home.dart` el mismo botón NO lleva este inset,
                // porque ahí el body se layoutea por encima de
                // `AppBottomNavBar` y su `padding.bottom` ya viene en 0 —
                // sumarlo sería doble padding.
                bottom: AppSpacing.md + bottomInset,
                child: AppButton(
                  label: 'Agregar gasto',
                  leadingIcon: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                  expand: false,
                  onPressed: () => _openAddExpense(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseRow(
    BuildContext context,
    Expense expense,
    String? myUserId,
    int memberCount,
  ) {
    final (icon, iconBg, _) = categoryVisual(expense.expenseCategory);

    var status = ExpenseRowStatus.neutral;
    var statusLabel = '';
    if (myUserId != null) {
      final net = myNetForExpense(expense, myUserId, memberCount);
      if (net > 0.005) {
        status = ExpenseRowStatus.owed;
        statusLabel = '+\$${net.toStringAsFixed(2)} para vos';
      } else if (net < -0.005) {
        status = ExpenseRowStatus.owe;
        statusLabel = 'Debés \$${net.abs().toStringAsFixed(2)}';
      } else {
        statusLabel = 'Saldado';
      }
    }

    return ExpenseListRow(
      icon: Icon(
        icon,
        size: 20,
        color: categoryVisual(expense.expenseCategory).$3,
      ),
      iconBackground: iconBg,
      title: expense.title,
      metaText:
          'Pagó ${_displayName(expense.payerUserId)} · ${splitTypeLabel(expense.splitType)}',
      timeLabel: formatShortDate(expense.createdAt),
      totalAmountLabel: '\$${expense.totalAmount.toStringAsFixed(2)}',
      statusLabel: statusLabel,
      status: status,
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.expenseDetails,
          arguments: expense.expenseId,
        );
      },
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({
    required this.label,
    required this.amount,
    required this.background,
    required this.textColor,
  });

  final String label;
  final String amount;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return AppInfoBanner(
      icon: const Icon(
        Icons.trending_up,
        color: AppSemanticColors.positiveText,
      ),
      title: '$label $amount',
      description: 'Basado en los saldos de la API',
      background: background,
    );
  }
}

/// Alta de miembro: POST /groups/{id}/members}.
///
/// El endpoint acepta `email` **o** `user_id`, así que el selector de arriba
/// decide cuál de los dos se manda. No se mandan ambos: el schema los declara
/// opcionales, y mandarle la clave del que no se usó como `null` haría que el
/// backend lo tomara como un valor explícito (mismo criterio que
/// `updateGroup` en el repositorio).
///
/// El error se muestra acá adentro y no en un SnackBar, igual que
/// `_RenameGroupDialog`: el mensaje del backend ("ese email no está
/// registrado", "ya es miembro") es el dato útil, y un SnackBar detrás del
/// diálogo queda tapado.
class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.groupId});

  final String groupId;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  late final TextEditingController _controller;
  bool _byEmail = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = _byEmail
          ? 'Escribe el email de la persona que quieres sumar.'
          : 'Escribe el user_id de la persona que quieres sumar.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await GroupRepository.instance.addMember(
        widget.groupId,
        email: _byEmail ? value : null,
        userId: _byEmail ? null : value,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
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
      title: const Text('Agregar miembro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El backend no trae código de invitación, así que "invitar" es
          // literalmente dar de alta a alguien por email o user_id.
          Row(
            children: [
              _ModeChip(
                label: 'Email',
                selected: _byEmail,
                onTap: _isSubmitting
                    ? null
                    : () => setState(() {
                          _byEmail = true;
                          _error = null;
                        }),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ModeChip(
                label: 'User ID',
                selected: !_byEmail,
                onTap: _isSubmitting
                    ? null
                    : () => setState(() {
                          _byEmail = false;
                          _error = null;
                        }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: _byEmail ? 'Email' : 'User ID',
            controller: _controller,
            prefixIcon: Icon(
              _byEmail ? Icons.mail_outline : Icons.badge_outlined,
              size: 20,
            ),
            keyboardType: _byEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySm(
                color: AppSemanticColors.negativeText,
              ),
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
          onPressed: _isSubmitting ? null : _handleAdd,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Agregar'),
        ),
      ],
    );
  }
}

/// Selector email / user_id del diálogo de alta. No reutiliza `AppFilterChip`
/// porque ese es un chip de filtro con punto de color pensado para categorías
/// de gasto, no para un toggle de dos opciones excluyentes.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppMd3Colors.primaryContainer
              : AppSemanticColors.slate100,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Text(
          label,
          style: AppTypography.bodySm(
            color: selected
                ? Colors.white
                : AppSemanticColors.slate600,
          ),
        ),
      ),
    );
  }
}

/// Hoja de miembros: lista el grupo y permite dar de baja a alguien.
///
/// Recibe `members` del `GroupDetail` (que ya vino en el `GET /detail`) en
/// lugar de llamar por su cuenta a `GET /members`: `GroupMemberResponse` sólo
/// trae `user_id` y `joined_at`, o sea exactamente lo que ya tiene el detail,
/// así que una llamada extra no aportaría nada.
///
/// La baja se pide sin diálogo de confirmación: el backend ya es la fuente de
/// verdad y rechaza (400/409) si el usuario arrastra gastos o deudas
/// pendientes. El error se muestra con `showApiError` para que se vea el
/// motivo real en vez de asumir que la baja entró.
class _MembersSheet extends StatefulWidget {
  const _MembersSheet({
    required this.groupId,
    required this.members,
    required this.userProfiles,
    required this.isSelf,
    required this.onMemberRemoved,
  });

  final String groupId;
  final List<GroupMember> members;

  /// userId -> nombre, armado desde `/balances` (`GroupMember` no trae nombre).
  final Map<String, UserProfile> userProfiles;
  final bool Function(String userId) isSelf;
  final VoidCallback onMemberRemoved;

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  /// Copia local de la lista, y no `widget.members` directo.
  ///
  /// `showModalBottomSheet` arma una ruta nueva, así que la hoja NO se
  /// reconstruye cuando la pantalla de atrás refresca sus datos: sin esta
  /// copia, el miembro dado de baja seguiría apareciendo en la lista hasta
  /// que se cerrara la hoja.
  late List<GroupMember> _members;

  /// userIds con una baja en vuelo, para bloquear sólo esa fila y no toda la
  /// hoja: dar de baja a dos personas a la vez sigue teniendo sentido.
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _members = [...widget.members];
  }

  Future<void> _remove(GroupMember member) async {
    setState(() => _removing.add(member.userId));
    try {
      await GroupRepository.instance.removeMember(
        widget.groupId,
        member.userId,
      );
      if (!mounted) return;
      final name = _nameFor(member.userId);
      setState(() {
        _removing.remove(member.userId);
        _members = _members.where((m) => m.userId != member.userId).toList();
      });
      // Refresca la pantalla de atrás (conteos, balances, nombre del
      // invitado). La hoja ya se actualizó sola con lo de arriba.
      widget.onMemberRemoved();
      // Confirmación de éxito con `ScaffoldMessenger` directo y no con
      // `showApiError`: ese helper traduce *todo* `ApiException(0, ...)` a
      // "No se pudo conectar con el servidor", así que un código 0 usado
      // como mensaje de éxito se mostraría como un problema de red.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _removing.remove(member.userId));
      showApiError(context, error);
    }
  }

  /// Nombre a mostrar para un user_id del grupo.
  ///
  /// Sale de `/balances` (`userProfiles`); si no está —típico justo después
  /// de un alta, antes de que `/balances` lo incluya— se cae al nombre del
  /// usuario actual o a un placeholder con los primeros caracteres del UUID,
  /// que es el mismo fallback que usa `_displayName` en la pantalla.
  String _nameFor(String userId) {
    final cached = widget.userProfiles[userId]?.name;
    if (cached != null && cached.isNotEmpty) return cached;
    if (widget.isSelf(userId)) return AuthSession.instance.userName ?? 'Vos';
    return 'Miembro ${userId.substring(0, userId.length >= 8 ? 8 : userId.length)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Miembros',
              style: AppTypography.titleMd(color: AppSemanticColors.slate900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_members.length} '
              '${_members.length == 1 ? 'persona' : 'personas'} en este grupo',
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_members.isEmpty)
              Text(
                'Este grupo todavía no tiene miembros.',
                style: AppTypography.bodySm(color: AppSemanticColors.slate600),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isSelf = widget.isSelf(member.userId);
                    final name = _nameFor(member.userId);
                    final isRemoving = _removing.contains(member.userId);

                    return Row(
                      children: [
                        AppAvatar(
                          initials: isSelf
                              ? 'Y'
                              : member.userId
                                  .substring(0, 2)
                                  .toUpperCase(),
                          size: 36,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSelf ? '$name (you)' : name,
                                style: AppTypography.bodyMd(
                                  color: AppSemanticColors.slate900,
                                ),
                              ),
                              Text(
                                'Se unió el ${formatShortDate(member.joinedAt)}',
                                style: AppTypography.bodySm(
                                  color: AppSemanticColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sacarse a uno mismo del grupo no es una operación
                        // que el endpoint soporte bien, así que el botón se
                        // oculta en vez de dejar que el backend lo rechace.
                        if (!isSelf)
                          isRemoving
                              ? const Padding(
                                  padding: EdgeInsets.all(AppSpacing.sm),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Quitar del grupo',
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    color: AppSemanticColors.negativeText,
                                    size: 20,
                                  ),
                                  onPressed: () => _remove(member),
                                ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de ajustes del grupo.
///
/// Por ahora sólo el estado `active`/`settled` — es lo único que
/// `PATCH /groups/{id}` además del nombre. Renombrar y borrar ya tienen su
/// propio lugar en la pantalla (el título editable y el quick action).
class _GroupSettingsSheet extends StatelessWidget {
  const _GroupSettingsSheet({
    required this.detail,
    required this.effectiveStatus,
    required this.onStatusChanged,
  });

  final GroupDetail detail;

  /// Status a mostrar: el del servidor, o el override local si recién se
  /// cambió (ver `_changeStatus`).
  final GroupStatus effectiveStatus;
  final Future<void> Function(GroupStatus status) onStatusChanged;

  bool get _isSettled => effectiveStatus == GroupStatus.settled;

  @override
  Widget build(BuildContext context) {
    final target = _isSettled ? GroupStatus.active : GroupStatus.settled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajustes del grupo',
            style: AppTypography.titleMd(color: AppSemanticColors.slate900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail.groupName,
            style: AppTypography.bodySm(color: AppSemanticColors.slate600),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Estado actual + acción para alternarlo.
          AppSettingsRow(
            icon: Icon(
              _isSettled ? Icons.check_circle : Icons.pending_actions,
              color: AppSemanticColors.slate900,
              size: 20,
            ),
            label: _isSettled ? 'Saldado' : 'Activo',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSettled ? 'Reabrir' : 'Marcar como saldado',
                  style: AppTypography.bodySm(
                    color: AppMd3Colors.primaryContainer,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppSemanticColors.slate400,
                ),
              ],
            ),
            onTap: () => onStatusChanged(target),
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            _isSettled
                ? 'Marca este grupo como saldado. Los grupos saldados siguen '
                    'abiertos como referencia pero dejan de contar como pendientes.'
                : 'Marca como saldada toda deuda pendiente de este grupo.',
            style: AppTypography.bodySm(color: AppSemanticColors.slate600),
          ),
        ],
      ),
    );
  }
}

class _DeleteGroupDialog extends StatefulWidget {
  const _DeleteGroupDialog({required this.detail});

  final GroupDetail detail;

  @override
  State<_DeleteGroupDialog> createState() => _DeleteGroupDialogState();
}

class _DeleteGroupDialogState extends State<_DeleteGroupDialog> {
  late final TextEditingController _nameController;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.detail.groupName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await GroupRepository.instance.deleteGroup(widget.detail.groupId);
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
      title: const Text('Eliminar grupo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Estás seguro de que quieres eliminar el grupo "${widget.detail.groupName}"?',
            style: AppTypography.bodySm(
              color: AppSemanticColors.slate600,
            ),
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
          onPressed: _isSubmitting ? null : _handleDelete,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eliminar'),
        ),
      ],
    );
  }
}

class _RenameGroupDialog extends StatefulWidget {
  const _RenameGroupDialog({required this.detail});

  final GroupDetail detail;

  @override
  State<_RenameGroupDialog> createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends State<_RenameGroupDialog> {
  late final TextEditingController _nameController;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.detail.groupName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty || newName == widget.detail.groupName) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await GroupRepository.instance.updateGroupName(widget.detail.groupId, newName);
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
      title: const Text('Renombrar grupo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Nombre del grupo',
            controller: _nameController,
            prefixIcon: const Icon(Icons.edit),
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
          onPressed: _isSubmitting ? null : _handleSave,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Aviso de un bloque de la pantalla que no se pudo cargar. El mensaje sale
/// de `apiErrorMessage` para no mentir: un 500 del backend no es lo mismo que
/// "no se pudo conectar".
class _SettlementsUnavailableNotice extends StatelessWidget {
  const _SettlementsUnavailableNotice({
    required this.error,
    required this.onRetry,
    this.title = 'Saldos no disponibles',
  });

  final Object error;
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppInfoBanner(
      icon: const Icon(
        Icons.cloud_off,
        color: AppSemanticColors.slate400,
        size: 20,
      ),
      title: title,
      description: apiErrorMessage(error),
      background: AppSemanticColors.slate100,
      trailing: AppTextAction(
        label: 'Reintentar',
        emphasized: true,
        onPressed: onRetry,
      ),
    );
  }
}

class _SettlementStatusBadge extends StatelessWidget {
  const _SettlementStatusBadge({
    required this.settlementStatus,
  });

  final GroupSettlementStatus settlementStatus;

  @override
  Widget build(BuildContext context) {
    final isSettled = settlementStatus.isSettled;
    final pendingCount = settlementStatus.pendingCount;
    final totalPendingAmount = settlementStatus.totalPendingAmount;

    // Use positive colors for settled, warning colors for pending
    final Color backgroundColor = isSettled
        ? AppSemanticColors.positiveContainer
        : AppSemanticColors.negativeContainer;
    final Color textColor = isSettled
        ? AppSemanticColors.positiveText
        : AppSemanticColors.negativeText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSettled ? Icons.check_circle : Icons.remove,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isSettled
              ? 'Todo saldado'
              : '$pendingCount pendiente${pendingCount == 1 ? '' : 's'}',
            style: AppTypography.bodySm(
              color: textColor,
            ),
          ),
          if (totalPendingAmount.isNotEmpty)
            Text(
              ' \$$totalPendingAmount',
              style: AppTypography.bodySm(
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _DebtListViewer extends StatelessWidget {
  const _DebtListViewer({
    required this.debts,
  });

  final List<DebtResponse> debts;

  @override
  Widget build(BuildContext context) {
    final myUserId = AuthSession.instance.userId;
    // Deuda = el DEBTOR le debe al CREDITOR. Si soy debtor, debo yo;
    // si soy creditor, me deben a mí. Saldado (PAID) o cancelado ya no
    // está pendiente — ver `isPendingStatus`.
    final owe = debts
        .where((d) => isPendingStatus(d.status) && d.debtorUserId == myUserId)
        .toList();
    final owed = debts
        .where((d) => isPendingStatus(d.status) && d.creditorUserId == myUserId)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (owe.isEmpty && owed.isEmpty)
              Text(
                'No hay deudas pendientes.',
                style: AppTypography.bodySm(color: AppSemanticColors.slate600),
              ),
            if (owe.isNotEmpty)
              _debtSection(
                context: context,
                label: 'Debes',
                items: owe,
                icon: Icons.arrow_upward,
                color: AppSemanticColors.negativeText,
              ),
            if (owed.isNotEmpty)
              _debtSection(
                context: context,
                label: 'Te deben',
                items: owed,
                icon: Icons.arrow_downward,
                color: AppSemanticColors.positiveText,
              ),
          ],
        ),
      ),
    );
  }

  Widget _debtSection({
    required BuildContext context,
    required String label,
    required List<DebtResponse> items,
    required IconData icon,
    required Color color,
  }) {
    final total = items.fold<double>(0, (s, d) => s + double.parse(d.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySm(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              '${items.length} ${items.length == 1 ? 'deuda' : 'deudas'}',
              style: AppTypography.bodySm(color: AppSemanticColors.slate600),
            ),
            const Spacer(),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: AppTypography.bodySm(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((debt) => _DebtTile(
              debtorName: debt.debtorName,
              creditorName: debt.creditorName,
              amount: debt.amount,
              status: debt.status,
            )),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debtorName,
    required this.creditorName,
    required this.amount,
    required this.status,
  });

  final String debtorName;
  final String creditorName;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(debtorName.isNotEmpty ? debtorName[0].toUpperCase() : '?'),
      ),
      title: Text(debtorName),
      subtitle: Text(creditorName),
      trailing: Text(amount),
      onTap: () {
        // Navigate to debt details or show expense breakdown
      },
    );
  }
}
