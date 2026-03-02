import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/raffle_config.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';

String _monthName(int month) {
  const names = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
  return names[month];
}

/// Contador regresivo hasta el sorteo; al llegar a 0 ejecuta el sorteo y se muestra al ganador.
class CountdownCard extends ConsumerStatefulWidget {
  const CountdownCard({super.key});

  static DateTime get drawDate => raffleDrawDate;

  @override
  ConsumerState<CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends ConsumerState<CountdownCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _drawTriggered = false;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final target = CountdownCard.drawDate;
    final now = DateTime.now();
    if (now.isAfter(target) || now.isAtSameMomentAs(target)) {
      setState(() => _remaining = Duration.zero);
      _timer?.cancel();
      _runDrawIfNeeded();
      return;
    }
    setState(() => _remaining = target.difference(now));
  }

  void _runDrawIfNeeded() async {
    if (_drawTriggered) return;
    _drawTriggered = true;
    final tickets = ref.read(raffleTicketsProvider);
    if (tickets.isEmpty) return;
    final stats = ref.read(buyerStatsProvider);
    if (stats.isEmpty) return;
    final rnd = Random();
    final ticket = tickets[rnd.nextInt(tickets.length)];
    final winnerKey = ticket.buyerName.trim().toLowerCase();
    int sectionIndex = 0;
    for (var i = 0; i < stats.length; i++) {
      if (stats[i].buyerName.trim().toLowerCase() == winnerKey) {
        sectionIndex = i;
        break;
      }
    }
    final winnerName = stats[sectionIndex].buyerName;
    final total = stats.fold<int>(0, (s, e) => s + e.ticketCount);
    double cumulative = 0;
    for (var i = 0; i < sectionIndex; i++) cumulative += stats[i].ticketCount;
    final sectionSpan = total > 0 ? (stats[sectionIndex].ticketCount / total) * 360 : 360.0;
    final sectionStart = total > 0 ? cumulative / total * 360 : 0.0;
    final needleAngle = sectionStart + sectionSpan * rnd.nextDouble();
    try {
      await ref.read(raffleRepositoryProvider).saveDrawResult(
        winnerName: winnerName,
        winningNumber: ticket.number,
        sectionIndex: sectionIndex,
        needleAngle: needleAngle,
      );
    } catch (_) {}
    ref.read(winnerNameProvider.notifier).update((_) => winnerName);
    ref.read(winnerSectionIndexProvider.notifier).update((_) => sectionIndex);
    ref.read(winnerNeedleAngleProvider.notifier).update((_) => needleAngle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    final isDone = _remaining <= Duration.zero;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.only(top: 1, left: 24, right: 24, bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF0B1322),
          border: Border.all(
            color: _hover ? AppColors.primary.op(0.5) : AppColors.borderGlass,
            width: 1,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: AppColors.primary.op(0.12),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.op(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.op(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Franja superior acento
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.op(0.9),
                      AppColors.secondary.op(0.8),
                      AppColors.primary.op(0.5),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CUENTA REGRESIVA',
                    style: TextStyle(
                      fontFamily: 'Oxanium',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: AppColors.primary.op(0.95),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${raffleDrawDate.day} de ${_monthName(raffleDrawDate.month)} · ${raffleDrawDate.hour.toString().padLeft(2, '0')}:${raffleDrawDate.minute.toString().padLeft(2, '0')} hs',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary.op(0.95),
                ),
              ),
              const SizedBox(height: 22),
              if (isDone)
                _buildDoneState()
              else
                _buildCountdown(d, h, m, s),
            ],
        ),
      ),
    );
  }

  Widget _buildDoneState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.op(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.op(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: 12),
          Text(
            '¡Sorteo realizado!',
            style: TextStyle(
              fontFamily: 'Oxanium',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(int d, int h, int m, int s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TimeBlock(value: d, label: 'DÍAS'),
        _SeparatorDot(),
        _TimeBlock(value: h, label: 'HRS'),
        _SeparatorDot(),
        _TimeBlock(value: m, label: 'MIN'),
        _SeparatorDot(),
        _TimeBlock(value: s, label: 'SEG'),
      ],
    );
  }
}

class _SeparatorDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: 'Oxanium',
          fontSize: 26,
          fontWeight: FontWeight.w300,
          color: AppColors.primary.op(0.5),
          height: 1.0,
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final int value;
  final String label;

  const _TimeBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF081018),
            border: Border.all(
              color: AppColors.primary.op(0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.op(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontFamily: 'Oxanium',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              height: 1.0,
              color: AppColors.textPrimary,
              shadows: [
                Shadow(
                  color: AppColors.primary.op(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
                Shadow(
                  color: AppColors.primary.op(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Oxanium',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: AppColors.textSecondary.op(0.9),
          ),
        ),
      ],
    );
  }
}
