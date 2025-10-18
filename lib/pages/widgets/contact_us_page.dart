import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  final ThemeController themeController;

  const ContactUsPage({Key? key, required this.themeController})
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
          'Contact Us',
          style: TextStyle(
            color: themeController.header2Color,
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildContactCard(
              icon: Icons.email,
              title: 'Email Us',
              subtitle: 'reshleygonzales11@gmail.com',
              onTap: () => _launchEmail(),
              themeController: themeController,
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '09123456789',
              onTap: () => _launchPhone(),
              themeController: themeController,
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.location_on,
              title: 'Visit Us',
              subtitle: '[Bundok]',
              onTap: () => _launchMaps(),
              themeController: themeController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeController themeController,
  }) {
    return Card(
      color: themeController.boxColor,
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF64B5F6), size: 30),
        title: Text(
          title,
          style: TextStyle(
            color: themeController.header2Color,
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: themeController.logtextColor,
            fontFamily: 'Space Grotesk',
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'reshleygonzales11@gmail.com',
      queryParameters: {'subject': 'Contact FundBuddy Support'},
    );
    await launchUrl(emailLaunchUri);
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '09123456789');
    await launchUrl(phoneUri);
  }

  void _launchMaps() async {
    // Replace with your actual coordinates
    const String query = '[Bundok]';
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }
}
