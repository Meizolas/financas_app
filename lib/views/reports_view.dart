import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/transaction_model.dart';
import '../viewmodels/finance_viewmodel.dart';

enum _ReportPeriod { monthly, semester, annual }

class _PeriodTotals {
  const _PeriodTotals({
    required this.receitas,
    required this.despesas,
    required this.gastosPorCategoria,
  });

  final double receitas;
  final double despesas;
  final Map<String, double> gastosPorCategoria;

  double get saldo => receitas - despesas;
}

class _EvolutionData {
  const _EvolutionData({
    required this.labels,
    required this.receitas,
    required this.despesas,
  });

  final List<String> labels;
  final List<double> receitas;
  final List<double> despesas;
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  _ReportPeriod _period = _ReportPeriod.monthly;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  int _semester = DateTime.now().month <= 6 ? 1 : 2;

  List<int> get _availableYears {
    final current = DateTime.now().year;
    return List.generate(7, (index) => current - 4 + index);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Consumer<FinanceViewModel>(
      builder: (context, vm, _) {
        final transactions = vm.transactions.toList();
        final periodTransactions = _filterTransactions(transactions);
        final current = _totalsFor(periodTransactions);
        final previous = _totalsFor(_previousPeriodTransactions(transactions));
        final evolution = _buildEvolution(periodTransactions);
        final hasData = periodTransactions.isNotEmpty;

        return Column(
          children: [
            _ReportsHeader(
              periodLabel: _selectedPeriodLabel,
              onCalendarTap: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  88 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterPanel(
                      period: _period,
                      month: _month,
                      year: _year,
                      semester: _semester,
                      availableYears: _availableYears,
                      onPeriodChanged: (period) {
                        setState(() => _period = period);
                      },
                      onMonthChanged: (month) {
                        setState(() => _month = month);
                      },
                      onYearChanged: (year) {
                        setState(() => _year = year);
                      },
                      onSemesterChanged: (semester) {
                        setState(() => _semester = semester);
                      },
                    ),
                    const SizedBox(height: 18),
                    if (!hasData)
                      _EmptyState(
                        onChangePeriod: () {
                          setState(() {
                            final now = DateTime.now();
                            _period = _ReportPeriod.monthly;
                            _month = now.month;
                            _year = now.year;
                            _semester = now.month <= 6 ? 1 : 2;
                          });
                        },
                      )
                    else ...[
                      _SummarySection(
                        currency: currency,
                        current: current,
                        previous: previous,
                      ),
                      const SizedBox(height: 22),
                      _CategorySection(
                        currency: currency,
                        gastos: current.gastosPorCategoria,
                        totalDespesas: current.despesas,
                      ),
                      const SizedBox(height: 22),
                      _EvolutionSection(
                        currency: currency,
                        data: evolution,
                      ),
                      const SizedBox(height: 22),
                      _IndicatorsSection(
                        currency: currency,
                        current: current,
                        previous: previous,
                        period: _period,
                        month: _month,
                        semester: _semester,
                        year: _year,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String get _selectedPeriodLabel {
    switch (_period) {
      case _ReportPeriod.monthly:
        return '${_monthName(_month)} de $_year';
      case _ReportPeriod.semester:
        return '$_semesterº semestre de $_year';
      case _ReportPeriod.annual:
        return 'Ano de $_year';
    }
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> all) {
    return all.where((transaction) {
      final date = transaction.date;
      switch (_period) {
        case _ReportPeriod.monthly:
          return date.year == _year && date.month == _month;
        case _ReportPeriod.semester:
          final startMonth = _semester == 1 ? 1 : 7;
          final endMonth = _semester == 1 ? 6 : 12;
          return date.year == _year &&
              date.month >= startMonth &&
              date.month <= endMonth;
        case _ReportPeriod.annual:
          return date.year == _year;
      }
    }).toList();
  }

  List<TransactionModel> _previousPeriodTransactions(
      List<TransactionModel> all) {
    return all.where((transaction) {
      final date = transaction.date;
      switch (_period) {
        case _ReportPeriod.monthly:
          final previous = DateTime(_year, _month - 1);
          return date.year == previous.year && date.month == previous.month;
        case _ReportPeriod.semester:
          final previousYear = _semester == 1 ? _year - 1 : _year;
          final previousSemester = _semester == 1 ? 2 : 1;
          final startMonth = previousSemester == 1 ? 1 : 7;
          final endMonth = previousSemester == 1 ? 6 : 12;
          return date.year == previousYear &&
              date.month >= startMonth &&
              date.month <= endMonth;
        case _ReportPeriod.annual:
          return date.year == _year - 1;
      }
    }).toList();
  }

  _PeriodTotals _totalsFor(List<TransactionModel> transactions) {
    var receitas = 0.0;
    var despesas = 0.0;
    final gastos = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.receita) {
        receitas += transaction.amount;
      } else {
        despesas += transaction.amount;
        final category = _displayCategory(transaction.category);
        gastos[category] = (gastos[category] ?? 0) + transaction.amount;
      }
    }

    return _PeriodTotals(
      receitas: receitas,
      despesas: despesas,
      gastosPorCategoria: gastos,
    );
  }

  _EvolutionData _buildEvolution(List<TransactionModel> transactions) {
    switch (_period) {
      case _ReportPeriod.monthly:
        return _monthlyEvolution(transactions);
      case _ReportPeriod.semester:
        return _semesterEvolution(transactions);
      case _ReportPeriod.annual:
        return _annualEvolution(transactions);
    }
  }

  _EvolutionData _monthlyEvolution(List<TransactionModel> transactions) {
    final lastDay = DateTime(_year, _month + 1, 0).day;
    final marks = [1, 5, 10, 15, 20, 25, lastDay]
        .where((day) => day <= lastDay)
        .toSet()
        .toList()
      ..sort();

    final receitas = <double>[];
    final despesas = <double>[];

    for (final day in marks) {
      var income = 0.0;
      var expense = 0.0;

      for (final transaction in transactions) {
        if (transaction.date.day > day) continue;
        if (transaction.type == TransactionType.receita) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      receitas.add(income);
      despesas.add(expense);
    }

    return _EvolutionData(
      labels: marks.map((day) => day.toString().padLeft(2, '0')).toList(),
      receitas: receitas,
      despesas: despesas,
    );
  }

  _EvolutionData _semesterEvolution(List<TransactionModel> transactions) {
    final startMonth = _semester == 1 ? 1 : 7;
    final labels = List.generate(6, (index) => _monthShort(startMonth + index));
    final receitas = List<double>.filled(6, 0);
    final despesas = List<double>.filled(6, 0);

    for (final transaction in transactions) {
      final index = transaction.date.month - startMonth;
      if (index < 0 || index >= 6) continue;
      if (transaction.type == TransactionType.receita) {
        receitas[index] += transaction.amount;
      } else {
        despesas[index] += transaction.amount;
      }
    }

    return _EvolutionData(
      labels: labels,
      receitas: receitas,
      despesas: despesas,
    );
  }

  _EvolutionData _annualEvolution(List<TransactionModel> transactions) {
    final labels = List.generate(12, (index) => _monthShort(index + 1));
    final receitas = List<double>.filled(12, 0);
    final despesas = List<double>.filled(12, 0);

    for (final transaction in transactions) {
      final index = transaction.date.month - 1;
      if (transaction.type == TransactionType.receita) {
        receitas[index] += transaction.amount;
      } else {
        despesas[index] += transaction.amount;
      }
    }

    return _EvolutionData(
      labels: labels,
      receitas: receitas,
      despesas: despesas,
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({
    required this.periodLabel,
    required this.onCalendarTap,
  });

  final String periodLabel;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkNavy,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.mintGreen,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Relatórios Financeiros',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acompanhe a evolução das suas finanças.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onCalendarTap,
                  tooltip: periodLabel,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                    size: 21,
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

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.period,
    required this.month,
    required this.year,
    required this.semester,
    required this.availableYears,
    required this.onPeriodChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onSemesterChanged,
  });

  final _ReportPeriod period;
  final int month;
  final int year;
  final int semester;
  final List<int> availableYears;
  final ValueChanged<_ReportPeriod> onPeriodChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onSemesterChanged;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 390;

    return _Surface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppColors.primaryGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _periodLabel(period),
                style: TextStyle(
                  color: AppColors.secondaryText(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PeriodSelector(
            selected: period,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 14),
          if (isCompact)
            Column(
              children: _verticalFields(_fieldWidgets()),
            )
          else
            Row(
              children: _horizontalFields(_fieldWidgets()),
            ),
        ],
      ),
    );
  }

  List<Widget> _verticalFields(List<Widget> fields) {
    return List.generate(fields.length, (index) {
      final isLast = index == fields.length - 1;
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
        child: fields[index],
      );
    });
  }

  List<Widget> _horizontalFields(List<Widget> fields) {
    return List.generate(fields.length, (index) {
      final isLast = index == fields.length - 1;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : 10),
          child: fields[index],
        ),
      );
    });
  }

  List<Widget> _fieldWidgets() {
    final fields = <Widget>[];

    if (period == _ReportPeriod.monthly) {
      fields.add(
        _SelectField<int>(
          label: 'Mês',
          value: month,
          items: List.generate(12, (index) => index + 1),
          labelBuilder: _monthName,
          onChanged: onMonthChanged,
        ),
      );
    }

    if (period == _ReportPeriod.semester) {
      fields.add(
        _SelectField<int>(
          label: 'Semestre',
          value: semester,
          items: const [1, 2],
          labelBuilder: (value) =>
              value == 1 ? '1º Semestre (Jan-Jun)' : '2º Semestre (Jul-Dez)',
          onChanged: onSemesterChanged,
        ),
      );
    }

    fields.add(
      _SelectField<int>(
        label: 'Ano',
        value: year,
        items: availableYears,
        labelBuilder: (value) => value.toString(),
        onChanged: onYearChanged,
      ),
    );

    return fields;
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final _ReportPeriod selected;
  final ValueChanged<_ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.field(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: _ReportPeriod.values.map((period) {
          final active = selected == period;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(period),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      active ? AppColors.surface(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _periodLabel(period),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? AppColors.primaryText(context)
                        : AppColors.secondaryText(context),
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.field(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.secondaryText(context),
              ),
              dropdownColor: AppColors.surface(context),
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        labelBuilder(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.currency,
    required this.current,
    required this.previous,
  });

  final NumberFormat currency;
  final _PeriodTotals current;
  final _PeriodTotals previous;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final twoColumns = width >= 620;

    final cards = [
      _SummaryCard(
        title: 'Receita Total',
        value: currency.format(current.receitas),
        delta: _variationLabel(current.receitas, previous.receitas),
        icon: Icons.trending_up_rounded,
        color: AppColors.income,
        positiveGood: true,
      ),
      _SummaryCard(
        title: 'Despesas Totais',
        value: currency.format(current.despesas),
        delta: _variationLabel(current.despesas, previous.despesas),
        icon: Icons.trending_down_rounded,
        color: AppColors.expense,
        positiveGood: false,
      ),
      _SummaryCard(
        title: 'Saldo Líquido',
        value: currency.format(current.saldo),
        delta: _variationLabel(current.saldo, previous.saldo),
        icon: Icons.account_balance_wallet_outlined,
        color: current.saldo >= 0 ? AppColors.investment : AppColors.expense,
        positiveGood: true,
      ),
    ];

    if (twoColumns) {
      return Row(
        children: List.generate(cards.length, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == cards.length - 1 ? 0 : 12,
              ),
              child: cards[index],
            ),
          );
        }),
      );
    }

    return Column(
      children: List.generate(cards.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == cards.length - 1 ? 0 : 12,
          ),
          child: cards[index],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
    required this.positiveGood,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
  final bool positiveGood;

  @override
  Widget build(BuildContext context) {
    final deltaIsPositive = !delta.startsWith('-') && delta != 'Sem histórico';
    final deltaColor = delta == 'Sem histórico'
        ? AppColors.secondaryText(context)
        : deltaIsPositive == positiveGood
            ? AppColors.income
            : AppColors.expense;

    return _Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                delta.startsWith('-')
                    ? Icons.south_east_rounded
                    : Icons.north_east_rounded,
                color: deltaColor,
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '$delta em relação ao período anterior',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: deltaColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.currency,
    required this.gastos,
    required this.totalDespesas,
  });

  final NumberFormat currency;
  final Map<String, double> gastos;
  final double totalDespesas;

  @override
  Widget build(BuildContext context) {
    final sorted = gastos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final width = MediaQuery.of(context).size.width;
    final sideBySide = width >= 680;

    return _SectionCard(
      title: 'Despesas por Categoria',
      subtitle: 'Distribuição dos gastos do período selecionado.',
      child: sideBySide
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _DonutChart(
                    entries: sorted,
                    totalDespesas: totalDespesas,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 6,
                  child: _CategoryList(
                    entries: sorted,
                    totalDespesas: totalDespesas,
                    currency: currency,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _DonutChart(
                  entries: sorted,
                  totalDespesas: totalDespesas,
                ),
                const SizedBox(height: 18),
                _CategoryList(
                  entries: sorted,
                  totalDespesas: totalDespesas,
                  currency: currency,
                ),
              ],
            ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.entries,
    required this.totalDespesas,
  });

  final List<MapEntry<String, double>> entries;
  final double totalDespesas;

  @override
  Widget build(BuildContext context) {
    final chartEntries = entries.take(6).toList();
    final size = MediaQuery.of(context).size.width < 360 ? 174.0 : 204.0;

    if (totalDespesas <= 0 || chartEntries.isEmpty) {
      return SizedBox(
        height: size,
        child: Center(
          child: Container(
            width: size * 0.70,
            height: size * 0.70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border(context),
                width: 18,
              ),
            ),
            child: Center(
              child: Text(
                'Sem\ndespesas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.secondaryText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: size * 0.30,
              startDegreeOffset: -90,
              sections: chartEntries.map((entry) {
                final percent =
                    totalDespesas > 0 ? entry.value / totalDespesas * 100 : 0;
                return PieChartSectionData(
                  value: entry.value,
                  color: _categoryColor(entry.key),
                  radius: size * 0.17,
                  showTitle: percent >= 8,
                  title: '${percent.round()}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: AppColors.secondaryText(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${totalDespesas.round()}',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.entries,
    required this.totalDespesas,
    required this.currency,
  });

  final List<MapEntry<String, double>> entries;
  final double totalDespesas;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty || totalDespesas <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.field(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Text(
          'Nenhuma despesa registrada no período.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.secondaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      children: entries.take(6).map((entry) {
        final percent =
            totalDespesas > 0 ? entry.value / totalDespesas * 100 : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _categoryColor(entry.key).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _categoryIcon(entry.key),
                  color: _categoryColor(entry.key),
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0).toDouble(),
                        minHeight: 5,
                        backgroundColor: AppColors.field(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _categoryColor(entry.key),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(entry.value),
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${percent.round()}%',
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EvolutionSection extends StatelessWidget {
  const _EvolutionSection({
    required this.currency,
    required this.data,
  });

  final NumberFormat currency;
  final _EvolutionData data;

  @override
  Widget build(BuildContext context) {
    final allValues = [...data.receitas, ...data.despesas];
    final maxValue = allValues.fold<double>(0, math.max);
    final maxY =
        maxValue <= 0 ? 1000.0 : ((maxValue * 1.25) / 1000).ceil() * 1000.0;

    return _SectionCard(
      title: 'Evolução Financeira',
      subtitle: 'Comparativo entre receitas e despesas.',
      headerTrailing: const _LineLegend(),
      child: SizedBox(
        height: 238,
        child: LineChart(
          LineChartData(
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.isDark(context)
                    ? const Color(0xFF263244)
                    : const Color(0xFFEFF4F8),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: math.max(0, data.labels.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: maxY / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      value >= 1000
                          ? '${(value / 1000).toStringAsFixed(0)}K'
                          : value.toStringAsFixed(0),
                      style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= data.labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data.labels[index],
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.darkNavy,
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final isIncome = spot.barIndex == 0;
                    return LineTooltipItem(
                      '${isIncome ? 'Receita' : 'Despesa'}\n'
                      '${currency.format(spot.y)}',
                      TextStyle(
                        color: isIncome ? AppColors.income : AppColors.expense,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              _lineData(data.receitas, AppColors.income),
              _lineData(data.despesas, AppColors.expense),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineData(List<double> values, Color color) {
    return LineChartBarData(
      spots: List.generate(
        values.length,
        (index) => FlSpot(index.toDouble(), values[index]),
      ),
      isCurved: true,
      curveSmoothness: 0.18,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: color,
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
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.00),
          ],
        ),
      ),
    );
  }
}

class _LineLegend extends StatelessWidget {
  const _LineLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendPill(color: AppColors.income, label: 'Receitas'),
        SizedBox(width: 8),
        _LegendPill(color: AppColors.expense, label: 'Despesas'),
      ],
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _IndicatorsSection extends StatelessWidget {
  const _IndicatorsSection({
    required this.currency,
    required this.current,
    required this.previous,
    required this.period,
    required this.month,
    required this.semester,
    required this.year,
  });

  final NumberFormat currency;
  final _PeriodTotals current;
  final _PeriodTotals previous;
  final _ReportPeriod period;
  final int month;
  final int semester;
  final int year;

  @override
  Widget build(BuildContext context) {
    final savingsRate =
        current.receitas > 0 ? (current.saldo / current.receitas) * 100 : 0.0;
    final days = _periodDays();
    final dailyAverage = days > 0 ? current.despesas / days : 0.0;
    final topCategory = current.gastosPorCategoria.entries.isEmpty
        ? null
        : current.gastosPorCategoria.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );
    final growth = _variationLabel(current.receitas, previous.receitas);
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 720 ? 4 : 2;

    final cards = [
      _IndicatorCard(
        icon: Icons.savings_outlined,
        color: AppColors.income,
        title: 'Taxa de Economia',
        value: '${savingsRate.clamp(-999, 999).toStringAsFixed(0)}%',
        detail: 'Saldo sobre receita',
      ),
      _IndicatorCard(
        icon: Icons.today_outlined,
        color: const Color(0xFFFF8A50),
        title: 'Média de Gastos Diários',
        value: currency.format(dailyAverage),
        detail: '$days dias analisados',
      ),
      _IndicatorCard(
        icon: Icons.category_outlined,
        color: const Color(0xFF7C3AED),
        title: 'Maior Categoria de Gasto',
        value: topCategory?.key ?? 'Sem gastos',
        detail: topCategory == null
            ? 'R\$ 0,00'
            : currency.format(topCategory.value),
      ),
      _IndicatorCard(
        icon: Icons.show_chart_rounded,
        color: AppColors.investment,
        title: 'Crescimento da Receita',
        value: growth,
        detail: 'Vs. período anterior',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicadores Financeiros',
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 4 ? 1.35 : 1.12,
          ),
          itemBuilder: (context, index) => cards[index],
        ),
      ],
    );
  }

  int _periodDays() {
    switch (period) {
      case _ReportPeriod.monthly:
        return DateTime(year, month + 1, 0).day;
      case _ReportPeriod.semester:
        final startMonth = semester == 1 ? 1 : 7;
        final endMonth = semester == 1 ? 6 : 12;
        var days = 0;
        for (var monthNumber = startMonth;
            monthNumber <= endMonth;
            monthNumber++) {
          days += DateTime(year, monthNumber + 1, 0).day;
        }
        return days;
      case _ReportPeriod.annual:
        return DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
    }
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onChangePeriod,
  });

  final VoidCallback onChangePeriod;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: Column(
        children: [
          SizedBox(
            width: 132,
            height: 112,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 108,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.field(context),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                ),
                const Positioned(
                  left: 18,
                  bottom: 20,
                  child: _EmptyBar(height: 34, color: AppColors.expense),
                ),
                const Positioned(
                  left: 54,
                  bottom: 20,
                  child: _EmptyBar(height: 55, color: AppColors.investment),
                ),
                const Positioned(
                  right: 20,
                  bottom: 20,
                  child: _EmptyBar(height: 72, color: AppColors.income),
                ),
                Positioned(
                  top: 4,
                  right: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum dado encontrado para este período.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha outro mês, semestre ou ano para continuar a análise.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onChangePeriod,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Alterar período'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBar extends StatelessWidget {
  const _EmptyBar({
    required this.height,
    required this.color,
  });

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerTrailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (headerTrailing != null) ...[
                const SizedBox(width: 10),
                headerTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.24 : 0.06,
            ),
            blurRadius: AppColors.isDark(context) ? 10 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _periodLabel(_ReportPeriod period) {
  switch (period) {
    case _ReportPeriod.monthly:
      return 'Mensal';
    case _ReportPeriod.semester:
      return 'Semestral';
    case _ReportPeriod.annual:
      return 'Anual';
  }
}

String _variationLabel(double current, double previous) {
  if (previous == 0) {
    if (current == 0) return 'Sem histórico';
    return '+100%';
  }

  final variation = ((current - previous) / previous.abs()) * 100;
  final sign = variation >= 0 ? '+' : '';
  return '$sign${variation.toStringAsFixed(0)}%';
}

String _displayCategory(String raw) {
  switch (raw) {
    case 'AlimentaÃ§Ã£o':
    case 'Alimentação':
      return 'Alimentação';
    case 'SaÃºde':
    case 'Saúde':
      return 'Saúde';
    case 'SalÃ¡rio':
    case 'Salário':
      return 'Salário';
    default:
      return raw;
  }
}

Color _categoryColor(String category) {
  switch (_displayCategory(category)) {
    case 'Alimentação':
      return const Color(0xFFFF7043);
    case 'Transporte':
      return const Color(0xFF2563EB);
    case 'Assinaturas':
      return const Color(0xFF8B5CF6);
    case 'Lazer':
      return const Color(0xFFEC4899);
    case 'Saúde':
      return const Color(0xFF14B8A6);
    case 'Moradia':
      return const Color(0xFF6366F1);
    case 'Contas':
      return const Color(0xFFF59E0B);
    case 'Salário':
      return AppColors.income;
    case 'Freelance':
      return const Color(0xFF06B6D4);
    default:
      return const Color(0xFF64748B);
  }
}

IconData _categoryIcon(String category) {
  switch (_displayCategory(category)) {
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
    case 'Salário':
      return Icons.work_outline_rounded;
    case 'Freelance':
      return Icons.computer_rounded;
    default:
      return Icons.category_outlined;
  }
}

String _monthName(int month) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return months[month - 1];
}

String _monthShort(int month) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return months[month - 1];
}
