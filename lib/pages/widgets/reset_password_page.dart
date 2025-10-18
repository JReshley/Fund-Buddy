import 'package:flutter/material.dart';
import '../../supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fund_buddy/pages/login_page.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';

class ResetPasswordPage extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  const ResetPasswordPage({
    super.key,
    required this.themeController,
    this.onThemeChanged,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _newPasswordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Password validation flags
  bool showChecklist = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;

  //Dark Mode
  ThemeController get themeController => widget.themeController;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePassword);
    _newPasswordFocusNode.addListener(() {
      setState(() {
        showChecklist = _newPasswordFocusNode.hasFocus;
      });
    });
  }

  void _validatePassword() {
    final newPassword = _newPasswordController.text;
    setState(() {
      hasUppercase = newPassword.contains(RegExp(r'[A-Z]'));
      hasLowercase = newPassword.contains(RegExp(r'[a-z]'));
      hasNumber = newPassword.contains(RegExp(r'\d'));
      hasSpecialChar = newPassword.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      hasMinLength = newPassword.length >= 8;
    });
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_validatePassword);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError("Please fill in both fields");
      return;
    }
    if (newPassword != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$',
    );

    if (!passwordRegex.hasMatch(newPassword)) {
      _showError(
        "Password must be at least 8 characters long and include:\n"
        "- One uppercase letter\n"
        "- One lowercase letter\n"
        "- One digit\n"
        "- One special character",
      );
      return;
    }

    try {
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        // ✅ Log out the current session
        await SupabaseConfig.client.auth.signOut();

        // ✅ Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );

        // ✅ Redirect to LoginPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(themeController: themeController),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      _showError("Failed to update password: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color blue = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeController.appColor,
        elevation: 0,
        title: Text(
          "Reset Password",
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.themeController.header2Color,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Password fields
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New Password",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeController.loginColor,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  style: TextStyle(color: widget.themeController.logtextColor),
                  controller: _newPasswordController,
                  obscureText: !_isPasswordVisible,
                  focusNode: _newPasswordFocusNode,
                  decoration: InputDecoration(
                    hintText: "Enter new password",
                    hintStyle: TextStyle(color: themeController.hintColor),
                    filled: true,
                    fillColor: themeController.boxColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: blue, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: themeController.hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: PasswordChecklist(
                    hasUppercase: hasUppercase,
                    hasLowercase: hasLowercase,
                    hasNumber: hasNumber,
                    hasSpecialChar: hasSpecialChar,
                    hasMinLength: hasMinLength,
                    themeController: themeController,
                  ),
                  crossFadeState: showChecklist
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
                const SizedBox(height: 20),
                Text(
                  "Confirm Password",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeController.loginColor,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  style: TextStyle(color: widget.themeController.logtextColor),
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "Re-enter new password",
                    hintStyle: TextStyle(color: themeController.hintColor),
                    filled: true,
                    fillColor: themeController.boxColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: blue, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: themeController.hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600, // semi-bold
                      ),
                    ),
                    onPressed: _updatePassword,
                    child: const Text("Reset Password"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- PASSWORD CHECKLIST ----------------------
class PasswordChecklist extends StatelessWidget {
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool hasMinLength;
  final ThemeController themeController;

  const PasswordChecklist({
    super.key,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.hasMinLength,
    required this.themeController,
  });

  Widget _buildCheckItem(String text, bool isChecked) {
    return Row(
      children: [
        Icon(
          isChecked ? Icons.check_circle : Icons.cancel,
          color: isChecked ? Colors.green : Colors.redAccent,
          size: 18,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: "SpaceGrotesk",
              fontSize: 12,
              color: isChecked ? Colors.green : themeController.loginColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: themeController.logboxColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF64B5F6).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckItem("At least 8 characters", hasMinLength),
          _buildCheckItem("One uppercase letter", hasUppercase),
          _buildCheckItem("One lowercase letter", hasLowercase),
          _buildCheckItem("One number", hasNumber),
          _buildCheckItem("One special character (!@#\$%^&*)", hasSpecialChar),
        ],
      ),
    );
  }
}
