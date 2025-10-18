import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/new_org.dart';
import '../../supabase_config.dart';
import 'theme_toggle.dart';

class CreateOrg extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  final String? orgID;
  final String? orgName;

  const CreateOrg({
    super.key,
    required this.themeController,
    this.onThemeChanged,
    this.orgID,
    this.orgName,
  });

  @override
  State<CreateOrg> createState() => _OrgBox();
}

class _OrgBox extends State<CreateOrg> {
  @override
  void initState() {
    super.initState();
    widget.themeController.loadTheme().then((_) {
      setState(() {});// rebuild to apply saved theme
    });
  }

  Future<void> _leaveOrganization() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.themeController.boxColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Leave Organization',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    color: widget.themeController.header2Color,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to leave ${widget.orgName ?? "this organization"}? This decision cannot be undone.',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              color: widget.themeController.logtextColor,
              fontSize: 14,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF64B5F6)),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: Color(0xFF64B5F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Yes, Leave',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Update user table to remove orgID and userAccess
      await SupabaseConfig.client
          .from('user')
          .update({
            'orgID': null,
            'userAccess': null,
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the organization successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Trigger parent widget to reload
        if (widget.onThemeChanged != null) {
          widget.onThemeChanged!();
        }
      }
    } catch (e) {
      print('Error leaving organization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave organization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final themeController = widget.themeController;
    
    // If user has an organization, show Leave Organization button
    if (widget.orgID != null) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _leaveOrganization,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeController.boxColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide( 
                    color: Color(0xFF64B5F6),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Leave Organization',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64B5F6),
                  letterSpacing: 0.25,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // If user has no organization, show Create Organization button with reminder
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => NewOrg(
                    themeController: widget.themeController,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              ).then((_) {
                // Reload parent widget when returning from NewOrg
                if (widget.onThemeChanged != null) {
                  widget.onThemeChanged!();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF64B5F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Create Organization',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w500,
                color: themeController.boxColor,
                letterSpacing: 0.25,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeController.boxColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF64B5F6).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF64B5F6),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Reminder',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.w700,
                          color: themeController.loginColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'If you haven\'t joined an organization, you may either contact the admin to add you as a member or create a new organization. You can only be part of one organization at a time.',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.normal,
                          color: themeController.loginColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}