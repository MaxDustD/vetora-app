import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cabeçalho com o símbolo e o logotipo "VETORA", usado no Onboarding e na Home.
class VetoraHeader extends StatelessWidget {
  const VetoraHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/brand/logo.png', width: 28, height: 28),
        const SizedBox(width: 10),
        Text('VETORA', style: AppTextStyles.logotipo.copyWith(fontSize: 14)),
      ],
    );
  }
}
