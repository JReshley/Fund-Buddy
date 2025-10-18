import 'package:flutter/material.dart';
import 'login_page.dart';
import 'widgets/theme_toggle.dart';

class OpeningPage extends StatefulWidget {

  final VoidCallback? onThemeChanged; 

  const OpeningPage({super.key, this.onThemeChanged});

  @override
  State<OpeningPage> createState() => _OpeningPageState();
}

class _OpeningPageState extends State<OpeningPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(themeController: themeController)),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeController.backgroundColor,
      body: Center(
        child: FadeTransition(
  opacity: _animation,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
    children: [
      Image.asset(
        'lib/assets/Logo.png',
        width: 120,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'FUND',
            style: TextStyle(
              fontFamily: "SpaceGrotesk",
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F4F4F),
              height: 1.0,
            ),
          ),
          Text(
            'BUDDY',
            style: TextStyle(
              fontFamily: "SpaceGrotesk",
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64B5F6),
              height: 1.0,
            ),
          ),
        ],
      ),
    ],
  ),
),
      ),
    );
  }
}
