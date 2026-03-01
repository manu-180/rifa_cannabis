import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rifa_cannabis/core/config/theme/app_colors.dart';
import 'package:rifa_cannabis/features/raffle/presentation/providers/raffle_provider.dart';
import 'package:rifa_cannabis/features/raffle/presentation/widgets/premium_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp de Manu (Argentina: 54 9 11 34272488).
const String kWhatsAppNumber = '5491134272488';

Future<void> _openWhatsApp(BuildContext context, Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp. Escribile a Manu manualmente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Una sola card que engloba Valores (1/2 números) y CTA para escribir a Manu. Diseño profesional.
class PurchaseCtaCard extends ConsumerWidget {
  const PurchaseCtaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedQuantityProvider);
    final isWide = MediaQuery.of(context).size.width > 560;

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.sell_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'VALORES Y RESERVA',
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ValuesSection(selected: selected, ref: ref)),
                    Container(
                      width: 1,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: AppColors.borderGlass,
                    ),
                    Expanded(child: _ContactSection(selected: selected)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ValuesSection(selected: selected, ref: ref),
                    const SizedBox(height: 20),
                    Container(height: 1, color: AppColors.borderGlass),
                    const SizedBox(height: 20),
                    _ContactSection(selected: selected),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ValuesSection extends StatelessWidget {
  final int selected;
  final WidgetRef ref;

  const _ValuesSection({required this.selected, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Elegí tu opción',
          style: TextStyle(
            fontFamily: 'Oxanium',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _PriceRow(
          amount: r'$10.000',
          label: '1 número',
          isSelected: selected == 1,
          onTap: () => ref.read(selectedQuantityProvider.notifier).state = 1,
        ),
        const SizedBox(height: 8),
        _PriceRow(
          amount: r'$15.000',
          label: '2 números',
          isSelected: selected == 2,
          onTap: () => ref.read(selectedQuantityProvider.notifier).state = 2,
        ),
      ],
    );
  }
}

class _PriceRow extends StatefulWidget {
  final String amount;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceRow({
    required this.amount,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PriceRow> createState() => _PriceRowState();
}

class _PriceRowState extends State<_PriceRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _hover;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: widget.isSelected ? 0.18 : 0.1)
                : AppColors.background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: widget.isSelected ? 0.6 : 0.4)
                  : AppColors.borderGlass,
              width: active ? 1.2 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                      ),
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'Oxanium',
                          fontSize: 14,
                          color: active ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.amount,
                style: TextStyle(
                  fontFamily: 'Oxanium',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final int selected;

  const _ContactSection({required this.selected});

  @override
  Widget build(BuildContext context) {
    final isOne = selected == 1;
    final message = 'Hola Manu, quiero reservar $selected ${selected == 1 ? "número" : "números"} para la rifa.';
    final uri = Uri.parse(
      'https://wa.me/$kWhatsAppNumber?text=${Uri.encodeComponent(message)}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOne
              ? 'Escribile por WhatsApp para reservar un número.'
              : 'Escribile por WhatsApp para reservar dos números.',
          style: TextStyle(
            fontFamily: 'Oxanium',
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openWhatsApp(context, uri),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.whatsapp, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Escribir a Manu',
                      style: TextStyle(
                        fontFamily: 'Oxanium',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            isOne ? '1 número seleccionado' : '2 números seleccionados',
            style: TextStyle(
              fontFamily: 'Oxanium',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
