import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../models/transaction_model.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Análise Financeira'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.pie_chart), text: 'Orçamento'),
              Tab(icon: Icon(Icons.list_alt), text: 'Movimentações'),
            ],
          ),
        ),
        body: Consumer<FinanceViewModel>(
          builder: (context, financeVM, _) {
            return TabBarView(
              children: [
                // === ABA 1: Análise de Orçamento ===
                _BudgetAnalysisTab(
                  financeVM: financeVM,
                  currencyFormat: currencyFormat,
                ),

                // === ABA 2: Lista completa de movimentações ===
                _TransactionListTab(
                  financeVM: financeVM,
                  currencyFormat: currencyFormat,
                  dateFormat: dateFormat,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ========================
// Aba de Análise de Orçamento
// ========================
class _BudgetAnalysisTab extends StatelessWidget {
  final FinanceViewModel financeVM;
  final NumberFormat currencyFormat;

  const _BudgetAnalysisTab({
    required this.financeVM,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final gastos = financeVM.gastosPorCategoria;
    final totalDespesas = financeVM.totalDespesas;
    final totalReceitas = financeVM.totalReceitas;

    // Cores para cada categoria
    final categoryColors = <String, Color>{
      'Alimentação': const Color(0xFFFF7043),
      'Moradia': const Color(0xFF42A5F5),
      'Transporte': const Color(0xFFFFCA28),
      'Lazer': const Color(0xFFAB47BC),
      'Contas': const Color(0xFF26A69A),
      'Outros': const Color(0xFF78909C),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card resumo geral
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo do Período',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barra de progresso: quanto das receitas foi gasto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Uso do orçamento',
                          style: TextStyle(fontSize: 15)),
                      Text(
                        totalReceitas > 0
                            ? '${((totalDespesas / totalReceitas) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalReceitas > 0
                          ? (totalDespesas / totalReceitas).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 14,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalDespesas / (totalReceitas > 0 ? totalReceitas : 1) >
                                0.8
                            ? Colors.red
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Disponível: ${currencyFormat.format(financeVM.saldo)}',
                        style: TextStyle(
                          color:
                              financeVM.saldo >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Gasto: ${currencyFormat.format(totalDespesas)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Título: gastos por categoria
          const Text(
            'Despesas por Categoria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 12),

          // Barras de progresso por categoria
          if (gastos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma despesa registrada.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...gastos.entries.map((entry) {
              final percentage =
                  totalDespesas > 0 ? entry.value / totalDespesas : 0.0;
              final color =
                  categoryColors[entry.key] ?? const Color(0xFF78909C);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              currencyFormat.format(entry.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(1)}% do total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),

          // Indicadores de receita por categoria
          const Text(
            'Receitas por Categoria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 12),

          if (financeVM.receitasPorCategoria.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma receita registrada.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...financeVM.receitasPorCategoria.entries.map((entry) {
              final percentage =
                  totalReceitas > 0 ? entry.value / totalReceitas : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF66BB6A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              currencyFormat.format(entry.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF66BB6A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(1)}% do total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ========================
// Aba de Lista de Movimentações
// ========================
class _TransactionListTab extends StatelessWidget {
  final FinanceViewModel financeVM;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  const _TransactionListTab({
    required this.financeVM,
    required this.currencyFormat,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final transactions = financeVM.recentTransactions;

    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma movimentação encontrada.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isReceita = t.type == TransactionType.receita;

        return Dismissible(
          key: Key(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            financeVM.removeTransaction(t.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${t.description} removido'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isReceita ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                child: Icon(
                  isReceita ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isReceita ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
              title: Text(
                t.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${t.category} • ${dateFormat.format(t.date)}',
                style: const TextStyle(fontSize: 13),
              ),
              trailing: Text(
                '${isReceita ? '+' : '-'} ${currencyFormat.format(t.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isReceita ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
