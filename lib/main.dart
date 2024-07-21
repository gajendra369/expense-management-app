import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/expense_provider.dart';
import './home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final expenseProvider = ExpenseProvider();
  await expenseProvider.fetchAndSetBudget();

  runApp(
    ChangeNotifierProvider(
      create: (context) => expenseProvider,
      child: const MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Expense Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
