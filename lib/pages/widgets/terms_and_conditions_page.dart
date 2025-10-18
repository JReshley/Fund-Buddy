import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';

class TermsAndConditionsPage extends StatelessWidget {
  final ThemeController themeController;

  const TermsAndConditionsPage({Key? key, required this.themeController})
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
          'Terms and Conditions',
          style: TextStyle(
            color: themeController.header2Color,
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF64B5F6).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last updated: October 12, 2025',
                  style: TextStyle(
                    color: themeController.logtextColor,
                    fontFamily: 'Space Grotesk',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 25),

                _buildTitle('Acceptance of Terms', themeController),
                const SizedBox(height: 10),
                _buildContent(
                  'By downloading, installing, or using FundBuddy, you automatically agree to these Terms and Conditions. If you disagree with any part of these terms, you must not use our application.',
                  themeController,
                ),
                const SizedBox(height: 25),

                _buildTitle('User Registration', themeController),
                const SizedBox(height: 10),
                _buildContent(
                  '• You must provide accurate and complete information when creating an account\n'
                  '• You are responsible for maintaining the security of your account credentials\n'
                  '• You must notify us immediately of any unauthorized access to your account',
                  themeController,
                ),
                const SizedBox(height: 25),

                _buildTitle('Organization Management', themeController),
                const SizedBox(height: 10),
                _buildContent(
                  '• Organizations must be legitimate and properly registered entities\n'
                  '• Organization administrators are responsible for managing member access\n'
                  '• All financial transactions must comply with local laws and regulations\n'
                  '• Organizations must maintain accurate and transparent financial records',
                  themeController,
                ),
                const SizedBox(height: 25),

                _buildTitle('Financial Services', themeController),
                const SizedBox(height: 10),
                _buildContent(
                  '• FundBuddy serves as a platform for financial management and does not provide financial advice\n'
                  '• Users are responsible for their own financial decisions\n'
                  '• All transactions are subject to verification and security checks\n'
                  '• We reserve the right to suspend services in case of suspicious activity',
                  themeController,
                ),
                const SizedBox(height: 25),

                _buildTitle('Privacy & Data Protection', themeController),
                const SizedBox(height: 10),
                _buildContent(
                  '• We collect and process data as outlined in our Privacy Policy\n'
                  '• User data is encrypted and stored securely\n'
                  '• We do not share personal information with third parties without consent\n'
                  '• Users have the right to request their data or its deletion',
                  themeController,
                ),
                const SizedBox(height: 25),

                _buildTitle('Contact Us', themeController),
                const SizedBox(height: 10),
                _buildContent(
                  'If you have any questions about these Terms and Conditions, please contact us:\n\n'
                  'Email: reshleygonzales11@gmail.com\n'
                  'Phone: 09123456789\n'
                  'Address: [Bundok]',
                  themeController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String title, ThemeController themeController) {
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFF64B5F6),
        fontFamily: 'Space Grotesk',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContent(String content, ThemeController themeController) {
    return Text(
      content,
      style: TextStyle(
        color: themeController.logtextColor,
        fontFamily: 'Space Grotesk',
        fontSize: 14,
      ),
    );
  }
}
