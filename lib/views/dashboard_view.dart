import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/finance_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/transaction_model.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    // Carrega dados de exemplo ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().loadSampleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Consumer<AuthViewModel>(
          builder: (context, authVM, _) {
            return Text('Olá, ${authVM.userName}');
          },
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ver Análises',
            onPressed: () => Navigator.pushNamed(context, '/analysis'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: Consumer<FinanceViewModel>(
        builder: (context, financeVM, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card do saldo
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B5E20),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    children: [
                      const Text(
                        'Saldo Atual',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(financeVM.saldo),
                        style: TextStyle(
                          color: financeVM.saldo >= 0
                              ? Colors.white
                              : Colors.redAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Cards de Receita e Despesa
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.arrow_upward,
                              label: 'Receitas',
                              value: currencyFormat
                                  .format(financeVM.totalReceitas),
                              color: const Color(0xFF66BB6A),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.arrow_downward,
                              label: 'Despesas',
                              value: currencyFormat
                                  .format(financeVM.totalDespesas),
                              color: const Color(0xFFEF5350),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Título do histórico
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transações Recentes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/analysis'),
                        child: const Text(
                          'Ver tudo',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de transações recentes (máx 5)
                if (financeVM.recentTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhuma transação registrada.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        financeVM.recentTransactions.length > 5
                            ? 5
                            : financeVM.recentTransactions.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final t = financeVM.recentTransactions[index];
                      final isReceita =
                          t.type == TransactionType.receita;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isReceita
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            child: Icon(
                              isReceita
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isReceita
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red,
                            ),
                          ),
                          title: Text(
                            t.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
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
                              color: isReceita
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),

      // Botão flutuante para adicionar transação
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  // Diálogo para adicionar nova transação
  void _showAddTransactionDialog(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType selectedType = TransactionType.despesa;
    String selectedCategory = 'Alimentação';

    final categories = [
      'Alimentação',
      'Moradia',
      'Transporte',
      'Lazer',
      'Contas',
      'Salário',
      'Freelance',
      'Vendas',
      'Outros',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova Transação'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tipo (Receita / Despesa)
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.receita,
                          label: Text('Receita'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: TransactionType.despesa,
                          label: Text('Despesa'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (newSelection) {
                        setDialogState(() {
                          selectedType = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor (R\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                            value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategory = val!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final desc = descController.text.trim();
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;
                    if (desc.isNotEmpty && amount > 0) {
                      context.read<FinanceViewModel>().addTransaction(
                            description: desc,
                            amount: amount,
                            type: selectedType,
                            category: selectedCategory,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Widget reutilizável para os cards de resumo
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
