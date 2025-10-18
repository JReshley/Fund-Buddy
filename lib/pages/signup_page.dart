import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/log_sign_header.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import 'login_page.dart';
import '../supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fund_buddy/pages/dashboard.dart';

class SignupPage extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  const SignupPage({
    super.key,
    required this.themeController,
    this.onThemeChanged,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool isRememberMe = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

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
    _passwordController.addListener(_validatePassword);
    _passwordFocusNode.addListener(() {
      setState(() {
        showChecklist = _passwordFocusNode.hasFocus;
      });
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasLowercase = password.contains(RegExp(r'[a-z]'));
      hasNumber = password.contains(RegExp(r'\d'));
      hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      hasMinLength = password.length >= 8;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        _showError("Google sign-in failed: missing tokens");
        return;
      }

      // Authenticate with Supabase
      final response = await SupabaseConfig.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        _showError("Google sign-up failed.");
        return;
      }

      // Extract names from Google profile
      final displayName = googleUser.displayName ?? '';
      final email = googleUser.email;
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final fullName = '$firstName $lastName';
      final username = email.split('@')[0];

      // Insert into 'user' table if doesn't exist
      final existingUser = await SupabaseConfig.client
          .from('user')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        await SupabaseConfig.client.from('user').insert({
          'id': user.id,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'username': username,
          'email': email,
          'profileImageUrl': googleUser.photoUrl,
        });
      }

      await Future.delayed(const Duration(milliseconds: 700));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } catch (e) {
      _showError("Google sign-up error: $e");
    }
  }

  Future<void> _signUp() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$',
    );

    if (!passwordRegex.hasMatch(password)) {
      _showError(
        "Password must be at least 8 characters long and include:\n"
        "- One uppercase letter\n"
        "- One lowercase letter\n"
        "- One digit\n"
        "- One special character",
      );
      return;
    }

    String capitalize(String name) {
      if (name.isEmpty) return name;
      return name
          .split(' ') // split into words
          .map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
    }

    firstName = capitalize(firstName);
    lastName = capitalize(lastName);
    final fullName = "$firstName $lastName";

    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await SupabaseConfig.client.from('user').insert({
          'id': response.user!.id,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'username': username,
          'email': email,
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(
              themeController: themeController,
              onThemeChanged: () {
                setState(() {});
              },
            ),
          ),
        );
      }
    } on AuthApiException catch (e) {
      if (e.code == 'user_already_exists') {
        _showError("This email is already registered. Please log in.");
      } else {
        _showError(e.message);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505' && e.message.contains('user_username_key')) {
        _showError(
          "This username is already taken. Please choose another one.",
        );
      } else {
        _showError("Database error: ${e.message}");
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFD32F2F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: widget.themeController.backgroundColor,
        width: double.infinity,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 100),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                LogSignHeader(themeController: themeController),
                const SizedBox(height: 30),

                // --- TEXT FIELDS START ---
                LabeledTextField(
                  label: "First Name",
                  hintText: "Enter your first name here",
                  prefixIcon: Icons.person,
                  controller: _firstNameController,
                  themeController: themeController,
                ),
                const SizedBox(height: 10),
                LabeledTextField(
                  label: "Last Name",
                  hintText: "Enter your last name here",
                  prefixIcon: Icons.person_outline,
                  controller: _lastNameController,
                  themeController: themeController,
                ),
                const SizedBox(height: 10),
                LabeledTextField(
                  label: "Username",
                  hintText: "Enter username here",
                  prefixIcon: Icons.account_circle,
                  controller: _usernameController,
                  themeController: themeController,
                ),
                const SizedBox(height: 10),
                LabeledTextField(
                  label: "Email",
                  hintText: "Enter email here",
                  prefixIcon: Icons.email,
                  controller: _emailController,
                  themeController: themeController,
                ),
                const SizedBox(height: 10),

                // --- PASSWORD FIELD + COLLAPSIBLE CHECKLIST ---
                LabeledTextField(
                  label: "Password",
                  hintText: "Enter password here",
                  prefixIcon: Icons.lock,
                  controller: _passwordController,
                  obscureText: true,
                  focusNode: _passwordFocusNode,
                  themeController: themeController,
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
                const SizedBox(height: 10),

                LabeledTextField(
                  label: "Confirm Password",
                  hintText: "Re-enter password here",
                  prefixIcon: Icons.lock_outline,
                  controller: _confirmPasswordController,
                  obscureText: true,
                  themeController: themeController,
                ),

                // --- TEXT FIELDS END ---
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                        fontFamily: "SpaceGrotesk",
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.themeController.loghintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontFamily: "SpaceGrotesk",
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LoginPage(themeController: themeController),
                          ),
                        );
                      },
                      child: const Text(
                        'Login here!',
                        style: TextStyle(
                          fontFamily: "SpaceGrotesk",
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64B5F6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: widget.themeController.navColor),
                const SizedBox(height: 10),
                Text(
                  "or continue with",
                  style: TextStyle(
                    fontFamily: "SpaceGrotesk",
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.themeController.loginColor,
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: _signUpWithGoogle,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.themeController.logboxColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        'lib/assets/google.png',
                        fit: BoxFit.contain,
                      ),
                    ),
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

// ---------------------- REUSABLE TEXT FIELD ----------------------
class LabeledTextField extends StatefulWidget {
  final ThemeController themeController;
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final TextEditingController controller;
  final bool obscureText;
  final FocusNode? focusNode;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.obscureText = false,
    required this.themeController,
    this.focusNode,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: "SpaceGrotesk",
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.themeController.loginColor,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          style: TextStyle(color: widget.themeController.logtextColor),
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText && !_isPasswordVisible,
          decoration: InputDecoration(
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: widget.themeController.loghintColor,
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: widget.themeController.loghintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 12,
              color: widget.themeController.loghintColor,
              fontStyle: FontStyle.italic,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF64B5F6),
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: widget.themeController.logboxColor,
          ),
        ),
      ],
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
