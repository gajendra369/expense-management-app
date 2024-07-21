import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final List<String> _categories = [
    'Food',
    'Transport',
    'Utilities',
    'Entertainment',
    'Others'
  ];
  String _selectedCategory = 'Food';
  bool isReset = false;

  @override
  void initState() {
    super.initState();
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    expenseProvider.fetchAndSetExpenses();
    expenseProvider.fetchAndSetBudget();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final double totalExpenses = _getTotalExpenses(expenseProvider);
    final double budget = expenseProvider.totalBudget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.currency_rupee,
              color: Colors.white,
            ),
            onPressed: () {
              _showBudgetDialog(context, expenseProvider);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              _resetData(expenseProvider);
              setState(() {
                isReset = true;
              });
            },
          ),
        ],
        backgroundColor: Colors.blue,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/bg.jpg"), fit: BoxFit.cover),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                  height: 289,
                  child: Column(children: [
                    Text(
                      'Total Budget: ₹${budget.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: _buildPieChart(expenseProvider),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    if (expenseProvider.hasExceededBudget && !isReset)
                      const Text(
                        'Warning: Expenses exceed the budget!',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      )
                    else if (expenseProvider.isNearBudget && !isReset)
                      const Text(
                        'Warning: Expenses are close to the budget!',
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      )
                    else if (isReset)
                      const Text(""),
                  ])),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        labelStyle:
                            TextStyle(color: Colors.white), // Label color
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white), // Border color
                        ),
                      ),
                      style: const TextStyle(color: Colors.white), // Text color
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        labelStyle:
                            TextStyle(color: Colors.white), // Label color
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white), // Border color
                        ),
                      ),
                      style: const TextStyle(color: Colors.white), // Text color
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), // Numeric input with optional decimal
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.black.withOpacity(0.5),
                    items: _categories
                        .map<DropdownMenuItem<String>>((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: const TextStyle(
                              color: Colors
                                  .white), // Set text color of each menu item
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final title = _titleController.text;
                      final amount = double.tryParse(_amountController.text);
                      if (title.isNotEmpty && amount != null) {
                        final expense = Expense(
                          title: title,
                          amount: amount,
                          category: _selectedCategory,
                          date: DateTime.now(),
                        );
                        expenseProvider.addExpense(expense);
                        _titleController.clear();
                        _amountController.clear();
                      }
                      if (isReset) {
                        isReset = false;
                      }
                    },
                    child: const Text('Add Expense'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<ExpenseProvider>(
                  builder: (context, provider, child) {
                    return ListView.builder(
                      itemCount: provider.expenses.length,
                      itemBuilder: (context, index) {
                        final expense = provider.expenses[index];
                        return ListTile(
                          title: Text(
                            expense.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                              '${expense.category} - ${expense.date.toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(color: Colors.white)),
                          trailing: Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(ExpenseProvider provider) {
    final sections = _getSections(provider);

    if (sections.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: sections,
        borderData: FlBorderData(show: false),
        sectionsSpace: 4,
        centerSpaceRadius: 40,
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, ExpenseProvider provider) {
    final TextEditingController budgetController = TextEditingController();
    budgetController.text = provider.totalBudget.toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Total Budget'),
          content: TextField(
            controller: budgetController,
            decoration: const InputDecoration(hintText: 'Enter budget amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final budget = double.tryParse(budgetController.text) ?? 0;
                provider.totalBudget = budget;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _resetData(ExpenseProvider provider) {
    provider.resetData();
  }

  List<PieChartSectionData> _getSections(ExpenseProvider provider) {
    Map<String, double> categorySums = {};
    for (var category in _categories) {
      categorySums[category] = provider.getTotalExpensesByCategory(category);
    }

    return categorySums.entries.map((entry) {
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: entry.key, // Show category name
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Set title color to white
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.blue;
      case 'Transport':
        return Colors.green;
      case 'Utilities':
        return Colors.orange;
      case 'Entertainment':
        return Colors.red;
      case 'Others':
      default:
        return Colors.grey;
    }
  }

  double _getTotalExpenses(ExpenseProvider provider) {
    return provider.expenses.fold(0.0, (sum, item) => sum + item.amount);
  }
}
