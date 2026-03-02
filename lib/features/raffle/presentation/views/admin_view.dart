import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/core/widgets/premium_background.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';

/// Vista admin: agregar números (nombre + uno o más números). Mismo nombre = se suman chances.
class AdminView extends ConsumerStatefulWidget {
  const AdminView({super.key});

  @override
  ConsumerState<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends ConsumerState<AdminView> {
  final _nameCtrl = TextEditingController();
  final _numbersCtrl = TextEditingController();
  final _numbersFocusNode = FocusNode();
  bool _loading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numbersCtrl.dispose();
    _numbersFocusNode.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() {
        _message = 'Ingresá el nombre del comprador.';
        _isError = true;
      });
      return;
    }
    final parts = _numbersCtrl.text.trim().split(RegExp(r'[\s,]+'));
    final numbers = <int>[];
    for (final p in parts) {
      if (p.isEmpty) continue;
      final n = int.tryParse(p);
      if (n == null || n < 1 || n > 100) {
        setState(() {
          _message = 'Números deben ser del 1 al 100 (separados por coma o espacio).';
          _isError = true;
        });
        return;
      }
      numbers.add(n);
    }
    if (numbers.isEmpty) {
      setState(() {
        _message = 'Ingresá al menos un número.';
        _isError = true;
      });
      return;
    }

    setState(() {
      _message = null;
      _loading = true;
    });

    final repo = ref.read(raffleRepositoryProvider);
    int ok = 0;
    String? lastError;
    for (final num in numbers) {
      try {
        await repo.assignTicket(number: num, buyerName: name);
        ok++;
      } catch (e) {
        lastError = e.toString().contains('duplicate') || e.toString().contains('unique')
            ? 'El número $num ya está vendido.'
            : e.toString();
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
        if (lastError != null && ok == 0) {
          _message = lastError;
          _isError = true;
        } else if (ok > 0) {
          _message = 'Se asignaron $ok número(s) a "$name".';
          _isError = false;
          if (ok == numbers.length) {
            _numbersCtrl.clear();
          } else {
            _numbersCtrl.text = numbers.where((n) {
              return true;
            }).join(', ');
          }
          // Cerrar y volver al talonario; el stream en tiempo real ya actualiza la vista.
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sold = ref.watch(raffleTicketsProvider).map((t) => t.number).toSet();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Administrar números'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: PremiumCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note, color: AppColors.primary, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'ASIGNAR NÚMEROS',
                        style: TextStyle(
                          fontFamily: 'Oxanium',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mismo nombre = más números = más chances. Ingresá números separados por coma o espacio.',
                    style: TextStyle(
                      fontFamily: 'Oxanium',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).requestFocus(_numbersFocusNode),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del comprador',
                      hintText: 'Ej: Juan Pérez',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _numbersCtrl,
                    focusNode: _numbersFocusNode,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _assign(),
                    decoration: InputDecoration(
                      labelText: 'Números (1-100)',
                      hintText: 'Ej: 5, 12, 33 o 5 12 33',
                      helperText: 'Números ya vendidos: ${sold.length}/100',
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (_isError ? AppColors.error : AppColors.success).op(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_isError ? AppColors.error : AppColors.success).op(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isError ? Icons.error_outline : Icons.check_circle_outline,
                            size: 20,
                            color: _isError ? AppColors.error : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: const TextStyle(
                                fontFamily: 'Oxanium',
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _assign,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Asignar números'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),  // SingleChildScrollView
        ],
      ),
    );
  }
}
