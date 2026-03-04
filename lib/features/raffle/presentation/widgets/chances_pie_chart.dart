import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/buyer_stats.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

const _reserveHeight = 44.0;
const _chartHeight   = 238.0;
const _innerRadius   = 44.0;
const _outerRadius   = 100.0;

class ChancesPieChart extends ConsumerStatefulWidget {
  const ChancesPieChart({super.key});

  @override
  ConsumerState<ChancesPieChart> createState() => _ChancesPieChartState();
}

class _ChancesPieChartState extends ConsumerState<ChancesPieChart>
    with TickerProviderStateMixin {
  int _touchedIndex = -1;

  late final AnimationController _needleController;
  late final AnimationController _hoverController;
  late final AnimationController _glowController;

  double _needleTargetAngleDeg = 270;
  bool _needleAnimationScheduled = false;

  int? _simulatedSectionIndex;
  String? _simulatedWinnerName;
  double? _simulatedNeedleAngleDeg;
  bool _isSimulationSpinning = false;
  int? _pendingSimSectionIndex;
  String? _pendingSimWinnerName;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFF00F0FF),
    Color(0xFFFFC000),
    Color(0xFF00FF94),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
  ];

  double _middleDegreeForSection(int index, List<BuyerStats> stats) {
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return 0;
    double cumulative = 0;
    for (var i = 0; i < index; i++) cumulative += stats[i].ticketCount;
    final sectionSpan = (stats[index].ticketCount / total) * 360;
    return cumulative / total * 360 + sectionSpan / 2;
  }

  double _randomDegreeInSection(int index, List<BuyerStats> stats) {
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return 0;
    double cumulative = 0;
    for (var i = 0; i < index; i++) cumulative += stats[i].ticketCount;
    final sectionSpan = (stats[index].ticketCount / total) * 360;
    final sectionStart = cumulative / total * 360;
    return sectionStart + sectionSpan * math.Random().nextDouble();
  }

  double _needleAngleDeg(List<BuyerStats> stats) {
    final realWinnerIdx = ref.watch(winnerSectionIndexProvider);
    final realWinnerAngle = ref.watch(winnerNeedleAngleProvider);

    if (_isSimulationSpinning && _needleController.isAnimating) {
      final t = Curves.easeOutCubic.transform(_needleController.value);
      const start = 270.0;
      final end = _needleTargetAngleDeg + 720;
      return start + (end - start) * t;
    }

    if (_simulatedSectionIndex != null && _simulatedSectionIndex! < stats.length) {
      return _simulatedNeedleAngleDeg ?? _middleDegreeForSection(_simulatedSectionIndex!, stats);
    }

    if (realWinnerIdx != null && realWinnerIdx >= 0 && realWinnerIdx < stats.length) {
      final target = realWinnerAngle ?? _middleDegreeForSection(realWinnerIdx, stats);
      if (_needleController.isAnimating) {
        final t = Curves.easeOutCubic.transform(_needleController.value);
        const start = 270.0;
        final end = _needleTargetAngleDeg + 720;
        return start + (end - start) * t;
      }
      if (_needleController.value >= 1.0) return target;
      return 270;
    }
    return 270;
  }

  int _pickWeightedRandomSection(List<BuyerStats> stats) {
    final total = stats.fold<int>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return 0;
    int r = math.Random().nextInt(total);
    for (var i = 0; i < stats.length; i++) {
      r -= stats[i].ticketCount;
      if (r < 0) return i;
    }
    return stats.length - 1;
  }

  void _runSimulation(List<BuyerStats> stats) {
    if (stats.isEmpty) return;
    final picked = _pickWeightedRandomSection(stats);
    final randomAngle = _randomDegreeInSection(picked, stats);
    setState(() {
      _simulatedSectionIndex = null;
      _simulatedWinnerName = null;
      _simulatedNeedleAngleDeg = null;
      _needleTargetAngleDeg = randomAngle;
      _isSimulationSpinning = true;
      _pendingSimSectionIndex = picked;
      _pendingSimWinnerName = stats[picked].buyerName;
    });
    _needleController.forward(from: 0);
  }

  int _hitTestSection(Offset localCenter, List<BuyerStats> stats) {
    final dist = localCenter.distance;
    if (dist < _innerRadius || dist > _outerRadius) return -1;
    double angleDeg = math.atan2(localCenter.dy, localCenter.dx) * 180 / math.pi;
    if (angleDeg < 0) angleDeg += 360;
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return -1;
    double cumulative = 0;
    for (var i = 0; i < stats.length; i++) {
      cumulative += stats[i].ticketCount;
      if (angleDeg <= (cumulative / total) * 360) return i;
    }
    return stats.length - 1;
  }

  @override
  void initState() {
    super.initState();
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!_isSimulationSpinning || _pendingSimSectionIndex == null) return;
        if (!mounted) return;
        setState(() {
          _simulatedSectionIndex = _pendingSimSectionIndex;
          _simulatedWinnerName = _pendingSimWinnerName;
          _simulatedNeedleAngleDeg = _needleTargetAngleDeg;
          _isSimulationSpinning = false;
          _pendingSimSectionIndex = null;
          _pendingSimWinnerName = null;
        });
      });

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _needleController.dispose();
    _hoverController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(buyerStatsProvider);
    final winnerIdx = ref.watch(winnerSectionIndexProvider);
    final winnerAngle = ref.watch(winnerNeedleAngleProvider);

    if (winnerIdx != null && stats.isNotEmpty && winnerIdx < stats.length && !_needleAnimationScheduled) {
      _needleTargetAngleDeg = winnerAngle ?? _middleDegreeForSection(winnerIdx, stats);
      _needleAnimationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _needleController.forward(from: 0);
      });
    }

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(stats),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isSimulationSpinning
                    ? const _SimulationNotification()
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (stats.isEmpty)
            SizedBox(
              height: _chartHeight + _reserveHeight,
              child: Center(
                child: Text(
                  'Sin datos aún',
                  style: TextStyle(fontFamily: 'Oxanium', fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            _buildChartArea(stats),

          // ── Ganador simulado: aparece abajo de la rueda sin expandir el layout.
          // Espacio fijo reservado; el bloque solo hace fade in (sin SizeTransition).
          SizedBox(
            height: 58,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: (_simulatedSectionIndex != null && _simulatedWinnerName != null)
                  ? Padding(
                      key: const ValueKey('sim_winner'),
                      padding: const EdgeInsets.only(top: 8),
                      child: _SimulatedWinnerBlock(winnerName: _simulatedWinnerName!),
                    )
                  : const SizedBox.shrink(key: ValueKey('sim_empty')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<BuyerStats> stats) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.op(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderHighlight.op(0.6)),
          ),
          child: const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'DISTRIBUCIÓN DE CHANCES',
            style: TextStyle(
              fontFamily: 'Oxanium', fontSize: 11, fontWeight: FontWeight.bold,
              letterSpacing: 1.4, color: AppColors.textPrimary,
            ),
          ),
        ),
        if (stats.isNotEmpty)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _runSimulation(stats),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.op(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.op(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Probar jackpot',
                      style: TextStyle(
                        fontFamily: 'Oxanium', fontSize: 11,
                        fontWeight: FontWeight.w600, color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChartArea(List<BuyerStats> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final centerX = w / 2;
        final centerY = _chartHeight / 2;

        return SizedBox(
          height: _chartHeight + _reserveHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── 1) Donut con efecto hover épico ──────────────────────────
              SizedBox(
                height: _chartHeight,
                child: MouseRegion(
                  onHover: (event) {
                    final offset = Offset(
                      event.localPosition.dx - centerX,
                      event.localPosition.dy - centerY,
                    );
                    final idx = _hitTestSection(offset, stats);
                    if (idx != _touchedIndex) {
                      setState(() => _touchedIndex = idx);
                      if (idx >= 0) {
                        // Siempre replay desde 0: tanto al entrar por primera vez
                        // como al cambiar de porción → el bounce se ve en cada transición.
                        _hoverController.forward(from: 0);
                      } else {
                        _hoverController.reverse();
                      }
                    }
                  },
                  onExit: (_) {
                    if (_touchedIndex != -1) {
                      setState(() => _touchedIndex = -1);
                      _hoverController.reverse();
                    }
                  },
                  child: GestureDetector(
                    onTapDown: (details) {
                      final offset = Offset(
                        details.localPosition.dx - centerX,
                        details.localPosition.dy - centerY,
                      );
                      setState(() => _touchedIndex = _hitTestSection(offset, stats));
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_hoverController, _glowController]),
                      builder: (_, __) => CustomPaint(
                        size: Size(w, _chartHeight),
                        painter: _DonutPainter(
                          stats: stats,
                          colors: _colors,
                          innerRadius: _innerRadius,
                          outerRadius: _outerRadius,
                          gapDeg: 1.2,
                          touchedIndex: _touchedIndex,
                          hoverProgress: _hoverController.value,
                          glowPulse: Curves.easeInOut.transform(_glowController.value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 2) Aguja ──────────────────────────────────────────────────
              // Siempre presente, sin condicionales que cambien la estructura.
              SizedBox(
                height: _chartHeight,
                child: Center(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _needleController,
                      builder: (context, _) {
                        final angle = _needleAngleDeg(stats);
                        return _CenterNeedle(
                          angleDeg: (angle * 100).round() / 100.0,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── 3) Callout 360° ───────────────────────────────────────────
              // FIX CRÍTICO: Positioned.fill hijo directo del Stack.
              Positioned.fill(
                child: IgnorePointer(
                  child: _CalloutContent(
                    touchedIndex: _touchedIndex,
                    stats: stats,
                    chartWidth: w,
                    centerX: centerX,
                  ),
                ),
              ),

              // ── 4) Slot estructural (siempre presente) ────────────────────
              // CRÍTICO: no quitar/agregar Positioned del árbol en release mode.
              // El ganador simulado ahora se muestra en el Column exterior.
              const Positioned(
                left: 0,
                right: 0,
                top: _chartHeight,
                height: _reserveHeight,
                child: IgnorePointer(child: SizedBox.expand()),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CalloutContent – posicionamiento 360° profesional
// Lógica: lane derecho/izquierdo según cosA, posición vertical sigue sinA.
// La card se desplaza arriba/abajo siguiendo la posición real del segmento.
// ─────────────────────────────────────────────────────────────────────────────
class _CalloutContent extends StatelessWidget {
  const _CalloutContent({
    required this.touchedIndex,
    required this.stats,
    required this.chartWidth,
    required this.centerX,
  });

  final int touchedIndex;
  final List<BuyerStats> stats;
  final double chartWidth;
  final double centerX;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFF00F0FF),
    Color(0xFFFFC000),
    Color(0xFF00FF94),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
  ];

  static const _sideDist    = _outerRadius + 64.0;
  static const _cardWidth   = 164.0;
  static const _cardHeight  = 44.0;
  static const _margin      = 8.0;
  static const _chartCenterY = _chartHeight / 2;

  double _middleDegForSection(int index) {
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return 0;
    double cumulative = 0;
    for (var i = 0; i < index; i++) cumulative += stats[i].ticketCount;
    final span = (stats[index].ticketCount / total) * 360;
    return cumulative / total * 360 + span / 2;
  }

  @override
  Widget build(BuildContext context) {
    final valid = touchedIndex >= 0 && touchedIndex < stats.length;
    if (!valid) return const SizedBox.expand();

    final idx = touchedIndex;
    final angleDeg = _middleDegForSection(idx);
    final rad = angleDeg * math.pi / 180;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);
    final color = _colors[idx % _colors.length];

    // Punto de conexión justo en el borde exterior del arco
    final ringPoint = Offset(
      centerX + (_outerRadius + 5) * cosA,
      _chartCenterY + (_outerRadius + 5) * sinA,
    );

    // Lane derecho si cosA >= 0 (derecha o abajo), izquierdo si cosA < 0
    final rightLane = cosA >= 0;

    // Posición horizontal de la card (clampeada dentro del chart)
    final double cardLeft;
    if (rightLane) {
      cardLeft = (centerX + _sideDist)
          .clamp(_margin, chartWidth - _cardWidth - _margin);
    } else {
      cardLeft = (centerX - _sideDist - _cardWidth)
          .clamp(_margin, chartWidth - _cardWidth - _margin);
    }

    // Posición vertical: buena distancia al círculo (carteles bien separados).
    const minBias = 98.0;
    const spread  = 138.0;
    final rawBias = sinA * spread;
    final vertBias = sinA >= 0
        ? math.max(rawBias, minBias)
        : math.min(rawBias, -minBias);

    final cardTop = (_chartCenterY + vertBias - _cardHeight / 2)
        .clamp(4.0, _chartHeight + _reserveHeight - _cardHeight - 4.0);

    // La línea conecta el punto del anillo con el borde "cercano" de la card
    final lineEnd = Offset(
      rightLane ? cardLeft : cardLeft + _cardWidth,
      cardTop + _cardHeight / 2,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Línea de conexión
        Positioned.fill(
          child: CustomPaint(
            painter: _CalloutLinePainter(
              start: ringPoint,
              end: lineEnd,
              color: color,
            ),
          ),
        ),
        // Punto pulsante en el anillo
        Positioned(
          left: ringPoint.dx - 5,
          top: ringPoint.dy - 5,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: AppColors.textPrimary.op(0.4), width: 1),
              boxShadow: [BoxShadow(color: color.op(0.6), blurRadius: 8)],
            ),
          ),
        ),
        // Card con nombre y porcentaje
        Positioned(
          left: cardLeft,
          top: cardTop,
          width: _cardWidth,
          child: _CalloutCard(
            color: color,
            buyerName: stats[idx].buyerName,
            percent: stats[idx].probabilityPercent,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DonutPainter – diseño tecnológico profesional.
// Capas (fondo → frente):
//   0) Fondo del agujero interior + decoración radar
//   1) Glow ambiental por sección (blur suave, respira con glowPulse)
//   2) Arcos principales + rim highlight + inner edge
//   3) Anillo decorativo exterior con marcas de instrumento
//   4) Etiquetas % en las secciones grandes (solo sin hover)
//   5) Sección hover elevada con doble halo épico
// ─────────────────────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.stats,
    required this.colors,
    required this.innerRadius,
    required this.outerRadius,
    this.gapDeg = 1.2,
    this.touchedIndex = -1,
    this.hoverProgress = 0.0,
    this.glowPulse = 0.0,
  });

  final List<BuyerStats> stats;
  final List<Color> colors;
  final double innerRadius;
  final double outerRadius;
  final double gapDeg;
  final int touchedIndex;
  final double hoverProgress;
  final double glowPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return;

    final strokeWidth = outerRadius - innerRadius;
    final drawRadius = innerRadius + strokeWidth / 2;
    final gapRad = gapDeg * math.pi / 180;
    final halfGap = gapRad / 2;
    final hasHover = touchedIndex >= 0 && hoverProgress > 0;

    final starts = <double>[];
    final sweeps = <double>[];
    double ang = 0;
    for (final st in stats) {
      starts.add(ang);
      final sw = (st.ticketCount / total) * 2 * math.pi;
      sweeps.add(sw);
      ang += sw;
    }

    // ── Layer 0: Inner hole background + radar decoration ─────────────────────
    _paintInnerDecor(canvas, center);

    // ── Layer 1: Ambient glow — breathing (non-hover sections) ───────────────
    for (var i = 0; i < stats.length; i++) {
      if (i == touchedIndex) continue;
      final effStart = starts[i] + halfGap;
      final effSweep = sweeps[i] - gapRad;
      if (effSweep <= 0) continue;
      final color = colors[i % colors.length];
      final alpha = (0.08 + glowPulse * 0.07) * (hasHover ? 0.28 : 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: drawRadius),
        effStart, effSweep, false,
        Paint()
          ..color = color.op(alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 20
          ..strokeCap = StrokeCap.butt
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }

    // ── Layer 2: Main arcs (non-hover) ────────────────────────────────────────
    for (var i = 0; i < stats.length; i++) {
      if (i == touchedIndex) continue;
      final effStart = starts[i] + halfGap;
      final effSweep = sweeps[i] - gapRad;
      if (effSweep <= 0) continue;
      final color = colors[i % colors.length];
      final baseOp = hasHover ? 0.36 : 0.87;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: drawRadius),
        effStart, effSweep, false,
        Paint()
          ..color = color.op(baseOp)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );

      // Outer rim highlight — simula bisel 3D
      final rimAlpha = (0.28 + glowPulse * 0.18) * (hasHover ? 0.28 : 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius - 1.5),
        effStart, effSweep, false,
        Paint()
          ..color = color.op(rimAlpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Inner edge line
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius + 1.5),
        effStart, effSweep, false,
        Paint()
          ..color = color.op((baseOp * 0.45).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // ── Layer 3: Outer instrument ring + tick marks ───────────────────────────
    _paintOuterDecor(canvas, center);

    // ── Layer 4: % labels (only in idle state) ────────────────────────────────
    if (!hasHover) _paintLabels(canvas, center, starts, sweeps, total);

    // ── Layer 5: Hover section — elevated + epic double-glow ─────────────────
    if (touchedIndex >= 0 && touchedIndex < stats.length) {
      final effStart = starts[touchedIndex] + halfGap;
      final effSweep = sweeps[touchedIndex] - gapRad;
      if (effSweep > 0) {
        final mid = starts[touchedIndex] + sweeps[touchedIndex] / 2;
        final progress = hoverProgress.clamp(0.0, 1.0);
        final elevNorm = Curves.easeOutBack.transform(progress);
        final elevation = elevNorm * 16.0;
        final color = colors[touchedIndex % colors.length];

        canvas.save();
        canvas.translate(elevation * math.cos(mid), elevation * math.sin(mid));

        // Wide outer halo
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: drawRadius),
          effStart, effSweep, false,
          Paint()
            ..color = color.op((progress * 0.36).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + 26
            ..strokeCap = StrokeCap.butt
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
        );
        // Tight halo
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: drawRadius),
          effStart, effSweep, false,
          Paint()
            ..color = color.op((progress * 0.58).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + 7
            ..strokeCap = StrokeCap.butt
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        // Arc at 100% brightness
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: drawRadius),
          effStart, effSweep, false,
          Paint()
            ..color = color.op(1.0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt,
        );
        // Blazing rim highlight
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius - 1.5),
          effStart, effSweep, false,
          Paint()
            ..color = color.op(0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );

        canvas.restore();
      }
    }
  }

  void _paintInnerDecor(Canvas canvas, Offset center) {
    // Solid dark background for the hole
    canvas.drawCircle(center, innerRadius - 0.5,
        Paint()..color = const Color(0xFF030709)..style = PaintingStyle.fill);

    // Concentric guide rings (radar / target sight)
    for (final r in [innerRadius * 0.72, innerRadius * 0.44, innerRadius * 0.18]) {
      canvas.drawCircle(center, r,
          Paint()
            ..color = AppColors.primary.op(0.07)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6);
    }

    // Crosshair lines inside the hole
    for (var deg = 0.0; deg < 180; deg += 45) {
      final rad = deg * math.pi / 180;
      final r = innerRadius - 5;
      canvas.drawLine(
        Offset(center.dx - math.cos(rad) * r, center.dy - math.sin(rad) * r),
        Offset(center.dx + math.cos(rad) * r, center.dy + math.sin(rad) * r),
        Paint()
          ..color = AppColors.primary.op(0.07)
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintOuterDecor(Canvas canvas, Offset center) {
    final decoR   = outerRadius + 7.0;
    final tickIn  = outerRadius + 10.0;
    final tickOut = outerRadius + 16.0;

    // Primary thin ring (breathing)
    canvas.drawCircle(center, decoR,
        Paint()
          ..color = AppColors.primary.op(0.14 + glowPulse * 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);

    // Outer boundary ring
    canvas.drawCircle(center, tickOut + 2,
        Paint()
          ..color = AppColors.primary.op(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);

    // Instrument tick marks every 10°
    for (var deg = 0.0; deg < 360; deg += 10) {
      final isCardinal = deg % 90 == 0;
      final isMajor    = deg % 30 == 0;
      final rad  = deg * math.pi / 180;
      final cosA = math.cos(rad);
      final sinA = math.sin(rad);
      final inner = isMajor ? tickIn - 1.5 : tickIn + 1.5;
      final outer = isCardinal ? tickOut + 1.5 : isMajor ? tickOut : tickOut - 2.0;
      canvas.drawLine(
        Offset(center.dx + cosA * inner, center.dy + sinA * inner),
        Offset(center.dx + cosA * outer, center.dy + sinA * outer),
        Paint()
          ..color = AppColors.primary.op(isCardinal ? 0.55 : isMajor ? 0.24 : 0.10)
          ..strokeWidth = isCardinal ? 1.4 : isMajor ? 0.9 : 0.6,
      );
    }

    // Inner hole border (breathing)
    canvas.drawCircle(center, innerRadius - 1,
        Paint()
          ..color = AppColors.primary.op(0.18 + glowPulse * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);
  }

  void _paintLabels(Canvas canvas, Offset center, List<double> starts,
      List<double> sweeps, double total) {
    final labelR = outerRadius + 22.0;
    for (var i = 0; i < stats.length; i++) {
      final percent = stats[i].ticketCount / total * 100;
      if (percent < 8) continue;
      final midAngle = starts[i] + sweeps[i] / 2;
      final color = colors[i % colors.length];
      final pos = Offset(
        center.dx + labelR * math.cos(midAngle),
        center.dy + labelR * math.sin(midAngle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color.op(0.82),
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.stats != stats ||
      old.innerRadius != innerRadius ||
      old.outerRadius != outerRadius ||
      old.touchedIndex != touchedIndex ||
      old.hoverProgress != hoverProgress ||
      old.glowPulse != glowPulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// _CalloutLinePainter – línea recta simple del punto al borde de la card
// ─────────────────────────────────────────────────────────────────────────────
class _CalloutLinePainter extends CustomPainter {
  _CalloutLinePainter({
    required this.start,
    required this.end,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color.op(0.65)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CalloutLinePainter old) =>
      old.start != start || old.end != end || old.color != color;
}

class _SimulationNotification extends StatelessWidget {
  const _SimulationNotification();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.op(0.98),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.op(0.5)),
          boxShadow: [
            BoxShadow(color: AppColors.primary.op(0.2), blurRadius: 16),
            BoxShadow(color: Colors.black.op(0.25), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Esto es una simulación',
              style: TextStyle(fontFamily: 'Oxanium', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulatedWinnerBlock extends StatelessWidget {
  const _SimulatedWinnerBlock({required this.winnerName});

  final String winnerName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.prizeGreen.op(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.prizeGreen.op(0.35)),
          boxShadow: [BoxShadow(color: AppColors.prizeGreen.op(0.1), blurRadius: 12)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.trophy, color: AppColors.prizeGreen, size: 18),
            const SizedBox(width: 10),
            FaIcon(FontAwesomeIcons.cannabis, color: AppColors.prizeGreen, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                winnerName,
                style: const TextStyle(
                  fontFamily: 'Oxanium', fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FaIcon(FontAwesomeIcons.cannabis, color: AppColors.prizeGreen.op(0.8), size: 14),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.op(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.op(0.35)),
              ),
              child: const Text(
                'Simulación',
                style: TextStyle(
                  fontFamily: 'Oxanium', fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.8, color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNeedle extends StatelessWidget {
  const _CenterNeedle({required this.angleDeg});

  final double angleDeg;

  @override
  Widget build(BuildContext context) {
    final rotationRad = (angleDeg - 270) * math.pi / 180;
    return SizedBox(
      width: 96, height: 96,
      child: Transform.rotate(
        angle: rotationRad,
        child: CustomPaint(painter: _NeedlePainter(), size: const Size(96, 96)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NeedlePainter – hub de mira de precisión + aguja con glow
// ─────────────────────────────────────────────────────────────────────────────
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // ── Needle ────────────────────────────────────────────────────────────────
    final needle = Path()
      ..moveTo(cx, cy - 40)
      ..lineTo(cx - 5.5, cy + 5)
      ..lineTo(cx - 1.5, cy + 3)
      ..lineTo(cx, cy + 10)
      ..lineTo(cx + 1.5, cy + 3)
      ..lineTo(cx + 5.5, cy + 5)
      ..close();

    // Needle glow
    canvas.drawPath(needle,
        Paint()
          ..color = AppColors.primary.op(0.30)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Needle body
    canvas.drawPath(needle, Paint()..color = AppColors.secondary..style = PaintingStyle.fill);
    canvas.drawPath(needle,
        Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 0.9);

    // ── Hub — targeting sight ──────────────────────────────────────────────────
    // Outer glow halo
    canvas.drawCircle(center, 17,
        Paint()
          ..color = AppColors.primary.op(0.12)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Dark fill background
    canvas.drawCircle(center, 13,
        Paint()..color = const Color(0xFF020608)..style = PaintingStyle.fill);

    // Concentric precision rings
    final rings = [
      (13.0, 1.5, 0.85),
      (9.5,  0.9, 0.38),
      (6.0,  0.7, 0.22),
    ];
    for (final r in rings) {
      canvas.drawCircle(center, r.$1,
          Paint()
            ..color = AppColors.primary.op(r.$3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r.$2);
    }

    // Crosshair tick marks on hub
    for (var deg = 0.0; deg < 360; deg += 90) {
      final rad = deg * math.pi / 180;
      canvas.drawLine(
        Offset(center.dx + math.cos(rad) * 6.5, center.dy + math.sin(rad) * 6.5),
        Offset(center.dx + math.cos(rad) * 11,  center.dy + math.sin(rad) * 11),
        Paint()..color = AppColors.primary.op(0.45)..strokeWidth = 0.9,
      );
    }

    // Center dot
    canvas.drawCircle(center, 3.5,
        Paint()..color = AppColors.primary..style = PaintingStyle.fill);
    canvas.drawCircle(center, 3.5,
        Paint()
          ..color = AppColors.primary.op(0.55)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({required this.color, required this.buyerName, required this.percent});

  final Color color;
  final String buyerName;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.op(0.5)),
        boxShadow: [
          BoxShadow(color: color.op(0.18), blurRadius: 14),
          BoxShadow(color: Colors.black.op(0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.op(0.5), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              buyerName,
              style: const TextStyle(
                fontFamily: 'Oxanium', fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: 'Oxanium', fontSize: 12, fontWeight: FontWeight.bold, color: color,
            ),
          ),
        ],
      ),
    );
  }
}
