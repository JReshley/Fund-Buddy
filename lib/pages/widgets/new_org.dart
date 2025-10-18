import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import '../../supabase_config.dart';

class NewOrg extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  const NewOrg({super.key, required this.themeController, this.onThemeChanged});

  @override
  State<NewOrg> createState() => _NewOrgState();
}

class _NewOrgState extends State<NewOrg> {
  //Controllers
  final TextEditingController orgnameController = TextEditingController();
  final TextEditingController orgabbreController = TextEditingController();
  final TextEditingController orgdescController = TextEditingController();
  
  bool isOrgNameFieldEnabled = true;
  bool isAbbreviationFieldEnabled = false;
  bool isDescriptionFieldEnabled = false;
  String? firstAdminName;

  static const double inputFontSize = 14;
  @override
  void initState() {
    super.initState();
    widget.themeController.loadTheme().then((_) {
      setState(() {}); // rebuild to apply saved theme
    });
  }

  @override
  void dispose() {
    orgnameController.dispose();
    orgabbreController.dispose();
    orgdescController.dispose();
    super.dispose();
  }

  Future<void> _checkOrgNameExists() async {
    final orgNameInput = orgnameController.text.trim();
    
    if (orgNameInput.isEmpty) {
      setState(() {
        isAbbreviationFieldEnabled = false;
        isDescriptionFieldEnabled = false;
        firstAdminName = null;
      });
      return;
    }

    // Check if organization name already exists (case-insensitive)
    try {
      final response = await SupabaseConfig.client
          .from('organization')
          .select('orgID, orgName')
          .ilike('orgName', orgNameInput);

      if (response.isNotEmpty) {
        // Organization exists, fetch the first admin
        final orgID = response[0]['orgID'];
        final adminResponse = await SupabaseConfig.client
            .from('user')
            .select('firstName, lastName')
            .eq('orgID', orgID)
            .eq('userAccess', 'Admin')
            .limit(1)
            .maybeSingle();

        String adminName = 'the admin';
        if (adminResponse != null) {
          adminName = '${adminResponse['firstName'] ?? ''} ${adminResponse['lastName'] ?? ''}'.trim();
          if (adminName.isEmpty) adminName = 'the admin';
        }

        setState(() {
          firstAdminName = adminName;
          isAbbreviationFieldEnabled = false;
          isDescriptionFieldEnabled = false;
        });

        // Show warning dialog
        if (mounted) {
          await showDialog(
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
                        'Organization Already Exists',
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
                  'An organization with this name already exists. Please contact this organization\'s admin, $adminName, or enter a different organization name.',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: widget.themeController.logtextColor,
                    fontSize: 14,
                  ),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Organization name is unique, enable other fields
        setState(() {
          isAbbreviationFieldEnabled = true;
          isDescriptionFieldEnabled = true;
          firstAdminName = null;
        });
      }
    } catch (e) {
      print('Error checking organization name: $e');
    }
  }

  Future<void> _saveOrganization() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final orgName = orgnameController.text.trim();
    final orgAbbreviation = orgabbreController.text.trim();
    final orgDescription = orgdescController.text.trim();

    // Validate required fields
    List<String> missingFields = [];
    if (orgName.isEmpty) missingFields.add('Organization Full Name');
    if (orgAbbreviation.isEmpty) missingFields.add('Organization Abbreviation');
    if (orgDescription.isEmpty) missingFields.add('Description');

    if (missingFields.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: widget.themeController.boxColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFF64B5F6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Missing required fields',
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
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please fill out the following before saving:',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        color: widget.themeController.logtextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: missingFields.map((f) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: widget.themeController.loginColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    color: widget.themeController.logtextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    // Check one more time if organization name exists
    try {
      final existingOrg = await SupabaseConfig.client
          .from('organization')
          .select('orgID')
          .ilike('orgName', orgName);

      if (existingOrg.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Organization name already exists'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create new organization
      final newOrgResponse = await SupabaseConfig.client
          .from('organization')
          .insert({
            'orgName': orgName,
            'abbreviation': orgAbbreviation,
            'description': orgDescription,
            'logoUrl': '', // Empty for now
          })
          .select('orgID')
          .single();

      final newOrgID = newOrgResponse['orgID'];

      // Update user with new orgID and set as Admin
      await SupabaseConfig.client
          .from('user')
          .update({
            'orgID': newOrgID,
            'userAccess': 'Admin',
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(); // Go back to profile page
      }
    } catch (e) {
      print('Error creating organization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create organization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeController.appColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.themeController.header2Color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            SizedBox(width: 15),
            Text(
              "Create New Organization",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.themeController.header2Color,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page description
            Text(
              "Enter the details for your new organization.",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: widget.themeController.loginColor,
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OrgHeaderText(text: "Organization Profile", color: widget.themeController.loginColor),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: widget.themeController.boxColor,
                    shape: BoxShape.circle, // ✅ make it a circle
                    border: Border.all(
                      color: const Color(0xFFBDBDBD),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 40,
                        color: widget.themeController.hintColor,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Upload Org Profile",
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                            color: widget.themeController.hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 15),
            OrgHeaderText(text: "Organization Full Name", color: widget.themeController.loginColor),
            SizedBox(height: 8),

            OrgTextFieldWithCheck(
              controller: orgnameController,
              hintText: "Enter organization name here",
              boxColor: widget.themeController.boxColor,
              hintColor: widget.themeController.hintColor,
              textColor: widget.themeController.logtextColor,
              fontSize: inputFontSize,
              onSubmitted: (value) => _checkOrgNameExists(),
            ),

            SizedBox(height: 8),
            OrgHeaderText(text: "Organization Abbreviation", color: widget.themeController.loginColor),
            SizedBox(height: 8),

            OrgTextField(
              controller: orgabbreController,
              hintText: "Enter organization abbreviation here",
              boxColor: widget.themeController.boxColor,
              hintColor: widget.themeController.hintColor,
              textColor: widget.themeController.logtextColor,
              fontSize: inputFontSize,
              enabled: isAbbreviationFieldEnabled,
            ),

            SizedBox(height: 8),
            OrgHeaderText(text: "Description", color: widget.themeController.loginColor),
            SizedBox(height: 8),

            OrgTextField(
              controller: orgdescController,
              hintText: "e.g., Materials for booth design",
              boxColor: widget.themeController.boxColor,
              hintColor: widget.themeController.hintColor,
              textColor: widget.themeController.logtextColor,
              fontSize: inputFontSize,
              enabled: isDescriptionFieldEnabled,
            ),
            SizedBox(height: 15),
            // Row(
            //   children: [
            //     // Cancel button
            //     Expanded(
            //       child: TextButton(
            //         onPressed: () {
            //           Navigator.of(context).pop();
            //         },
            //         style: TextButton.styleFrom(
            //           padding: const EdgeInsets.symmetric(vertical: 16),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(8),
            //             side: const BorderSide(color: Color(0xFF64B5F6)),
            //           ),
            //         ),
            //         child: const Text(
            //           "Cancel",
            //           style: TextStyle(
            //             fontFamily: 'Space Grotesk',
            //             color: Color(0xFF64B5F6),
            //             fontWeight: FontWeight.w600,
            //           ),
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     // Save button
            //     Expanded(
            //       child: TextButton(
            //         onPressed: () {
            //           Navigator.of(context).pop();
            //         },
            //         style: TextButton.styleFrom(
            //           backgroundColor: Color(0xFF64B5F6),
            //           padding: const EdgeInsets.symmetric(vertical: 16),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //         ),
            //         child: const Text(
            //           "Save",
            //           style: TextStyle(
            //             fontFamily: 'Space Grotesk',
            //             color: Colors.white,
            //             fontWeight: FontWeight.w600,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF64B5F6)),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: Color(0xFF64B5F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton(
                onPressed: _saveOrganization,
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFF64B5F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Save",
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
      ),
    );
  }
}

class OrgHeaderText extends StatelessWidget {
  final String text;
  final Color color; 

  const OrgHeaderText({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color, 
      ),
    );
  }
}

class OrgTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color boxColor;
  final Color hintColor;
  final Color textColor;
  final double fontSize;
  final bool enabled;

  const OrgTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.boxColor,
    required this.hintColor,
    required this.textColor,
    this.fontSize = 14.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: enabled ? boxColor : boxColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: enabled ? textColor : textColor.withOpacity(0.5),
          fontWeight: FontWeight.normal,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class OrgTextFieldWithCheck extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color boxColor;
  final Color hintColor;
  final Color textColor;
  final double fontSize;
  final Function(String)? onSubmitted;

  const OrgTextFieldWithCheck({
    super.key,
    required this.controller,
    required this.hintText,
    required this.boxColor,
    required this.hintColor,
    required this.textColor,
    this.fontSize = 14.0,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.normal,
          fontSize: fontSize,
        ),
      ),
    );
  }
}