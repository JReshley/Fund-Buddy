import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';

class LogSignHeader extends StatelessWidget {
  final ThemeController themeController;
  const LogSignHeader({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/Logo.png', width: 60),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 7),
                Text(
                  'FUND',
                  style: TextStyle(
                    fontFamily: "SpaceGrotesk",
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F4F4F),
                    height: 0.7,
                  ),
                ),
                Text(
                  'BUDDY',
                  style: TextStyle(
                    fontFamily: "SpaceGrotesk",
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64B5F6),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 50),

        // Welcome Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ',
              style: TextStyle(
                fontFamily: "SpaceGrotesk",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeController.loginColor,
              ),
            ),
            Text(
              'Fu',
              style: TextStyle(
                fontFamily: "SpaceGrotesk",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F4F4F),
              ),
            ),
            Text(
              'Bu',
              style: TextStyle(
                fontFamily: "SpaceGrotesk",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64B5F6),
              ),
            ),
            Text(
              ',',
              style: TextStyle(
                fontFamily: "SpaceGrotesk",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeController.loginColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),
        Text(
          'Where transparency meets efficiency',
          style: TextStyle(
            fontFamily: "SpaceGrotesk",
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: themeController.loginColor,
          ),
        ),
      ],
    );
  }
}
