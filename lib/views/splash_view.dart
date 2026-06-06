import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _loadingCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _scaleAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);

    _entryCtrl.forward();

    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;

      final hasSession =
          await context.read<AuthViewModel>().restoreCurrentSession();
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        hasSession ? '/loading' : '/login',
      );
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _loadingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fundo gradiente radial verde → preto ─────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.05),
                radius: 1.1,
                colors: [
                  Color(0xFF0C2212),
                  Color(0xFF061008),
                  Color(0xFF020603),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Traçados de gráfico no background ────────────────
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _ChartTracesPainter(),
          ),

          // ── Conteúdo ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo + nome + subtítulo
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (_, child) => Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.scale(
                      scale: 0.75 + _scaleAnim.value * 0.25,
                      child: child,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FinancyLogo(size: 100),
                      SizedBox(height: 24),
                      Text(
                        'Financy App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Controle seu dinheiro.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Construa seu futuro.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // ── Barra de loading animada ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: AnimatedBuilder(
                    animation: _loadingCtrl,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          value: _loadingCtrl.value,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Indicadores de página ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(false),
                    const SizedBox(width: 6),
                    _dot(true),
                    const SizedBox(width: 6),
                    _dot(false),
                  ],
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) => Container(
        width: active ? 20 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGreen : Colors.white24,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

// ── Traçados de gráfico sutis no fundo ───────────────────────────────
class _ChartTracesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawLine(
      canvas,
      points: [
        Offset(w * 0.18, h * 0.58),
        Offset(w * 0.26, h * 0.50),
        Offset(w * 0.32, h * 0.54),
        Offset(w * 0.40, h * 0.42),
        Offset(w * 0.46, h * 0.46),
        Offset(w * 0.55, h * 0.34),
        Offset(w * 0.62, h * 0.38),
        Offset(w * 0.70, h * 0.28),
        Offset(w * 0.78, h * 0.32),
        Offset(w * 0.87, h * 0.20),
        Offset(w * 0.95, h * 0.24),
      ],
      color: const Color(0xFF00C853),
      opacity: 0.13,
      strokeWidth: 1.4,
      drawDots: true,
    );

    _drawLine(
      canvas,
      points: [
        Offset(w * 0.25, h * 0.65),
        Offset(w * 0.34, h * 0.59),
        Offset(w * 0.41, h * 0.62),
        Offset(w * 0.50, h * 0.52),
        Offset(w * 0.57, h * 0.55),
        Offset(w * 0.65, h * 0.44),
        Offset(w * 0.73, h * 0.48),
        Offset(w * 0.81, h * 0.37),
        Offset(w * 0.89, h * 0.41),
        Offset(w * 0.98, h * 0.30),
      ],
      color: Colors.white,
      opacity: 0.06,
      strokeWidth: 0.9,
      drawDots: false,
    );

    _drawLine(
      canvas,
      points: [
        Offset(-w * 0.02, h * 0.72),
        Offset(w * 0.08, h * 0.65),
        Offset(w * 0.15, h * 0.68),
        Offset(w * 0.23, h * 0.58),
        Offset(w * 0.30, h * 0.62),
        Offset(w * 0.38, h * 0.53),
        Offset(w * 0.45, h * 0.56),
      ],
      color: const Color(0xFF00C853),
      opacity: 0.07,
      strokeWidth: 0.8,
      drawDots: false,
    );

    // Grade de fundo
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 6; i++) {
      final y = h * i / 6;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (int i = 1; i < 4; i++) {
      final x = w * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
  }

  void _drawLine(
    Canvas canvas, {
    required List<Offset> points,
    required Color color,
    required double opacity,
    required double strokeWidth,
    required bool drawDots,
  }) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final cp = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, cp.dx, cp.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);

    if (drawDots) {
      final dotPaint = Paint()
        ..color = color.withValues(alpha: opacity * 1.6)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < points.length; i += 2) {
        canvas.drawCircle(points[i], strokeWidth * 1.6, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
