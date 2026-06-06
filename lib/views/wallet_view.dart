import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/transaction_model.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../viewmodels/market_viewmodel.dart';
import 'login_view.dart' show Validators;

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(
      children: [
        const _WalletHeader(),
        Expanded(
          child: Consumer<FinanceViewModel>(
            builder: (context, financeVM, _) {
              if (financeVM.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final transactions = financeVM.recentTransactions;

              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: _MarketIndicatorsSection(),
                  ),
                  if (transactions.isEmpty)
                    const SliverFillRemaining(
                      child: _EmptyWallet(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      sliver: SliverList.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return _TransactionManageTile(
                            transaction: transaction,
                            currency: currency,
                            onEdit: () => _showEditTransactionSheet(
                              context,
                              transaction,
                            ),
                            onDelete: () => _confirmDelete(
                              context,
                              transaction,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final id = transaction.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir transação'),
          content: Text('Deseja excluir "${transaction.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: AppColors.expense),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<FinanceViewModel>().removeTransaction(id);
    }
  }

  void _showEditTransactionSheet(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final titleController =
        TextEditingController(text: transaction.description);
    final amountController = TextEditingController(
      text: transaction.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    final formKey = GlobalKey<FormState>();
    final dateFormat = DateFormat('dd/MM/yyyy');
    TransactionType selectedType = transaction.type;
    String selectedCategory = transaction.category;
    DateTime selectedDate = transaction.date;

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

    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Outros';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar transação',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeChip(
                              label: 'Receita',
                              selected: selectedType == TransactionType.receita,
                              color: AppColors.income,
                              onTap: () => setSheetState(
                                () => selectedType = TransactionType.receita,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeChip(
                              label: 'Despesa',
                              selected: selectedType == TransactionType.despesa,
                              color: AppColors.expense,
                              onTap: () => setSheetState(
                                () => selectedType = TransactionType.despesa,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _EditTextField(
                        controller: titleController,
                        hint: 'Título',
                        validator: Validators.requiredText,
                      ),
                      const SizedBox(height: 12),
                      _EditTextField(
                        controller: amountController,
                        hint: 'Valor (R\$)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: Validators.money,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: _DateBox(label: dateFormat.format(selectedDate)),
                      ),
                      const SizedBox(height: 12),
                      _CategoryDropdown(
                        value: selectedCategory,
                        categories: categories,
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final amount =
                                Validators.parseMoney(amountController.text) ??
                                    0;
                            final updated = transaction.copyWith(
                              description: titleController.text.trim(),
                              amount: amount,
                              type: selectedType,
                              category: selectedCategory,
                              date: selectedDate,
                            );

                            final saved = await context
                                .read<FinanceViewModel>()
                                .updateTransaction(updated);
                            if (saved && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Salvar alterações',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
        );
      },
    );
  }
}

class _MarketIndicatorsSection extends StatelessWidget {
  const _MarketIndicatorsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketViewModel>(
      builder: (context, marketVM, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Indicadores do Mercado',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dados em tempo real - BrasilAPI',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => context.read<MarketViewModel>().reload(),
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: AppColors.mutedIcon(context),
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Atualizar',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (marketVM.isLoading)
                  const _MarketSkeleton()
                else if (marketVM.errorMessage != null)
                  _MarketError(
                    message: marketVM.errorMessage!,
                    onRetry: () => context.read<MarketViewModel>().reload(),
                  )
                else if (marketVM.indicators.isEmpty)
                  const SizedBox.shrink()
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: marketVM.indicators.take(3).map((indicator) {
                      final visibleIndicators = marketVM.indicators.take(3);
                      final isLast = indicator == visibleIndicators.last;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 8),
                          child: _MarketCard(indicator: indicator),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MarketCard extends StatelessWidget {
  final dynamic indicator;

  const _MarketCard({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final isUp = indicator.value >= 0;
    final trendColor = isUp ? AppColors.primaryGreen : AppColors.expense;
    final trendIcon =
        isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.field(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  trendColor.withValues(alpha: 0.15),
                  trendColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(trendIcon, color: trendColor, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            indicator.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${indicator.value.toStringAsFixed(2)}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: trendColor,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: trendColor,
              ),
              const SizedBox(width: 2),
              Text(
                isUp ? 'Alta' : 'Baixa',
                style: TextStyle(
                  fontSize: 10,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketSkeleton extends StatelessWidget {
  const _MarketSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
              decoration: BoxDecoration(
                color: AppColors.field(context),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MarketError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MarketError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: AppColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Tentar novamente',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface(context),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText(context),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border(context)),
        ],
      ),
    );
  }
}

class _TransactionManageTile extends StatelessWidget {
  const _TransactionManageTile({
    required this.transaction,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.receita;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final date = DateFormat('dd/MM/yyyy').format(transaction.date);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${transaction.category} - $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.expense,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryGreen,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhuma transação cadastrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use o botão central de adicionar para registrar receitas e despesas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditTextField extends StatelessWidget {
  const _EditTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  final String value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: categories
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
