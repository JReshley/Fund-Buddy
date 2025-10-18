import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';

class AboutUsPage extends StatelessWidget {
  final ThemeController themeController;

  const AboutUsPage({Key? key, required this.themeController})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeController.boxColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeController.headerColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Us',
          style: TextStyle(
            color: themeController.header2Color,
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const SizedBox(height: 16),
          _buildHeading('Our Mission', themeController),
          _buildText(
            'FundBuddy aims to simplify financial management for organizations by providing a secure and user-friendly platform.',
            themeController,
          ),

          const SizedBox(height: 32),
          _buildHeading('Who We Are', themeController),
          _buildText(
            'We are a team of passionate developers committed to creating innovative solutions for organizational financial management.',
            themeController,
          ),

          const SizedBox(height: 32),
          _buildHeading('Core Features', themeController),
          _buildBulletPoints([
            'Intuitive fund management',
            'Secure organization system',
            'Real-time tracking',
            'Multi-user access',
            'Detailed reporting',
          ], themeController),

          const SizedBox(height: 32),
          _buildHeading('Development Team', themeController),
          _buildTeamMember(
            'John Reshley P. Gonzales',
            'Team Leader',
            themeController,
          ),
          _buildTeamMember(
            'Mark Harold T. Valderrama',
            'Backend Developer',
            themeController,
          ),
          _buildTeamMember(
            'Randel Angelo L. Yumul',
            'Frontend Developer',
            themeController,
          ),
          _buildTeamMember(
            'Keith Ryan N.Almanzor',
            'UI/UX Designer',
            themeController,
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(String text, ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF64B5F6),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Space Grotesk',
        ),
      ),
    );
  }

  Widget _buildText(String text, ThemeController themeController) {
    return Text(
      text,
      style: TextStyle(
        color: themeController.logtextColor,
        fontSize: 16,
        height: 1.5,
        fontFamily: 'Space Grotesk',
      ),
    );
  }

  Widget _buildBulletPoints(
    List<String> points,
    ThemeController themeController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64B5F6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: themeController.logtextColor,
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTeamMember(
    String name,
    String role,
    ThemeController themeController,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person_outline, color: const Color(0xFF64B5F6)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: themeController.headerColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Space Grotesk',
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  color: themeController.logtextColor,
                  fontSize: 14,
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
