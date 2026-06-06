import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class LoadingView extends StatefulWidget {
  const LoadingView({super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────
  late AnimationController _fadeCtrl; // fade-in geral
  late AnimationController _glowCtrl; // brilho pulsante do logo
  late AnimationController _floatCtrl; // flutuação vertical do logo
  late AnimationController _loadingCtrl; // barra de progresso
  late AnimationController _bgCtrl; // movimento das curvas de fundo

  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _textDelayAnim;

  @override
  void initState() {
    super.initState();

    // Fade-in inicial (logo + textos)
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _textDelayAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    // Glow pulsante contínuo no logo
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    // Flutuação vertical suave (±5 px)
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    // Barra de progresso
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    // Animação lenta do fundo (curvas financeiras)
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _fadeCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    _loadingCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fundo gradiente premium ──────────────────────────
          _PremiumBackground(),

          // ── Glow central pulsante no fundo ───────────────────
          _BackgroundGlowOverlay(glowAnim: _glowAnim),

          // ── Curvas financeiras animadas ───────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: Size(size.width, size.height),
              painter: _FinancialCurvesPainter(_bgCtrl.value),
            ),
          ),

          // ── Conteúdo principal ────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const Spacer(flex: 2),

              // Logo com glow + flutuação
              AnimatedBuilder(
                animation: Listenable.merge([_fadeCtrl, _glowCtrl, _floatCtrl]),
                builder: (_, child) {
                  final glow = _glowAnim.value;
                  final floatY = (_floatAnim.value - 0.5) * 10.0;

                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, floatY),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            // Glow interno
                            BoxShadow(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.35 + glow * 0.30),
                              blurRadius: 24 + glow * 24,
                              spreadRadius: 0,
                            ),
                            // Glow externo difuso
                            BoxShadow(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.10 + glow * 0.12),
                              blurRadius: 60 + glow * 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: const FinancyLogo(size: 112),
              ),

              const SizedBox(height: 32),

              // Nome do app
              AnimatedBuilder(
                animation: _textDelayAnim,
                builder: (_, child) =>
                    Opacity(opacity: _textDelayAnim.value, child: child),
                child: const Text(
                  'Financy App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Slogan
              AnimatedBuilder(
                animation: _textDelayAnim,
                builder: (_, child) => Opacity(
                  opacity: _textDelayAnim.value * 0.7,
                  child: child,
                ),
                child: const Text(
                  'Gerencie suas finanças com inteligência.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13.5,
                    letterSpacing: 0.2,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),

              // ── Barra de progresso ──────────────────────────
              _AnimatedProgressBar(loadingCtrl: _loadingCtrl),

              const SizedBox(height: 14),

              // Texto de status
              AnimatedBuilder(
                animation: _fadeAnim,
                builder: (_, child) =>
                    Opacity(opacity: _fadeAnim.value * 0.45, child: child),
                child: const Text(
                  'Carregando seus dados...',
                  style: TextStyle(color: Colors.white, fontSize: 11.5),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 48),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Fundo gradiente premium escuro ────────────────────────────────────
class _PremiumBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.08),
          radius: 1.15,
          colors: [
            Color(0xFF0E2416), // verde esmeralda escuro no centro
            Color(0xFF07120A), // verde muito escuro
            Color(0xFF020603), // quase preto nas bordas
          ],
          stops: [0.0, 0.50, 1.0],
        ),
      ),
    );
  }
}

