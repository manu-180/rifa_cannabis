import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/domain/models/buyer_stats.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

const _reserveHeight = 72.0;
const _chartHeight = 200.0;

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
  }

  @override
  void dispose() {
    _needleController.dispose();
    super.dispose();
  }

  /// Secciones del PieChart. El índice tocado NO afecta la geometría (radio/color fijos).
  /// Si no hay datos, un solo segmento con color primario evita el círculo gris (p. ej. en web).
  List<PieChartSectionData> _buildSections(List<BuyerStats> stats) {
    if (stats.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: '',
          color: AppColors.primary.withValues(alpha: 0.4),
          radius: 52,
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1),
        ),
      ];
    }
    return stats.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      final color = _colors[i % _colors.length];
      // Una sola sección (100%): color opaco para que no se vea gris/blanquecino en producción/web.
      final useSolid = stats.length == 1;
      return PieChartSectionData(
        value: s.ticketCount.toDouble(),
        title: '',
        color: useSolid ? color : color.withValues(alpha: 0.85),
        radius: 52,
        borderSide: BorderSide(color: color.withValues(alpha: useSolid ? 0.6 : 0.5), width: 1),
      );
    }).toList();
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
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderHighlight.withValues(alpha: 0.6)),
          ),
          child: Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
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
    // Las secciones se crean una vez y no cambian con el hover.
    final sections = _buildSections(stats);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final centerX = w / 2;

        return SizedBox(
          height: _chartHeight + _reserveHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1) PieChart: recibe hover directamente (nada encima lo bloquea).
              SizedBox(
                height: _chartHeight,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 1.5,
                    centerSpaceRadius: 42,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: sections,
                  ),
                ),
              ),

              // 2) Aguja: IgnorePointer para que no robe hover al PieChart.
              if (stats.isNotEmpty)
                SizedBox(
                  height: _chartHeight,
                  child: Center(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _needleController,
                        builder: (context, _) {
                          final angle = _needleAngleDeg(stats);
                          return _CenterNeedle(angleDeg: (angle * 100).round() / 100.0);
                        },
                      ),
                    ),
                  ),
                ),

              // 3) Callout: SIEMPRE en el árbol, SIEMPRE IgnorePointer.
              //    Usa Opacity para mostrar/ocultar SIN agregar/quitar widgets.
              //    IgnorePointer hace que NUNCA bloquee los eventos del PieChart.
              IgnorePointer(
                child: _CalloutLayer(
                  touchedIndex: _touchedIndex,
                  stats: stats,
                  chartWidth: w,
                  centerX: centerX,
                ),
              ),

              // 4) Ganador simulado (zona reservada abajo).
              if (_simulatedSectionIndex != null &&
                  _simulatedWinnerName != null &&
                  _simulatedSectionIndex! < stats.length)
                Positioned(
                  left: 0, right: 0,
                  top: _chartHeight,
                  height: _reserveHeight,
                  child: IgnorePointer(
                    child: _SimulatedWinnerBlock(winnerName: _simulatedWinnerName!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Capa del callout (punto + línea L + card). Siempre en el árbol, se muestra/oculta con Opacity.
class _CalloutLayer extends StatelessWidget {
  const _CalloutLayer({
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
  /// Margen extra entre el anillo del donut y la card (para que no quede encimada).
  static const _gapFromRing = 28.0;
  /// En zona abajo: empuja la card un poco más abajo del chart.
  static const _extraGapBelowChart = 14.0;

  double _middleDegreeForSection(int index) {
    final total = stats.fold<double>(0, (s, e) => s + e.ticketCount);
    if (total <= 0) return 0;
    double cumulative = 0;
    for (var i = 0; i < index; i++) cumulative += stats[i].ticketCount;
    final sectionSpan = (stats[index].ticketCount / total) * 360;
    return cumulative / total * 360 + sectionSpan / 2;
  }

  Offset _pointOnRing(double degreeDeg) {
    final rad = degreeDeg * math.pi / 180;
    return Offset(
      centerX + _ringRadius * math.cos(rad),
      _chartCenterY + _ringRadius * math.sin(rad),
    );
  }

  static double _normDeg(double deg) => (deg % 360 + 360) % 360;

  _CalloutZone _zoneForAngle(double deg) {
    final a = _normDeg(deg);
    if (a >= 270 || a < 60) return _CalloutZone.right;
    if (a >= 60 && a < 120) return _CalloutZone.bottom;
    return _CalloutZone.left;
  }

  @override
  Widget build(BuildContext context) {
    final valid = touchedIndex >= 0 && touchedIndex < stats.length;

    // Si no es válido: renderiza un Positioned.fill vacío (mismo tipo de widget, no cambia estructura del árbol).
    if (!valid) {
      return Positioned.fill(child: const SizedBox.shrink());
    }

    final idx = touchedIndex;
    final angleDeg = _middleDegreeForSection(idx);
    final point = _pointOnRing(angleDeg);
    final color = _colors[idx % _colors.length];
    final zone = _zoneForAngle(angleDeg);
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

    return Positioned.fill(
      child: CustomPaint(
        painter: _CalloutPainter(point: point, elbow: elbow, lineEnd: lineEnd, pointColor: color),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: point.dx - 5,
              top: point.dy - 5,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.4), width: 1),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                ),
              ),
            ),
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
        ),
      ),
    );
  }
}

enum _CalloutZone { left, bottom, right }

class _CalloutPainter extends CustomPainter {
  _CalloutPainter({
    required this.point,
    required this.elbow,
    required this.lineEnd,
    required this.pointColor,
  });

  final Offset point;
  final Offset elbow;
  final Offset lineEnd;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(point.dx, point.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(lineEnd.dx, lineEnd.dy);

    final linePaint = Paint()
      ..color = pointColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CalloutPainter old) =>
      old.point != point || old.elbow != elbow || old.lineEnd != lineEnd || old.pointColor != pointColor;
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
          color: AppColors.surface.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16),
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
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
          color: AppColors.prizeGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.prizeGreen.withValues(alpha: 0.35)),
          boxShadow: [BoxShadow(color: AppColors.prizeGreen.withValues(alpha: 0.1), blurRadius: 12)],
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
                style: const TextStyle(fontFamily: 'Oxanium', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FaIcon(FontAwesomeIcons.cannabis, color: AppColors.prizeGreen.withValues(alpha: 0.8), size: 14),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Simulación',
                style: TextStyle(fontFamily: 'Oxanium', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primary),
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

    canvas.drawCircle(Offset(cx, cy), 8, Paint()..color = AppColors.surface..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 8, Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = AppColors.primary.withValues(alpha: 0.4)..style = PaintingStyle.fill);

    final path = Path()
      ..moveTo(cx, cy - 32)
      ..lineTo(cx - 6, cy + 4)
      ..lineTo(cx - 2, cy + 2)
      ..lineTo(cx, cy + 8)
      ..lineTo(cx + 2, cy + 2)
      ..lineTo(cx + 6, cy + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = AppColors.secondary.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1);
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
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12),
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
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
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              buyerName,
              style: const TextStyle(fontFamily: 'Oxanium', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(fontFamily: 'Oxanium', fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
