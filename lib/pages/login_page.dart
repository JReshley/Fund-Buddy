import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/dashboard.dart';
import 'package:fund_buddy/pages/widgets/log_sign_header.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import 'profile_page.dart';
import 'signup_page.dart';
import '../supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fund_buddy/pages/widgets/reset_password_page.dart';

class LoginPage extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  const LoginPage({
    super.key,
    required this.themeController,
    this.onThemeChanged,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isRememberMe = false;
  bool _isPasswordVisible = false;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _secureStorage = FlutterSecureStorage(); // For storing pass

  Future<void> _loginWithGoogle() async {
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
        _showError("Google login failed.");
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
      final username = email.split('@')[0]; // optional username from email

      // Insert user into Supabase 'user' table if doesn't exist
      final existingUser = await SupabaseConfig.client
          .from('user')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        try {
          await SupabaseConfig.client.from('user').insert({
            'id': user.id,
            'email': email,
            'firstName': firstName,
            'lastName': lastName,
            'fullName': fullName,
            'username': username,
            'profileImageUrl': googleUser.photoUrl,
          });

          // Verify the insert was successful by fetching the user
          await SupabaseConfig.client
              .from('user')
              .select('id')
              .eq('id', user.id)
              .single(); // This will throw if user doesn't exist

          print("User successfully created/verified in database");
        } catch (insertError) {
          _showError("Failed to create user profile: $insertError");
          return;
        }
      }

      // Navigate to Dashboard only after confirming user data exists
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } catch (e) {
      _showError("Google login error: $e");
    }
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showError("Please enter both username/email and password");
      return;
    }

    // for remember me button
    final prefs = await SharedPreferences.getInstance();
    if (isRememberMe) {
      await prefs.setString('identifier', identifier);
      await prefs.setBool('rememberMe', true);
      await _secureStorage.write(key: 'password', value: password);
    } else {
      await prefs.remove('identifier');
      await prefs.setBool('rememberMe', false);
      await _secureStorage.delete(key: 'password');
    }
    // end

    setState(() {
      // Optional: add a loading state here if needed
    });

    try {
      String emailToUse = identifier;

      // If input is a username (no '@'), resolve to email
      if (!identifier.contains('@')) {
        final profileRes = await SupabaseConfig.client
            .from('user')
            .select('email')
            .eq('username', identifier)
            .maybeSingle();

        final emailToUse1 =
            profileRes !=
                null //debug
            ? profileRes['email']
            : identifier;

        if (profileRes != null && profileRes['email'] != null) {
          emailToUse = profileRes['email'] as String;
        } else {
          _showError("Invalid username or password");
          return; // Stop login attempt if username not found
        }
      }

      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );

      if (res.user == null) {
        _showError("Invalid username/email or password");
        return;
      }

      // Navigate to Dashboard on successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } catch (e) {
      // Preserve your exception error handling
      _showError("Login failed. Please check your username and password.");
    } finally {
      setState(() {
        // Optional: reset loading state if added
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFD32F2F),
      ),
    );
  }

  //Dark Mode
  ThemeController get themeController => widget.themeController;

  // For remember me function
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIdentifier = prefs.getString('identifier');
      final remember = prefs.getBool('rememberMe') ?? false;

      if (remember && savedIdentifier != null) {
        final savedPassword = await _secureStorage.read(key: 'password');

        setState(() {
          _identifierController.text = savedIdentifier;
          _passwordController.text = savedPassword ?? '';
          isRememberMe = true;
        });
      }
    } catch (e) {
      print("Error loading saved credentials: $e");
    }
  }

  // end

  // Reset Password
  Future<void> _resetPassword() async {
    final email = _identifierController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError("Please enter a valid email to reset your password.");
      return;
    }

    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        email,
        redirectTo: "fundbuddy://reset-password",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset link sent to your email."),
          ),
        );
      }
    } catch (e) {
      _showError("Error sending reset link: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: widget.themeController.backgroundColor,
        width: double.infinity,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 35, vertical: 100),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                LogSignHeader(themeController: themeController),
                SizedBox(height: 30),
                // TEXT FIELDS START -----------------------------------------------------------------------------------------------------------------
                Row(
                  children: [
                    Text(
                      'Email/Username',
                      style: TextStyle(
                        fontFamily: "SpaceGrotesk",
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.transparent,
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: TextStyle(
                      color: widget.themeController.logtextColor,
                    ),
                    controller: _identifierController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person,
                        color: widget.themeController.loghintColor,
                      ),
                      hintText: 'Enter email/username here',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: widget.themeController.loghintColor,
                        fontStyle: FontStyle.italic,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: MediaQuery.of(context).size.width * 0.02,
                      ),

                      // Normal (unfocused) border
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                      ),

                      // Focused border (when user taps the field)
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF64B5F6),
                          width: 2.0,
                        ),
                      ),

                      filled: true,
                      fillColor: widget.themeController.logboxColor,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Password',
                      style: TextStyle(
                        fontFamily: "SpaceGrotesk",
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.transparent,
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(
                      color: widget.themeController.logtextColor,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock,
                        color: widget.themeController.loghintColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: widget.themeController.loghintColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      hintText: 'Enter password here',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: widget.themeController.loghintColor,
                        fontStyle: FontStyle.italic,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: MediaQuery.of(context).size.width * 0.02,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF64B5F6),
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor: widget.themeController.logboxColor,
                    ),
                  ),
                ),
                // TEXT FIELDS END -----------------------------------------------------------------------------------------------------------------
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isRememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              isRememberMe = value ?? false;
                            });
                          },
                          visualDensity: VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ), // removes extra space
                          materialTapTargetSize: MaterialTapTargetSize
                              .shrinkWrap, // shrinks default padding
                          activeColor: const Color(
                            0xFF64B5F6,
                          ), // color when checked
                          checkColor: Colors.white, // checkmark color
                          side: const BorderSide(
                            // border when unchecked
                            color: Color(0xFF4F4F4F),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            // rounded checkbox
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Remember Me",
                          style: TextStyle(
                            fontFamily: "SpaceGrotesk",
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: widget.themeController.loginColor,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _resetPassword,
                      child: Text(
                        'Forgot Password?',
                        style: const TextStyle(
                          fontFamily: "SpaceGrotesk",
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64B5F6),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shadowColor: Colors.black.withOpacity(1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.transparent),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      "Log in",
                      style: TextStyle(
                        fontFamily: "SpaceGrotesk",
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontFamily: "SpaceGrotesk",
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.loginColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        print("Sign up clicked");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SignupPage(themeController: themeController),
                          ),
                        );
                      },
                      child: Text(
                        'Sign up',
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
                SizedBox(height: 10),
                Divider(color: widget.themeController.navColor),
                SizedBox(height: 10),
                Text(
                  "or continue with",
                  style: TextStyle(
                    fontFamily: "SpaceGrotesk",
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.themeController.loginColor,
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _loginWithGoogle,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.themeController.logboxColor,
                          border: Border.all(
                            color: Colors.transparent,
                            width: 2,
                          ),
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
          ],
        ),
      ),
    );
  }
}