// ── Glow radial central pulsante no fundo ─────────────────────────────
class _BackgroundGlowOverlay extends StatelessWidget {
  final Animation<double> glowAnim;
  const _BackgroundGlowOverlay({required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.15),
            radius: 0.60 + glowAnim.value * 0.08,
            colors: [
              AppColors.primaryGreen
                  .withValues(alpha: 0.04 + glowAnim.value * 0.04),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Barra de progresso animada ─────────────────────────────────────────
class _AnimatedProgressBar extends StatelessWidget {
  final AnimationController loadingCtrl;
  const _AnimatedProgressBar({required this.loadingCtrl});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: loadingCtrl,
      builder: (_, __) {
        return Container(
          width: screenW * 0.38,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: loadingCtrl.value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00C853),
                        Color(0xFF69FF9E),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Curvas financeiras com onda fluindo suavemente ponto a ponto ──────
class _FinancialCurvesPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 em loop

  const _FinancialCurvesPainter(this.progress);

  // Aplica uma onda sinusoidal com fase individual por ponto,
  // criando o efeito de "onda fluindo" da esquerda para a direita.
  List<Offset> _animate(
    List<Offset> base, {
    double amplitude = 3.0,
    double phaseShift = 0.0,
    double pointSpread = 0.38,
  }) {
    return List.generate(base.length, (i) {
      final phase = progress * 2 * math.pi + phaseShift + i * pointSpread;
      final dy = math.sin(phase) * amplitude;
      return Offset(base[i].dx, base[i].dy + dy);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Curva 1 — tendência principal ascendente ───────────────
    _drawSmooth(
      canvas,
      points: _animate(
        [
          Offset(w * 0.08, h * 0.58),
          Offset(w * 0.18, h * 0.51),
          Offset(w * 0.26, h * 0.55),
          Offset(w * 0.35, h * 0.43),
          Offset(w * 0.44, h * 0.47),
          Offset(w * 0.53, h * 0.34),
          Offset(w * 0.62, h * 0.38),
          Offset(w * 0.70, h * 0.26),
          Offset(w * 0.79, h * 0.30),
          Offset(w * 0.88, h * 0.19),
          Offset(w * 0.97, h * 0.23),
        ],
        amplitude: 3.5,
        phaseShift: 0.0,
      ),
      color: const Color(0xFF00C853),
      opacity: 0.15,
      strokeWidth: 1.5,
      drawDots: true,
    );

    // ── Curva 2 — secundária mais sutil ────────────────────────
    _drawSmooth(
      canvas,
      points: _animate(
        [
          Offset(w * 0.16, h * 0.67),
          Offset(w * 0.26, h * 0.61),
          Offset(w * 0.34, h * 0.64),
          Offset(w * 0.44, h * 0.54),
          Offset(w * 0.52, h * 0.57),
          Offset(w * 0.61, h * 0.46),
          Offset(w * 0.70, h * 0.50),
          Offset(w * 0.79, h * 0.39),
          Offset(w * 0.88, h * 0.43),
          Offset(w * 0.98, h * 0.32),
        ],
        amplitude: 2.8,
        phaseShift: math.pi * 0.5,
      ),
      color: Colors.white,
      opacity: 0.055,
      strokeWidth: 0.9,
      drawDots: false,
    );

    // ── Curva 3 — inferior esquerda ────────────────────────────
    _drawSmooth(
      canvas,
      points: _animate(
        [
          Offset(-w * 0.02, h * 0.75),
          Offset(w * 0.08, h * 0.67),
          Offset(w * 0.16, h * 0.71),
          Offset(w * 0.25, h * 0.62),
          Offset(w * 0.33, h * 0.65),
          Offset(w * 0.42, h * 0.55),
          Offset(w * 0.51, h * 0.59),
          Offset(w * 0.59, h * 0.49),
        ],
        amplitude: 2.2,
        phaseShift: math.pi * 1.1,
      ),
      color: const Color(0xFF00C853),
      opacity: 0.07,
      strokeWidth: 0.8,
      drawDots: false,
    );

    // ── Grade sutil ─────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(Offset(0, h * i / 6), Offset(w, h * i / 6), gridPaint);
    }
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(w * i / 4, 0), Offset(w * i / 4, h), gridPaint);
    }
  }

  void _drawSmooth(
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
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);

    if (drawDots) {
      final dotPaint = Paint()
        ..color = color.withValues(alpha: opacity * 1.9)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < points.length; i += 2) {
        canvas.drawCircle(points[i], strokeWidth * 1.7, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_FinancialCurvesPainter old) => old.progress != progress;
}
