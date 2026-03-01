import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Número de usuarios viendo la página en tiempo real (Supabase Realtime Presence).
/// Se actualiza cuando el widget de presencia está montado y suscrito al canal.
final presenceViewersCountProvider = StateProvider<int>((ref) => 0);
