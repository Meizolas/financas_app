import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'data/app_database.dart';
import 'data/supabase_config.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/finance_viewmodel.dart';
import 'viewmodels/market_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/splash_view.dart';
import 'views/loading_view.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/home_shell.dart';
import 'views/settings_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.configureFactory();

  await dotenv.load(fileName: '.env', isOptional: true);
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const FinancyApp());
}

class FinancyApp extends StatelessWidget {
  const FinancyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
        ChangeNotifierProvider(create: (_) => MarketViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) {
          return MaterialApp(
            title: 'Financy App',
            debugShowCheckedModeBanner: false,
            themeMode: themeVM.isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              colorSchemeSeed: AppColors.primaryGreen,
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.lightBackground,
              textTheme:
                  GoogleFonts.interTextTheme(ThemeData.light().textTheme),
              cardColor: Colors.white,
              dividerColor: AppColors.borderColor,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorSchemeSeed: AppColors.primaryGreen,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0B1220),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              cardColor: const Color(0xFF111827),
              dividerColor: const Color(0xFF334155),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashView(),
              '/login': (context) => const LoginView(),
              '/register': (context) => const RegisterView(),
              '/loading': (context) => const LoadingView(),
              '/home': (context) => const HomeShell(),
              '/settings': (context) => const SettingsView(),
            },
          );
        },
      ),
    );
  }
}
