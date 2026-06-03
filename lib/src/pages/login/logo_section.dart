import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';

class LogoSection extends StatelessWidget {
  const LogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppPalette.primaryBlue, AppPalette.lightBlue],
            ),
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 46),
        ),
        const SizedBox(height: 18),
        const Text(
          'PAMSIMAS',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppPalette.primaryBlue,
          ),
        ),
      ],
    );
  }
}
