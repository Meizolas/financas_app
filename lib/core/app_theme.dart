import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF00C853);
  static const Color darkGreen = Color(0xFF0D9624);
  static const Color mintGreen = Color(0xFF0BF0AE);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);

  static const Color income = Color(0xFF00C853);
  static const Color expense = Color(0xFFEF5350);
  static const Color investment = Color(0xFF3B82F6);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkGreen, primaryGreen],
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B1220) : lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF111827) : white;

  static Color elevatedSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF172033) : white;

  static Color field(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : lightBackground;

  static Color primaryText(BuildContext context) =>
      isDark(context) ? const Color(0xFFF8FAFC) : textPrimary;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? const Color(0xFFCBD5E1) : textSecondary;

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : borderColor;

  static Color mutedIcon(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : textSecondary;
}

/// Logo standalone (assets/logo.png) — use sobre fundos escuros ou brancos
class FinancyLogo extends StatelessWidget {
  final double size;
  const FinancyLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackLogo(size: size, dark: false),
    );
  }
}

/// Ícone do app (assets/icone.png) — versão com fundo escuro arredondado
class FinancyIcon extends StatelessWidget {
  final double size;
  const FinancyIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icone.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackLogo(size: size, dark: true),
    );
  }
}

/// Fallback caso os assets não sejam encontrados
class _FallbackLogo extends StatelessWidget {
  final double size;
  final bool dark;
  const _FallbackLogo({required this.size, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0F1C14) : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: dark
            ? null
            : const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [Color(0xFF00C853), Color(0xFF5EFF9E)],
              ),
      ),
      child: Center(
        child: Text(
          'F',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.52,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
