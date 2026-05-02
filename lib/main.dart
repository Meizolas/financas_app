import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/finance_viewmodel.dart';
import 'views/auth_view.dart';
import 'views/dashboard_view.dart';
import 'views/analysis_view.dart';

void main() {
  runApp(const FinancasApp());
}

class FinancasApp extends StatelessWidget {
  const FinancasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
      ],
      child: MaterialApp(
        title: 'FinançasApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthView(),
          '/dashboard': (context) => const DashboardView(),
          '/analysis': (context) => const AnalysisView(),
        },
      ),
    );
  }
}
