import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/contact_us_page.dart';
import 'package:fund_buddy/pages/login_page.dart';
import 'package:fund_buddy/pages/widgets/about_us_page.dart';
import 'package:fund_buddy/pages/widgets/create_org.dart';
import 'package:fund_buddy/pages/widgets/edit_info.dart';
import 'package:fund_buddy/pages/widgets/org_box.dart';
import 'package:fund_buddy/pages/widgets/terms_and_conditions_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/theme_toggle.dart';
import '../supabase_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;

  const ProfilePage({
    super.key,
    required this.themeController,
    this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final double coverHeight = 220;
  final double profileHeight = 150;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  // Password validation flags
  bool showChecklist = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;

  String? fullName;
  String? email;
  String? _imageUrl; // for image
  String? orgID; // organization ID
  String? userAccess; // user access level (Admin, Member, etc.)
  String? orgName; // organization name

  bool isOn = false;
  String language = "English";
  bool _isLoading = true; // Loading state

  String? _originalFirstName;
  String? _originalLastName;
  String? _originalUsername;
  String? _originalEmail;

  final double profileboxgap = 15;

  @override
  void initState() {
    super.initState();

    // Load saved theme
    widget.themeController.loadTheme().then((_) {
      setState(() {}); // rebuild to apply saved theme
    });

    // Initialize profile-related flags
    _editprofile = true;
    _isPasswordEditable = false;
    _confirmpassword = false;
    showChecklist = false;

    // Load user data
    _loadUserData();

    // Add password listener for validation
    _passwordController.addListener(_validatePassword);

    // Show checklist when password field is focused
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
    _confirmpasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    print('_loadUserData() called');
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      print('No authenticated user found');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    print('User authenticated: ${user.id}');
    print('User email: ${user.email}');

    try {
      // Safely query user table
      print('Querying user table for id: ${user.id}');

      final response = await SupabaseConfig.client
          .from('user')
          .select(
            'firstName, lastName, username, email, profileImageUrl, role, userAccess, orgID',
          )
          .eq('id', user.id)
          .maybeSingle();

      print('Raw response: $response');
      print('Response type: ${response.runtimeType}');

      if (response == null) {
        print('No user data found for ${user.id}');
        print('This means the user record does not exist in the user table');
        print('Or RLS policies are blocking the query');
        return;
      }

      print('User data loaded successfully!');
      print('   - firstName: ${response['firstName']}');
      print('   - lastName: ${response['lastName']}');
      print('   - email: ${response['email']}');
      print('   - orgID: ${response['orgID']}');
      print('   - userAccess: ${response['userAccess']}');

      // Fetch organization name if orgID exists
      String? fetchedOrgName;
      if (response['orgID'] != null) {
        try {
          final orgResponse = await SupabaseConfig.client
              .from('organization')
              .select('orgName')
              .eq('orgID', response['orgID'])
              .maybeSingle();

          if (orgResponse != null) {
            fetchedOrgName = orgResponse['orgName'];
            print('   - orgName: $fetchedOrgName');
          }
        } catch (e) {
          print('Error fetching organization name: $e');
        }
      }

      setState(() {
        _firstNameController.text = response['firstName'] ?? '';
        _lastNameController.text = response['lastName'] ?? '';
        _usernameController.text = response['username'] ?? '';
        _emailController.text = response['email'] ?? '';
        _imageUrl = response['profileImageUrl'];
        orgID = response['orgID']?.toString();
        userAccess = response['userAccess'];
        orgName = fetchedOrgName;

        // For more secure edit profile
        _originalFirstName = response['firstName'];
        _originalLastName = response['lastName'];
        _originalUsername = response['username'];
        _originalEmail = response['email'];

        print(
          'State updated - orgID: $orgID, userAccess: $userAccess, orgName: $orgName',
        );

        // Update display variables
        fullName =
            "${response['firstName'] ?? ''} ${response['lastName'] ?? ''}"
                .trim();
        email = response['email'] ?? '';

        print('Full name set to: $fullName');

        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print("Error loading user data: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleProfileImageTap() async {
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      // Show dialog to choose between view or change
      final choice = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: widget.themeController.boxColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              'Profile Image',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w700,
                color: widget.themeController.header2Color,
                fontSize: 16,
              ),
            ),
            content: Text(
              'What would you like to do?',
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
                      onPressed: () => Navigator.of(context).pop('view'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF64B5F6)),
                        ),
                      ),
                      child: const Text(
                        'View',
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
                      onPressed: () => Navigator.of(context).pop('change'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Change',
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

      if (choice == 'view') {
        // Show full image in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.black54,
                            child: const Text(
                              'Error loading image',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else if (choice == 'change') {
        await _pickAndUploadImage();
      }
    } else {
      // No existing image, directly pick and upload
      await _pickAndUploadImage();
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileName = 'profile_${user.id}.jpg';

    try {
      // Store old image URL to delete later
      String? oldImageUrl = _imageUrl;

      // Upload to Supabase Storage
      await SupabaseConfig.client.storage
          .from('profile_images')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final publicUrl = SupabaseConfig.client.storage
          .from('profile_images')
          .getPublicUrl(fileName);

      // Update user table
      await SupabaseConfig.client
          .from('user')
          .update({'profileImageUrl': publicUrl})
          .eq('id', user.id);

      // Delete old image from storage if it exists and is different
      if (oldImageUrl != null &&
          oldImageUrl.isNotEmpty &&
          oldImageUrl != publicUrl) {
        try {
          // Extract filename from old URL
          final oldFileName = oldImageUrl.split('/').last.split('?').first;
          await SupabaseConfig.client.storage.from('profile_images').remove([
            oldFileName,
          ]);
        } catch (e) {
          print('Error deleting old image: $e');
          // Continue even if deletion fails
        }
      }

      setState(() {
        _imageUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Image upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfileChanges() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    String? firstName = _firstNameController.text.trim();
    String? lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final emailInput = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmpasswordController.text.trim();

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

    // Only check passwords if user is actually changing them
    if (password.isNotEmpty || confirmPassword.isNotEmpty) {
      if (password != confirmPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
        return;
      }
    }

    // Collect only changed fields
    final updates = <String, dynamic>{};

    // Compare against loaded state (not the same controllers)
    if (firstName.isNotEmpty && firstName != _originalFirstName) {
      updates['firstName'] = firstName;
    }
    if (lastName.isNotEmpty && lastName != _originalLastName) {
      updates['lastName'] = lastName;
    }
    if (username.isNotEmpty && username != _originalUsername) {
      updates['username'] = username;
    }
    if (emailInput.isNotEmpty && emailInput != _originalEmail) {
      updates['email'] = emailInput;
    }

    if (updates.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No changes detected.")));
      return;
    }

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$',
    );

    if (password.isNotEmpty && !passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 8 characters long and include:\n"
            "- One uppercase letter\n"
            "- One lowercase letter\n"
            "- One digit\n"
            "- One special character",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFD32F2F), // optional: red error color
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Update"),
        content: const Text("Do you want to save your profile changes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Update email/password in Supabase Auth only if provided
      if ((emailInput.isNotEmpty && emailInput != user.email) ||
          password.isNotEmpty) {
        await SupabaseConfig.client.auth.updateUser(
          UserAttributes(
            email: emailInput.isNotEmpty && emailInput != user.email
                ? emailInput
                : null,
            password: password.isNotEmpty ? password : null,
          ),
        );
      }

      // Add fullName only if first or last names updated
      if (updates.containsKey('firstName') || updates.containsKey('lastName')) {
        updates['fullName'] = "$firstName $lastName".trim();
      }

      // Update PostgreSQL user table if needed
      if (updates.isNotEmpty) {
        await SupabaseConfig.client
            .from('user')
            .update(updates)
            .eq('id', user.id);
      }

      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      setState(() {
        _editprofile = true;
        _confirmpassword = false;
        _isPasswordEditable = false;
      });
    } catch (e) {
      print("Profile update failed: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
    }
  }

  bool _editprofile = true;
  bool _isPasswordEditable = false;
  bool _confirmpassword = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF64B5F6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      color: widget.themeController.headerColor,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Blue cover (background)
                      Container(
                        height: coverHeight,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF64B5F6),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                      ),

                      // Profile + card moved down by half of blue cover
                      Padding(
                        padding: const EdgeInsets.only(top: 125),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // White card
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                              ),
                              child: Container(
                                // Outer container gives shadow
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.1,
                                      ), // Subtle shadow for depth
                                      blurRadius: 4,
                                      offset: Offset(
                                        2,
                                        2,
                                      ), // Shadow positioned below
                                    ),
                                  ],
                                ),
                                child: ClipPath(
                                  clipper: TopHoleClipper(65),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: widget.themeController.boxColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 60),
                                        ...[
                                          if (_editprofile) ...[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  fullName ?? "Name",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'SpaceGrotesk',
                                                    fontWeight: FontWeight.w700,
                                                    color: widget
                                                        .themeController
                                                        .headerColor,
                                                  ),
                                                ),
                                                if (userAccess == 'Admin') ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFF64B5F6,
                                                        ),
                                                        width: 1.5,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Admin',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontFamily:
                                                            'SpaceGrotesk',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF64B5F6,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              email ?? "Email",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'SpaceGrotesk',
                                                fontWeight: FontWeight.w500,
                                                color: widget
                                                    .themeController
                                                    .headerColor,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                          ]
                                          // EDIT PROFILE PART --------------------------------------------------
                                          else ...[
                                            EditProfileField(
                                              controller: _firstNameController,
                                              label: "Firstname",
                                              hinttext: "firstname",
                                              initialValue:
                                                  _firstNameController.text,
                                              icon: Icons.person,
                                              themeController:
                                                  widget.themeController,
                                            ),
                                            const SizedBox(height: 6),
                                            EditProfileField(
                                              controller: _lastNameController,
                                              label: "Lastname",
                                              hinttext: "lastname",
                                              initialValue:
                                                  _lastNameController.text,
                                              icon:
                                                  Icons.person_outline_outlined,
                                              themeController:
                                                  widget.themeController,
                                            ),
                                            const SizedBox(height: 6),
                                            EditProfileField(
                                              controller: _usernameController,
                                              label: "Username",
                                              hinttext: "username",
                                              initialValue:
                                                  _usernameController.text,
                                              icon: Icons.account_circle,
                                              themeController:
                                                  widget.themeController,
                                            ),
                                            const SizedBox(height: 6),
                                            EditProfileField(
                                              controller: _emailController,
                                              label: "Email",
                                              hinttext: "email",
                                              initialValue: email,
                                              icon: Icons.email,
                                              themeController:
                                                  widget.themeController,
                                            ),
                                            const SizedBox(height: 6),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      "Password",
                                                      style: TextStyle(
                                                        fontFamily:
                                                            "SpaceGrotesk",
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: widget
                                                            .themeController
                                                            .loginColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(
                                                              0.1,
                                                            ), // Subtle shadow for depth
                                                        blurRadius: 4,
                                                        offset: Offset(
                                                          2,
                                                          2,
                                                        ), // Shadow positioned below
                                                      ),
                                                    ],
                                                  ),
                                                  child: TextField(
                                                    controller:
                                                        _passwordController,
                                                    readOnly:
                                                        !_isPasswordEditable,
                                                    focusNode:
                                                        _passwordFocusNode,
                                                    obscureText:
                                                        !_showPassword, // hides text when false
                                                    style: TextStyle(
                                                      color: widget
                                                          .themeController
                                                          .logtextColor,
                                                      fontFamily:
                                                          "SpaceGrotesk",
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    decoration: InputDecoration(
                                                      prefixIcon: Icon(
                                                        Icons.lock,
                                                        color: widget
                                                            .themeController
                                                            .loghintColor,
                                                      ),
                                                      suffixIcon:
                                                          _isPasswordEditable
                                                          ? IconButton(
                                                              icon: Icon(
                                                                _showPassword
                                                                    ? Icons
                                                                          .visibility
                                                                    : Icons
                                                                          .visibility_off,
                                                                color: widget
                                                                    .themeController
                                                                    .logtextColor,
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _showPassword =
                                                                      !_showPassword;
                                                                });
                                                              },
                                                            ) // no icon when editable
                                                          : IconButton(
                                                              icon: Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                color: widget
                                                                    .themeController
                                                                    .logtextColor,
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _isPasswordEditable =
                                                                      !_isPasswordEditable;
                                                                  _confirmpassword =
                                                                      !_confirmpassword;
                                                                });
                                                              },
                                                            ),
                                                      hintText: "Password",
                                                      hintStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: widget
                                                            .themeController
                                                            .hintColor,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 5,
                                                            horizontal:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width *
                                                                0.02,
                                                          ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFF64B5F6,
                                                                  ),
                                                                  width: 2.0,
                                                                ),
                                                          ),
                                                      filled: true,
                                                      fillColor: widget
                                                          .themeController
                                                          .logboxColor,
                                                    ),
                                                  ),
                                                ),
                                                AnimatedCrossFade(
                                                  firstChild:
                                                      const SizedBox.shrink(),
                                                  secondChild:
                                                      PasswordChecklist(
                                                        hasUppercase:
                                                            hasUppercase,
                                                        hasLowercase:
                                                            hasLowercase,
                                                        hasNumber: hasNumber,
                                                        hasSpecialChar:
                                                            hasSpecialChar,
                                                        hasMinLength:
                                                            hasMinLength,
                                                        themeController: widget
                                                            .themeController,
                                                      ),
                                                  crossFadeState: showChecklist
                                                      ? CrossFadeState
                                                            .showSecond
                                                      : CrossFadeState
                                                            .showFirst,
                                                  duration: const Duration(
                                                    milliseconds: 250,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // Confirm Password
                                            if (_confirmpassword) ...[
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Confirm Password",
                                                        style: TextStyle(
                                                          fontFamily:
                                                              "SpaceGrotesk",
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: widget
                                                              .themeController
                                                              .loginColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.1,
                                                              ), // Subtle shadow for depth
                                                          blurRadius: 4,
                                                          offset: Offset(
                                                            2,
                                                            2,
                                                          ), // Shadow positioned below
                                                        ),
                                                      ],
                                                    ),
                                                    child: TextField(
                                                      controller:
                                                          _confirmpasswordController,
                                                      obscureText:
                                                          !_showConfirmPassword, // hides text when false
                                                      style: TextStyle(
                                                        color: widget
                                                            .themeController
                                                            .logtextColor,
                                                        fontFamily:
                                                            "SpaceGrotesk",
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      decoration: InputDecoration(
                                                        prefixIcon: Icon(
                                                          Icons.lock_outline,
                                                          color: widget
                                                              .themeController
                                                              .loghintColor,
                                                        ),
                                                        suffixIcon:
                                                            _isPasswordEditable
                                                            ? IconButton(
                                                                icon: Icon(
                                                                  _showConfirmPassword
                                                                      ? Icons
                                                                            .visibility
                                                                      : Icons
                                                                            .visibility_off,
                                                                  color: widget
                                                                      .themeController
                                                                      .logtextColor,
                                                                ),
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _showConfirmPassword =
                                                                        !_showConfirmPassword;
                                                                  });
                                                                },
                                                              )
                                                            : IconButton(
                                                                icon: Icon(
                                                                  Icons
                                                                      .edit_outlined,
                                                                  color: widget
                                                                      .themeController
                                                                      .logtextColor,
                                                                ),
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _isPasswordEditable =
                                                                        !_isPasswordEditable;
                                                                    _confirmpassword =
                                                                        !_confirmpassword;
                                                                  });
                                                                },
                                                              ),
                                                        hintText:
                                                            "Confirm Password",
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color: widget
                                                              .themeController
                                                              .hintColor,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 5,
                                                              horizontal:
                                                                  MediaQuery.of(
                                                                    context,
                                                                  ).size.width *
                                                                  0.02,
                                                            ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: Colors
                                                                    .transparent,
                                                                width: 1.0,
                                                              ),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              borderSide:
                                                                  const BorderSide(
                                                                    color: Color(
                                                                      0xFF64B5F6,
                                                                    ),
                                                                    width: 2.0,
                                                                  ),
                                                            ),
                                                        filled: true,
                                                        fillColor: widget
                                                            .themeController
                                                            .logboxColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _editprofile = true;
                                                        _confirmpassword =
                                                            false;
                                                        _isPasswordEditable =
                                                            false;
                                                        showChecklist = false;
                                                        _showPassword = false;
                                                        _showConfirmPassword =
                                                            false;
                                                      });
                                                    },
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        side: const BorderSide(
                                                          color: Color(
                                                            0xFF64B5F6,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Space Grotesk',
                                                        color: Color(
                                                          0xFF64B5F6,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed:
                                                        _saveProfileChanges,
                                                    style: TextButton.styleFrom(
                                                      backgroundColor: Color(
                                                        0xFF64B5F6,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      "Save",
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Space Grotesk',
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Profile picture overlapping the card (For Profile)
                            Positioned(
                              top: -60,
                              left: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: GestureDetector(
                                  onTap: _handleProfileImageTap,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.themeController.isDarkMode
                                            ? Colors.white24
                                            : Colors.black12,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            0.1,
                                          ), // Subtle shadow for depth
                                          blurRadius: 4,
                                          offset: Offset(
                                            2,
                                            2,
                                          ), // Shadow positioned below
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child:
                                          _imageUrl != null &&
                                              _imageUrl!.isNotEmpty
                                          ? Image.network(
                                              _imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: widget
                                                        .themeController
                                                        .headerColor,
                                                  ),
                                            )
                                          : Container(
                                              color: widget
                                                  .themeController
                                                  .appColor,
                                              child: Icon(
                                                Icons.add_a_photo_rounded,
                                                size: 40,
                                                color: widget
                                                    .themeController
                                                    .headerColor,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (_editprofile)
                    //Organization buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 5),
                      child: CreateOrg(
                        themeController: widget.themeController,
                        orgID: orgID,
                        orgName: orgName,
                        onThemeChanged: () {
                          _loadUserData(); // Reload user data after leaving org
                          setState(() {});
                        },
                      ),
                    ),

                  if (_editprofile) ...[
                    // If theres an org joined
                    if (orgID != null) ...[
                      Builder(
                        builder: (context) {
                          print(
                            'Building OrgBox with orgID: $orgID, userAccess: $userAccess',
                          );
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(25, 10, 25, 5),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: widget.themeController.boxColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.1,
                                    ), // Subtle shadow for depth
                                    blurRadius: 4,
                                    offset: Offset(
                                      2,
                                      2,
                                    ), // Shadow positioned below
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OrgBox(
                                      themeController: widget.themeController,
                                      orgID: orgID!,
                                      userAccess: userAccess,
                                      onThemeChanged: () {
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      Builder(
                        builder: (context) {
                          print('OrgBox NOT shown - orgID is null');
                          return SizedBox.shrink();
                        },
                      ),
                    ],

                    // New white box below
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 5,
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: widget.themeController.boxColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.1,
                              ), // Subtle shadow for depth
                              blurRadius: 4,
                              offset: Offset(2, 2), // Shadow positioned below
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _editprofile = false;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.list_alt_outlined,
                                      color: widget.themeController.headerColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Edit Profile Information",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'SpaceGrotesk',
                                        color:
                                            widget.themeController.headerColor,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              SizedBox(height: profileboxgap),
                              // Notifications
                              // GestureDetector(
                              //   onTap: () {
                              //     print('Tapped!');
                              //   },
                              //   child: Row(
                              //     children: [
                              //       Icon(
                              //         Icons.notifications,
                              //         color: widget.themeController.headerColor,
                              //       ),
                              //       const SizedBox(width: 12),
                              //       Text(
                              //         "Notifications",
                              //         style: TextStyle(
                              //           fontSize: 16,
                              //           fontFamily: 'SpaceGrotesk',
                              //           color:
                              //               widget.themeController.headerColor,
                              //         ),
                              //       ),
                              //       const Spacer(),
                              //     ],
                              //   ),
                              // ),
                              // SizedBox(height: profileboxgap),
                              // Dark Mode toggle
                              Row(
                                children: [
                                  Icon(
                                    Icons.dark_mode,
                                    color: widget.themeController.headerColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Dark Mode",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'SpaceGrotesk',
                                      color: widget.themeController.headerColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        widget.themeController.toggleTheme();
                                        widget.onThemeChanged?.call();
                                      });
                                    },
                                    child: Container(
                                      width: 60,
                                      height: 30,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: widget.themeController.isDarkMode
                                            ? Colors.black
                                            : Colors.grey[300],
                                      ),
                                      child: AnimatedAlign(
                                        alignment:
                                            widget.themeController.isDarkMode
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                widget
                                                    .themeController
                                                    .isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: profileboxgap),
                              ProfileSettings(
                                icon: Icons.chat,
                                title: "Contact Us",
                                color: widget.themeController.headerColor,
                                destination: ContactUsPage(
                                  themeController: widget.themeController,
                                ),
                              ),
                              SizedBox(height: profileboxgap),
                              // ProfileSettings(
                              //   icon: Icons.report,
                              //   title: "Report a Problem",
                              //   color: widget.themeController.headerColor,
                              //   destination: EditInformationPage(),
                              // ),
                              // SizedBox(height: profileboxgap),
                              ProfileSettings(
                                icon: Icons.article,
                                title: "Terms and Conditions",
                                color: widget.themeController.headerColor,
                                destination: TermsAndConditionsPage(
                                  themeController: widget.themeController,
                                ),
                              ),
                              SizedBox(height: profileboxgap),
                              ProfileSettings(
                                icon: Icons.info_outline,
                                title: "About Us",
                                color: widget.themeController.headerColor,
                                destination: AboutUsPage(
                                  themeController: widget.themeController,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.themeController.boxColor,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: Color(0xFFD32F2F),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                await SupabaseConfig.signOut(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(
                                      themeController: widget.themeController,
                                      onThemeChanged: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Logout",
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'SpaceGrotesk',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
  final FocusNode? focusNode;

  const PasswordChecklist({
    super.key,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.hasMinLength,
    required this.themeController,
    this.focusNode,
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

// --------------- END ---------------

// Put this **outside** the ProfilePage class
class TopHoleClipper extends CustomClipper<Path> {
  final double radius;
  TopHoleClipper(this.radius);

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width / 2 - radius, 0);
    path.arcToPoint(
      Offset(size.width / 2 + radius, 0),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class ProfileSettings extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget destination; // the page to navigate to

  const ProfileSettings({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'SpaceGrotesk',
              color: color,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class EditProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hinttext;
  final String? initialValue;
  final IconData? icon;
  final dynamic
  themeController; // Replace `dynamic` with your actual ThemeController type

  EditProfileField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hinttext,
    required this.initialValue,
    required this.icon,
    required this.themeController,
  }) : super(key: key) {
    // 👇 Set the initial value once when the widget is created
    controller.text = initialValue ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: "SpaceGrotesk",
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: themeController.loginColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Subtle shadow for depth
                blurRadius: 4,
                offset: Offset(2, 2), // Shadow positioned below
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: themeController.logtextColor,
              fontFamily: "SpaceGrotesk",
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: themeController.loghintColor),
              hintText: label,
              hintStyle: TextStyle(
                fontSize: 12,
                color: themeController.hintColor,
                fontStyle: FontStyle.italic,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 5,
                horizontal: MediaQuery.of(context).size.width * 0.02,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.transparent,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF64B5F6),
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: themeController.logboxColor,
            ),
          ),
        ),
      ],
    );
  }
}
