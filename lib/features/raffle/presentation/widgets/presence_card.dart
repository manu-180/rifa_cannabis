import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/core/providers/supabase_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/presence_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/presence_leader_storage.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:supabase/supabase.dart';

/// Widget tipo Apex: muestra cuántos usuarios están viendo la página en tiempo real.
/// Hover: se resalta; clic: abre popover con lista "Anónimos" y marca "Tú" al que está viendo.
class PresenceCard extends ConsumerStatefulWidget {
  const PresenceCard({super.key});

  @override
  ConsumerState<PresenceCard> createState() => _PresenceCardState();
}

class _PresenceCardState extends ConsumerState<PresenceCard> {
  RealtimeChannel? _channel;
  bool _initialized = false;
  bool _hover = false;
  String? _myClientId;
  Timer? _heartbeatTimer;

  static String _generateClientId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(0x7FFFFFFF)}';
  }

  void _doTrack() {
    _channel?.track({
      'online_at': DateTime.now().toIso8601String(),
      'client_id': _myClientId,
    });
  }

  void _initChannel(WidgetRef ref) {
    if (_channel != null) return;
    _myClientId = _generateClientId();
    final client = ref.read(supabaseClientProvider);
    _channel = client.channel(
      'raffle-viewers',
      opts: const RealtimeChannelConfig(enabled: true),
    );
    _channel!.onPresenceSync((_) {
      final count = _channel!.presenceState().length;
      ref.read(presenceViewersCountProvider.notifier).update((_) => count);
    });
    _channel!.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (presenceAmILeader() || presenceTryClaimLeader()) _doTrack();
        _heartbeatTimer?.cancel();
        _heartbeatTimer = Timer.periodic(
          const Duration(seconds: 2),
          (_) => presenceHeartbeatTick(() {
            if (mounted && _channel != null) _doTrack();
          }),
        );
      }
    });
  }

  bool _isMe(SinglePresenceState state) {
    if (_myClientId == null) return false;
    for (final p in state.presences) {
      final id = p.payload['client_id'];
      if (id == _myClientId) return true;
    }
    return false;
  }

  void _showPresencePopover(BuildContext context) {
    final state = _channel?.presenceState() ?? <SinglePresenceState>[];
    if (state.isEmpty) return;

    final overlay = context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final pos = overlay.localToGlobal(Offset.zero);
    final size = overlay.size;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy + size.height + 6,
        pos.dx + size.width,
        pos.dy + size.height + 200,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderGlass),
      ),
      color: AppColors.surface,
      elevation: 8,
      items: [
        PopupMenuItem<void>(
          enabled: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Viendo ahora',
                  style: TextStyle(
                    fontFamily: 'Oxanium',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Anónimos',
                  style: TextStyle(
                    fontFamily: 'Oxanium',
                    fontSize: 10,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                ...state.map((s) {
                  final isMe = _isMe(s);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.prizeGreen
                                : AppColors.textSecondary.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMe ? 'Tú' : 'Anónimo',
                          style: TextStyle(
                            fontFamily: 'Oxanium',
                            fontSize: 13,
                            fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                            color: isMe
                                ? AppColors.prizeGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(tú estás viendo)',
                            style: TextStyle(
                              fontFamily: 'Oxanium',
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      _initChannel(ref);
    }
    final count = ref.watch(presenceViewersCountProvider);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showPresencePopover(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hover ? AppColors.surface.withValues(alpha: 0.95) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hover ? AppColors.primary.withValues(alpha: 0.5) : AppColors.borderGlass,
              width: 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.prizeGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.prizeGreen.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                count == 1 ? '1 online' : '$count online',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hover ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
