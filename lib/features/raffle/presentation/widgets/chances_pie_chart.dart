import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/buyer_stats.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

const _reserveHeight = 72.0;
const _chartHeight = 200.0;
const _innerRadius = 42.0;
const _outerRadius = 94.0;

// Logs de diagnóstico solo en release; en debug ya se ven los errores de widget.
void _log(String msg) => debugPrint('[PIE_CHART] $msg');

class ChancesPieChart extends ConsumerStatefulWidget {
  const ChancesPieChart({super.key});

  @override
  ConsumerState<ChancesPieChart> createState() => _ChancesPieChartState();
}

class _ChancesPieChartState extends ConsumerState<ChancesPieChart>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;

  late final AnimationController _needleController;
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
    _log('runSimulation: stats.length=${stats.length}');
    if (stats.isEmpty) return;
    final picked = _pickWeightedRandomSection(stats);
    final randomAngle = _randomDegreeInSection(picked, stats);
    _log('runSimulation: picked=$picked angle=$randomAngle');
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
    _log('initState');
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addStatusListener((status) {
        _log('needle animation status: $status');
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
  }

  @override
  void dispose() {
    _log('dispose');
    _needleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('build() start');
    final stats = ref.watch(buyerStatsProvider);
    _log('build() stats.length=${stats.length}');

    final winnerIdx = ref.watch(winnerSectionIndexProvider);
    final winnerAngle = ref.watch(winnerNeedleAngleProvider);
    _log('build() winnerIdx=$winnerIdx winnerAngle=$winnerAngle');

    if (winnerIdx != null && stats.isNotEmpty && winnerIdx < stats.length && !_needleAnimationScheduled) {
      _needleTargetAngleDeg = winnerAngle ?? _middleDegreeForSection(winnerIdx, stats);
      _needleAnimationScheduled = true;
      _log('build() scheduling needle animation to $_needleTargetAngleDeg');
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
          const SizedBox(height: 20),
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
    _log('_buildChartArea: stats.length=${stats.length} touchedIndex=$_touchedIndex');

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final centerX = w / 2;
        final centerY = _chartHeight / 2;
        _log('_buildChartArea LayoutBuilder: w=$w centerX=$centerX');

        // Estado del ganador simulado — calculado aquí para no cambiar
        // la estructura del árbol de widgets condicionalmente.
        final showSimWinner = _simulatedSectionIndex != null &&
            _simulatedWinnerName != null &&
            _simulatedSectionIndex! < stats.length;
        _log('_buildChartArea: showSimWinner=$showSimWinner simWinner=$_simulatedWinnerName');

        return SizedBox(
          height: _chartHeight + _reserveHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── 1) Donut chart ───────────────────────────────────────────
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
                      _log('hover: touchedIndex=$idx');
                      setState(() => _touchedIndex = idx);
                    }
                  },
                  onExit: (_) {
                    if (_touchedIndex != -1) {
                      _log('hover exit');
                      setState(() => _touchedIndex = -1);
                    }
                  },
                  child: GestureDetector(
                    onTapDown: (details) {
                      final offset = Offset(
                        details.localPosition.dx - centerX,
                        details.localPosition.dy - centerY,
                      );
                      final idx = _hitTestSection(offset, stats);
                      _log('tap: touchedIndex=$idx');
                      setState(() => _touchedIndex = idx);
                    },
                    child: CustomPaint(
                      size: Size(w, _chartHeight),
                      painter: _DonutPainter(
                        stats: stats,
                        colors: _colors,
                        innerRadius: _innerRadius,
                        outerRadius: _outerRadius,
                        gapDeg: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // ── 2) Aguja ─────────────────────────────────────────────────
              // Siempre presente (no condicional) para no cambiar estructura.
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

              // ── 3) Callout ───────────────────────────────────────────────
              // FIX CRÍTICO: Positioned.fill AQUÍ en el Stack, NO dentro del
              // IgnorePointer. Un ParentDataWidget (Positioned) debe ser hijo
              // directo del Stack; de lo contrario dart2js en release mode
              // falla con un type cast de StackParentData.
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

              // ── 4) Ganador simulado ──────────────────────────────────────
              // Siempre presente con Opacity para NO agregar/quitar Positioned
              // del árbol (cambios estructurales en Stack también causan el
              // cast failure en release mode).
              Positioned(
                left: 0, right: 0,
                top: _chartHeight,
                height: _reserveHeight,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: showSimWinner ? 1.0 : 0.0,
                    child: showSimWinner
                        ? _SimulatedWinnerBlock(winnerName: _simulatedWinnerName!)
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CalloutContent: reemplaza _CalloutLayer.
// Ahora es hijo de Positioned.fill > IgnorePointer, así que llena el espacio
// disponible. Devuelve un Stack interno con los elementos del callout.
// NUNCA devuelve Positioned.fill (eso causaba el type cast failure).
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

  static const _ringRadius = 54.0;
  static const _chartCenterY = _chartHeight / 2;
  static const _cardWidth = 160.0;
  static const _cardHeight = 44.0;
  static const _margin = 12.0;
  static const _gapFromRing = 28.0;
  static const _extraGapBelowChart = 14.0;

  double _middleDegForSection(int index) {
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return 0;
    double cumulative = 0;
    for (var i = 0; i < index; i++) cumulative += stats[i].ticketCount;
    final span = (stats[index].ticketCount / total) * 360;
    return cumulative / total * 360 + span / 2;
  }

  Offset _pointOnRing(double deg) {
    final rad = deg * math.pi / 180;
    return Offset(
      centerX + _ringRadius * math.cos(rad),
      _chartCenterY + _ringRadius * math.sin(rad),
    );
  }

  static double _normDeg(double deg) => (deg % 360 + 360) % 360;

  _CalloutZone _zone(double deg) {
    final a = _normDeg(deg);
    if (a >= 270 || a < 60) return _CalloutZone.right;
    if (a >= 60 && a < 120) return _CalloutZone.bottom;
    return _CalloutZone.left;
  }

  @override
  Widget build(BuildContext context) {
    _log('_CalloutContent.build: touchedIndex=$touchedIndex stats=${stats.length}');

    final valid = touchedIndex >= 0 && touchedIndex < stats.length;
    if (!valid) {
      // Retorna SizedBox.expand() — ocupa el espacio pero no dibuja nada.
      return const SizedBox.expand();
    }

    _log('_CalloutContent: mostrando callout para idx=$touchedIndex');

    final idx = touchedIndex;
    final angleDeg = _middleDegForSection(idx);
    final point = _pointOnRing(angleDeg);
    final color = _colors[idx % _colors.length];
    final zone = _zone(angleDeg);
    final w = chartWidth;
    final reserveCenterY = _chartHeight + _reserveHeight / 2;

    double cardLeft;
    double cardTop;
    Offset elbow;
    Offset lineEnd;

    switch (zone) {
      case _CalloutZone.right:
        cardLeft = math.min(centerX + _ringRadius + _gapFromRing, w - _cardWidth - _margin);
        cardLeft = math.max(_margin, cardLeft);
        cardTop = _chartCenterY - _cardHeight / 2;
        elbow = Offset(cardLeft, point.dy);
        lineEnd = Offset(cardLeft, _chartCenterY);
        break;
      case _CalloutZone.left:
        cardLeft = math.max(_margin, centerX - _ringRadius - _gapFromRing - _cardWidth);
        cardLeft = math.min(cardLeft, w - _cardWidth - _margin);
        cardTop = _chartCenterY - _cardHeight / 2;
        elbow = Offset(cardLeft + _cardWidth, point.dy);
        lineEnd = Offset(cardLeft + _cardWidth, _chartCenterY);
        break;
      case _CalloutZone.bottom:
        cardLeft = centerX - _cardWidth / 2;
        cardLeft = math.max(_margin, math.min(cardLeft, w - _cardWidth - _margin));
        cardTop = reserveCenterY - _cardHeight / 2 + _extraGapBelowChart;
        elbow = Offset(point.dx, cardTop);
        lineEnd = Offset(cardLeft + _cardWidth / 2, cardTop);
        break;
    }

    // Stack normal (no Positioned.fill) — su padre ya es Positioned.fill.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Línea L del callout (CustomPaint sobre toda el área)
        Positioned.fill(
          child: CustomPaint(
            painter: _CalloutLinePainter(
              point: point,
              elbow: elbow,
              lineEnd: lineEnd,
              color: color,
            ),
          ),
        ),
        // Punto en el anillo
        Positioned(
          left: point.dx - 5,
          top: point.dy - 5,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: AppColors.textPrimary.op(0.4), width: 1),
              boxShadow: [BoxShadow(color: color.op(0.5), blurRadius: 6)],
            ),
          ),
        ),
        // Card del comprador
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

enum _CalloutZone { left, bottom, right }

// ─────────────────────────────────────────────────────────────────────────────
// Painters y widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.stats,
    required this.colors,
    required this.innerRadius,
    required this.outerRadius,
    this.gapDeg = 1.2,
  });

  final List<BuyerStats> stats;
  final List<Color> colors;
  final double innerRadius;
  final double outerRadius;
  final double gapDeg;

  @override
  void paint(Canvas canvas, Size size) {
    _log('_DonutPainter.paint: ${stats.length} secciones size=$size');
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) {
      _log('_DonutPainter: total=0, nada que dibujar');
      return;
    }

    final strokeWidth = outerRadius - innerRadius;
    final drawRadius = innerRadius + strokeWidth / 2;
    final gapRad = gapDeg * math.pi / 180;
    final halfGap = gapRad / 2;

    double startAngle = 0;

    for (var i = 0; i < stats.length; i++) {
      final sweepAngle = (stats[i].ticketCount / total) * 2 * math.pi;
      final effectiveStart = startAngle + halfGap;
      final effectiveSweep = sweepAngle - gapRad;

      if (effectiveSweep > 0) {
        final color = colors[i % colors.length];
        final rect = Rect.fromCircle(center: center, radius: drawRadius);

        canvas.drawArc(
          rect, effectiveStart, effectiveSweep, false,
          Paint()
            ..color = color.op(0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt,
        );

        final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
        canvas.drawArc(outerRect, effectiveStart, effectiveSweep, false,
          Paint()..color = color.op(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);

        final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
        canvas.drawArc(innerRect, effectiveStart, effectiveSweep, false,
          Paint()..color = color.op(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }
      startAngle += sweepAngle;
    }
    _log('_DonutPainter.paint: OK');
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.stats != stats || old.innerRadius != innerRadius || old.outerRadius != outerRadius;
}

class _CalloutLinePainter extends CustomPainter {
  _CalloutLinePainter({
    required this.point,
    required this.elbow,
    required this.lineEnd,
    required this.color,
  });

  final Offset point;
  final Offset elbow;
  final Offset lineEnd;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(point.dx, point.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(lineEnd.dx, lineEnd.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.op(0.65)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CalloutLinePainter old) =>
      old.point != point || old.elbow != elbow || old.lineEnd != lineEnd || old.color != color;
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
    _log('_SimulatedWinnerBlock.build: winner=$winnerName');
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
      width: 86, height: 86,
      child: Transform.rotate(
        angle: rotationRad,
        child: CustomPaint(painter: _NeedlePainter(), size: const Size(86, 86)),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawCircle(Offset(cx, cy), 8,
      Paint()..color = AppColors.surface..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 8,
      Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, cy), 6,
      Paint()..color = AppColors.primary.op(0.4)..style = PaintingStyle.fill);

    final path = Path()
      ..moveTo(cx, cy - 32)
      ..lineTo(cx - 6, cy + 4)
      ..lineTo(cx - 2, cy + 2)
      ..lineTo(cx, cy + 8)
      ..lineTo(cx + 2, cy + 2)
      ..lineTo(cx + 6, cy + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = AppColors.secondary.op(0.6)..style = PaintingStyle.stroke..strokeWidth = 1);
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
          BoxShadow(color: color.op(0.15), blurRadius: 12),
          BoxShadow(color: Colors.black.op(0.25), blurRadius: 8, offset: const Offset(0, 2)),
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
