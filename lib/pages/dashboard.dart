import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/home_page.dart';
import 'package:fund_buddy/pages/profile_page.dart';
import 'package:fund_buddy/pages/transactions_page.dart';
import 'widgets/theme_toggle.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int lightBlue = 0xFF64B5F6;
  int _selectedIndex = 0;

  final ThemeController themeController = ThemeController();
  late List<Widget> _pages;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await themeController.loadTheme();
    _pages = [
      HomePage(themeController: themeController),
      TransactionsPage(themeController: themeController),
      ProfilePage(
        themeController: themeController,
        onThemeChanged: () => setState(() {}),
      ),
    ];
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Space Grotesk',
        scaffoldBackgroundColor: themeController.backgroundColor,
        primaryColor: const Color(0xFF64B5F6),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF64B5F6),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: themeController.appColor,
          toolbarHeight: 7,
        ),
        body: _pages[_selectedIndex],
        
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                 color: themeController.boxshadow,
                blurRadius: 0.5,
                offset: Offset(-2, 0),
              )
            ]
          ),
          child: BottomNavigationBar(
          iconSize: 24,
          selectedFontSize: 14,
          selectedItemColor: const Color(0xFF64B5F6),
          unselectedItemColor: themeController.navColor,
          backgroundColor: themeController.appColor,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        )
      ),
    );
  }
}
