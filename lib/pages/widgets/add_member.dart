import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import '../../supabase_config.dart';

class AddMember extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  final String orgID;
  final String orgAbbreviation;
  final String userAccess;

  const AddMember({
    super.key,
    required this.themeController,
    required this.orgID,
    required this.orgAbbreviation,
    required this.userAccess,
    this.onThemeChanged,
  });

  @override
  State<AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {
  String? selectedAccess;
  bool isCheckingEmail = false;
  bool emailExists = false;
  String? userIdFromEmail;

  final TextEditingController memberemailController = TextEditingController();
  final TextEditingController memberroleController = TextEditingController();
  static const double inputFontSize = 14;

  @override
  void initState() {
    super.initState();
    widget.themeController.loadTheme().then((_) {
      setState(() {}); // rebuild to apply saved theme
    });
  }

  // Check if email exists in user table
  Future<void> _checkEmailExists() async {
    final email = memberemailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      isCheckingEmail = true;
      emailExists = false;
      userIdFromEmail = null;
    });

    try {
      final response = await SupabaseConfig.client
          .from('user')
          .select('id, orgID')
          .eq('email', email)
          .maybeSingle();

      setState(() {
        if (response != null) {
          emailExists = true;
          userIdFromEmail = response['id'];
          
          // Check if user already belongs to an organization
          if (response['orgID'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This user already belongs to an organization'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          emailExists = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email address does not belong to any user'),
              backgroundColor: Colors.red,
            ),
          );
        }
        isCheckingEmail = false;
      });
    } catch (e) {
      setState(() {
        isCheckingEmail = false;
      });
      print('Error checking email: $e');
    }
  }

  // Helper function to capitalize first letter of each word
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Add member to organization
  Future<void> _addMemberToOrganization() async {
    // Validate all fields
    final email = memberemailController.text.trim();
    final role = _capitalizeWords(memberroleController.text.trim());

    if (email.isEmpty || role.isEmpty || selectedAccess == null || selectedAccess == 'Select Access') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All input fields must be filled out'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if email exists
    if (!emailExists || userIdFromEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify the email address first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update user's orgID, role, and userAccess
      await SupabaseConfig.client.from('user').update({
        'orgID': int.parse(widget.orgID),
        'role': role,
        'userAccess': selectedAccess,
      }).eq('id', userIdFromEmail!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous page with success
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error adding member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    memberemailController.dispose();
    memberroleController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // Check if user is admin
    if (widget.userAccess != 'Admin') {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: widget.themeController.appColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: widget.themeController.header2Color),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Add New Member",
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.themeController.header2Color,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: widget.themeController.loginColor.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  "Access Denied",
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.themeController.loginColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Only administrators can add members to the organization.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 16,
                    color: widget.themeController.loginColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Admin view - show the add member form
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeController.appColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.themeController.header2Color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Add New Member",
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.themeController.header2Color,
              ),
            ),
            SizedBox(width: 25),
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
            SizedBox(height: 20),

            // Organization notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF64B5F6).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF64B5F6),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You are adding a member for ${widget.orgAbbreviation}",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            AddHeaderText(text: "Email Address", color: widget.themeController.loginColor),
            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: AddTextField(
                    controller: memberemailController,
                    hintText: "Enter new member's email",
                    boxColor: widget.themeController.boxColor,
                    hintColor: widget.themeController.hintColor,
                    textColor: widget.themeController.logtextColor,
                    fontSize: inputFontSize,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isCheckingEmail ? null : _checkEmailExists,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isCheckingEmail
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Verify",
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),

            // Email verification status
            if (emailExists)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Email verified",
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 15),
            AddHeaderText(text: "Member Role", color: widget.themeController.loginColor),
            SizedBox(height: 8),

            AddTextField(
              controller: memberroleController,
              hintText: "Enter new member's role",
              boxColor: widget.themeController.boxColor,
              hintColor: widget.themeController.hintColor,
              textColor: widget.themeController.logtextColor,
              fontSize: inputFontSize,
            ),

            SizedBox(height: 15),
            AddHeaderText(text: "Member Access", color: widget.themeController.loginColor),
            SizedBox(height: 8),

            // Member Access Dropdown
            LayoutBuilder(
              builder: (context, constraints) {
                final double fieldWidth = constraints.maxWidth;

                return Center(
                  child: Container(
                    width: fieldWidth,
                     decoration: BoxDecoration(
                      color: widget.themeController.boxColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: DropdownMenu<String>(
                      width: fieldWidth,
                      menuStyle: MenuStyle(
                        backgroundColor: MaterialStatePropertyAll(widget.themeController.boxColor),
                        elevation: const MaterialStatePropertyAll(4),
                        fixedSize: MaterialStatePropertyAll(
                          Size(fieldWidth, double.infinity),
                        ),
                      ),
                      trailingIcon: Icon(
                        Icons.arrow_drop_down,
                        color: widget.themeController.logtextColor, 
                        size: 24,                    
                      ),
                      selectedTrailingIcon: Icon(
                        Icons.arrow_drop_up,
                        color: widget.themeController.logtextColor, 
                        size: 24,                    
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: selectedAccess == null || selectedAccess == 'Select Access'
                            ? widget.themeController.hintColor
                            : widget.themeController.logtextColor,
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: widget.themeController.boxColor,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      initialSelection: 'Select Access',
                      onSelected: (value) {
                        setState(() {
                          selectedAccess = value;
                        });
                      },
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: 'Select Access', 
                          label: 'Select Access',
                          style: ButtonStyle(
                            foregroundColor: MaterialStatePropertyAll(widget.themeController.hintColor), 
                          ),
                        ),
                        DropdownMenuEntry(
                          value: 'Admin', 
                          label: 'Admin',
                          style: ButtonStyle(
                            foregroundColor: MaterialStatePropertyAll(widget.themeController.hintColor), 
                          ),
                        ),
                        DropdownMenuEntry(
                          value: 'Member', 
                          label: 'Member',
                          style: ButtonStyle(
                            foregroundColor: MaterialStatePropertyAll(widget.themeController.hintColor), 
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
                onPressed: _addMemberToOrganization,
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

class AddHeaderText extends StatelessWidget {
  final String text;
  final Color color; 

  const AddHeaderText({
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

class AddTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color boxColor;
  final Color hintColor;
  final Color textColor;
  final double fontSize;

  const AddTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.boxColor,
    required this.hintColor,
    required this.textColor,
    this.fontSize = 14.0,
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