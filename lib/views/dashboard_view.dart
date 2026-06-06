import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../models/transaction_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.onViewAllTransactions,
  });

  final VoidCallback? onViewAllTransactions;

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Consumer2<AuthViewModel, FinanceViewModel>(
      builder: (context, authVM, financeVM, _) {
        return Column(
          children: [
            _DashHeader(authVM: authVM, financeVM: financeVM),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricsRow(
                        financeVM: financeVM, currencyFormat: currencyFormat),
                    const SizedBox(height: 24),
                    _EvolutionChart(financeVM: financeVM),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Últimas transações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: onViewAllTransactions,
                          child: const Text(
                            'Ver todas',
                            style: TextStyle(
                                color: AppColors.primaryGreen, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...financeVM.recentTransactions.take(3).map(
                          (t) => _TransactionTile(
                              t: t, currencyFormat: currencyFormat),
                        ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashHeader extends StatelessWidget {
  final AuthViewModel authVM;
  final FinanceViewModel financeVM;

  const _DashHeader({required this.authVM, required this.financeVM});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final profileBytes = authVM.profileImageBytes;

    return Container(
      color: AppColors.background(context),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    profileBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              profileBytes,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          )
                        : CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.22),
                            child: Text(
                              authVM.userName.isNotEmpty
                                  ? authVM.userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${authVM.userName}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Tenha um ótimo dia!',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      tooltip: 'NotificaÃ§Ãµes',
                      onPressed: () => _showNotifications(context),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Saldo Total',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.visibility_outlined,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currencyFormat.format(financeVM.saldo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Builder(builder: (context) {
                      final pct = financeVM.thisMonthChangePercent;
                      final sign = pct >= 0 ? '+' : '';
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pct >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$sign${pct.toStringAsFixed(1)}% este mês',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(financeVM.saldo),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward,
                                color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              '+8,5% este mês',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 */
  void _showNotifications(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final recent = financeVM.recentTransactions.take(3).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surface(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(sheetContext),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notificações',
                      style: TextStyle(
                        color: AppColors.primaryText(sheetContext),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _NotificationItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Saldo atualizado',
                description:
                    'Seu saldo atual é ${currencyFormat.format(financeVM.saldo)}.',
              ),
              if (recent.isEmpty)
                const _NotificationItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sem movimentações recentes',
                  description:
                      'Cadastre receitas ou despesas para receber alertas.',
                )
              else
                ...recent.map(
                  (transaction) {
                    final isIncome =
                        transaction.type == TransactionType.receita;
                    return _NotificationItem(
                      icon: isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      title: transaction.description,
                      description:
                          '${isIncome ? 'Receita' : 'Despesa'} de ${currencyFormat.format(transaction.amount)}.',
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.field(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final FinanceViewModel financeVM;
  final NumberFormat currencyFormat;

  const _MetricsRow({required this.financeVM, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.arrow_downward_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primaryGreen,
            label: 'Receitas',
            value: currencyFormat.format(financeVM.totalReceitas),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.arrow_upward_rounded,
            iconBg: const Color(0xFFFFEBEE),
            iconColor: AppColors.expense,
            label: 'Despesas',
            value: currencyFormat.format(financeVM.totalDespesas),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: AppColors.investment,
            label: 'Investimentos',
            value: currencyFormat.format(financeVM.investimentos),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? iconColor.withValues(alpha: 0.18)
                  : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.financeVM});

  final FinanceViewModel financeVM;

  @override
  Widget build(BuildContext context) {
    final monthData = financeVM.lastSixMonthsData;
    final values = monthData.map((m) => m['net'] as double).toList();
    final maxVal = values.fold(0.0, (a, b) => b > a ? b : a);
    final minVal = values.fold(0.0, (a, b) => b < a ? b : a);
    final maxY = maxVal <= 0 ? 1000.0 : ((maxVal * 1.3) / 500).ceil() * 500.0;
    final minY = minVal >= 0 ? 0.0 : ((minVal * 1.3) / 500).floor() * 500.0;
    final range = maxY - minY;
    final interval = range <= 0 ? 1000.0 : ((range / 4) / 500).ceil() * 500.0;
    final gridColor = AppColors.isDark(context)
        ? const Color(0xFF263244)
        : const Color(0xFFEFF4F8);

    return Container(
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
              Text(
                'Evolução',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText(context),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.field(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Text(
                  '6 meses',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo líquido dos últimos 6 meses',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: gridColor, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == minY && minY == 0) {
                          return const SizedBox.shrink();
                        }
                        final label = value.abs() >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}K'
                            : value.toStringAsFixed(0);
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryText(context),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            monthData[idx]['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondaryText(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      values.length,
                      (i) => FlSpot(i.toDouble(), values[i]),
                    ),
                    isCurved: true,
                    color: AppColors.primaryGreen,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primaryGreen,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryGreen.withValues(alpha: 0.15),
                          AppColors.primaryGreen.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel t;
  final NumberFormat currencyFormat;

  const _TransactionTile({required this.t, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isReceita = t.type == TransactionType.receita;
    final color = _categoryColor(t.category, isReceita);
    final now = DateTime.now();
    final diff = now.difference(t.date).inDays;
    final dateStr = diff == 0
        ? 'Hoje'
        : diff == 1
            ? 'Ontem'
            : '${diff}d atrás';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(t.category, isReceita),
                color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isReceita ? 'Receita' : 'Despesa'} · $dateStr',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.secondaryText(context)),
                ),
              ],
            ),
          ),
          Text(
            '${isReceita ? '+' : '-'}${currencyFormat.format(t.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isReceita ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  static Color _categoryColor(String category, bool isReceita) {
    if (isReceita) return AppColors.income;
    switch (category) {
      case 'Alimentação':
        return const Color(0xFFFF7043);
      case 'Transporte':
        return const Color(0xFF42A5F5);
      case 'Assinaturas':
        return const Color(0xFFAB47BC);
      case 'Lazer':
        return const Color(0xFFEF5350);
      case 'Saúde':
        return const Color(0xFF26A69A);
      case 'Moradia':
        return const Color(0xFF5C6BC0);
      default:
        return const Color(0xFF78909C);
    }
  }

  static IconData _categoryIcon(String category, bool isReceita) {
    if (isReceita) return Icons.arrow_downward_rounded;
    switch (category) {
      case 'Salário':
        return Icons.work_outline_rounded;
      case 'Freelance':
        return Icons.computer_rounded;
      case 'Alimentação':
        return Icons.restaurant_rounded;
      case 'Transporte':
        return Icons.directions_car_rounded;
      case 'Assinaturas':
        return Icons.subscriptions_rounded;
      case 'Lazer':
        return Icons.sports_esports_rounded;
      case 'Saúde':
        return Icons.favorite_outline_rounded;
      case 'Moradia':
        return Icons.home_outlined;
      case 'Contas':
        return Icons.receipt_long_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
