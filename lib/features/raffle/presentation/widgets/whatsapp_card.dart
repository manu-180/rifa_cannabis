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

/// Card CTA: comprar 1 o 2 números por WhatsApp. Texto dinámico según selección.
class WhatsAppCard extends ConsumerWidget {
  const WhatsAppCard({super.key});

  static String _message(int quantity) {
    return 'Hola Manu, quiero reservar $quantity ${quantity == 1 ? "número" : "números"} para la rifa.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(selectedQuantityProvider);
    final isOne = quantity == 1;

    final title = isOne
        ? 'Comprar un número'
        : 'Comprar dos números';
    final subtitle = isOne
        ? 'Escribile a Manu por WhatsApp y reservá tu número.'
        : 'Escribile a Manu por WhatsApp y reservá tus dos números.';

    final uri = Uri.parse(
      'https://wa.me/$kWhatsAppNumber?text=${Uri.encodeComponent(_message(quantity))}',
    );

    return PremiumCard(
      accentColor: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.op(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.op(0.4),
                  ),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Oxanium',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Oxanium',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(context, uri),
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
              label: Text(
                isOne ? 'Escribir a Manu — 1 número' : 'Escribir a Manu — 2 números',
                style: const TextStyle(
                  fontFamily: 'Oxanium',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
