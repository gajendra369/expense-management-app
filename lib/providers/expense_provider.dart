import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  double _totalBudget = 0.0;
  List<Expense> _expenses = []; // Declare _expenses

  double get totalBudget => _totalBudget;
  List<Expense> get expenses => _expenses;

  set totalBudget(double value) {
    _totalBudget = value;
    DBHelper().setSetting('budget', value.toString());
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    final db = await DBHelper().database;
    await db.insert('expenses', expense.toMap());
    _expenses.add(expense);
    notifyListeners();
  }

  Future<void> fetchAndSetExpenses() async {
    final db = await DBHelper().database;
    final List<Map<String, dynamic>> dataList = await db.query('expenses');
    _expenses = dataList.map((item) {
      return Expense(
        id: item['id'] as int,
        title: item['title'] ?? 'No Title',
        amount: item['amount'] as double,
        category: item['category'] ?? 'Others',
        date: DateTime.parse(item['date'] as String),
      );
    }).toList();
    notifyListeners();
  }

  Future<void> fetchAndSetBudget() async {
    final budgetString = await DBHelper().getSetting('budget');
    _totalBudget = double.tryParse(budgetString ?? '') ?? 0.0;
    notifyListeners();
  }

  double getTotalExpensesByCategory(String category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> resetData() async {
    final db = await DBHelper().database;

    // Clear the expenses table
    await db.delete('expenses');

    // Clear the in-memory list of expenses
    _expenses.clear();

    // Reset the total budget
    _totalBudget = 0.0;
    await DBHelper().setSetting('budget', '0.0'); // Reset budget in DB

    notifyListeners();
  }

  bool get hasExceededBudget {
    final totalExpenses = _expenses.fold(0.0, (sum, item) => sum + item.amount);
    return totalExpenses >= _totalBudget;
  }

  bool get isNearBudget {
    final totalExpenses = _expenses.fold(0.0, (sum, item) => sum + item.amount);
    return _totalBudget > 0 && totalExpenses / _totalBudget > 0.9;
  }
}
