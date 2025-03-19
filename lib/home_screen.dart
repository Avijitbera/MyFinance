import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfinance/auth_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'finance_provider.dart';
import 'category_screen.dart';
import 'finance_model.dart';
import 'add_transaction_screen.dart';
import 'transaction_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Expense';
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final transactions = financeProvider.transactions;
    
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Finance Tracker'),
            actions: [
              IconButton(
                icon: const Icon(Icons.category),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: financeProvider.isSyncing 
                  ? null 
                  : () async {
                      if (financeProvider.isOnline) {
                        await financeProvider.syncLocalWithCloud();
                      }
                    },
              ),
              IconButton(
                onPressed: () async {
                  context.read<FinanceProvider>().clearAllData();
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                    (v) => false,
                  );
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Balance: ${NumberFormat.currency(symbol: '\$').format(finance.getMoney().toInt())}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Last 7 Days'),
                      selected: _selectedDays == 7,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDays = 7);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Last 30 Days'),
                      selected: _selectedDays == 30,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDays = 30);
                        }
                      },
                    ),
                  ],
                ),
              ),
              TransactionChart(
                transactions: transactions,
                daysToShow: _selectedDays,
              ),
              Expanded(
                child: finance.isSyncing && finance.transactions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: finance.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = finance.transactions[index];
                          return ListTile(
                            title: Text(transaction.title),
                            subtitle: Row(
                              children: [
                                Text(
                                  transaction.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat.yMMMd().format(transaction.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${transaction.type == 'Income' ? '+' : ''}${NumberFormat.currency(symbol: '\$').format(transaction.amount)}',
                              style: TextStyle(
                                color: transaction.type == 'Income'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}