import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/transaction_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/finance_viewmodel.dart';
import 'dashboard_view.dart';
import 'login_view.dart' show Validators;
import 'profile_view.dart';
import 'reports_view.dart';
import 'wallet_view.dart';

class _CurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final cents = int.tryParse(digits) ?? 0;
    final intPart = cents ~/ 100;
    final decPart = cents % 100;

    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    ).format(intPart + decPart / 100.0);

    final trimmed = formatted.trim();
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  bool _isAddSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUserId;
      if (userId != null) {
        context.read<FinanceViewModel>().loadTransactions(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onViewAllTransactions: () => setState(() => _currentIndex = 1),
      ),
      const ReportsPage(),
      const WalletPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          elevation: 10,
          color: AppColors.surface(context),
          surfaceTintColor: AppColors.surface(context),
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0,
                  current: _currentIndex,
                  inactiveIcon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Início',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  index: 1,
                  current: _currentIndex,
                  inactiveIcon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Relatórios',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _AddNavButton(onTap: () => _showAddTransactionSheet(context)),
                _NavItem(
                  index: 2,
                  current: _currentIndex,
                  inactiveIcon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Carteira',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  index: 3,
                  current: _currentIndex,
                  inactiveIcon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Perfil',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    if (_isAddSheetOpen) return;
    _isAddSheetOpen = true;

    final descController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final dateFormat = DateFormat('dd/MM/yyyy');
    TransactionType selectedType = TransactionType.despesa;
    DateTime selectedDate = DateTime.now();
    String selectedCategory = 'Alimentação';

    bool isSaving = false;

    const categories = [
      'Alimentação',
      'Transporte',
      'Assinaturas',
      'Lazer',
      'Saúde',
      'Moradia',
      'Salário',
      'Freelance',
      'Outros',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isReceita = selectedType == TransactionType.receita;
          final typeColor =
              isReceita ? AppColors.primaryGreen : AppColors.expense;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.field(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            _SheetTypeTab(
                              label: 'Receita',
                              icon: Icons.arrow_downward_rounded,
                              selected: isReceita,
                              color: AppColors.primaryGreen,
                              onTap: () => setSheetState(
                                () => selectedType = TransactionType.receita,
                              ),
                            ),
                            _SheetTypeTab(
                              label: 'Despesa',
                              icon: Icons.arrow_upward_rounded,
                              selected: !isReceita,
                              color: AppColors.expense,
                              onTap: () => setSheetState(
                                () => selectedType = TransactionType.despesa,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                            child: const Text('R\$'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_CurrencyFormatter()],
                              validator: Validators.money,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText(context),
                              ),
                              decoration: InputDecoration(
                                hintText: '0,00',
                                hintStyle: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.border(context),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                errorStyle: const TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Divider(
                        color: AppColors.border(context),
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        controller: descController,
                        validator: Validators.requiredText,
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Descrição',
                          hintStyle: TextStyle(
                            color: AppColors.secondaryText(context),
                          ),
                          prefixIcon: Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.mutedIcon(context),
                            size: 22,
                          ),
                          filled: true,
                          fillColor: AppColors.field(context),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: AppColors.border(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: AppColors.border(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: typeColor, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.expense, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.expense, width: 1.5),
                          ),
                          errorStyle: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final name = categories[i];
                          final isSelected = selectedCategory == name;
                          return GestureDetector(
                            onTap: () => setSheetState(
                              () => selectedCategory = name,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? typeColor
                                    : AppColors.field(context),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                      ? typeColor
                                      : AppColors.border(context),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.secondaryText(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setSheetState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.field(context),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppColors.border(context)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: AppColors.mutedIcon(context),
                                  size: 18),
                              const SizedBox(width: 10),
                              Text(
                                dateFormat.format(selectedDate),
                                style: TextStyle(
                                    color: AppColors.primaryText(context),
                                    fontSize: 14),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right,
                                  color: AppColors.border(context), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isSaving) return;
                            if (!formKey.currentState!.validate()) return;
                            final desc = descController.text.trim();
                            final amount =
                                Validators.parseMoney(amountController.text) ??
                                    0;
                            if (desc.isEmpty || amount <= 0) return;
                            setSheetState(() => isSaving = true);
                            final fallbackUserId =
                                context.read<AuthViewModel>().currentUserId;
                            try {
                              final saved = await context
                                  .read<FinanceViewModel>()
                                  .addTransaction(
                                    description: desc,
                                    amount: amount,
                                    type: selectedType,
                                    category: selectedCategory,
                                    date: selectedDate,
                                    userId: fallbackUserId,
                                  );
                              if (saved && ctx.mounted) {
                                Navigator.pop(ctx);
                              } else if (!saved && ctx.mounted) {
                                setSheetState(() => isSaving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Erro ao salvar. Tente novamente.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (_) {
                              if (ctx.mounted) {
                                setSheetState(() => isSaving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Erro ao salvar. Tente novamente.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeColor,
                            shadowColor: typeColor.withValues(alpha: 0.35),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            surfaceTintColor: typeColor,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isReceita
                                      ? 'Adicionar Receita'
                                      : 'Adicionar Despesa',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _isAddSheetOpen = false;
      descController.dispose();
      amountController.dispose();
    });
  }
}

class _AddNavButton extends StatelessWidget {
  const _AddNavButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Adicionar transação',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.current,
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int current;
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = current == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? AppColors.primaryGreen : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? AppColors.primaryGreen : Colors.grey,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTypeTab extends StatelessWidget {
  const _SheetTypeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color:
                    selected ? Colors.white : AppColors.secondaryText(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
