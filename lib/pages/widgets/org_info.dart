import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import 'package:fund_buddy/pages/widgets/add_member.dart';
import 'package:fund_buddy/supabase_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrgInfo extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  final String orgID;
  final String? userAccess;

  const OrgInfo({
    super.key,
    required this.themeController,
    required this.orgID,
    this.userAccess,
    this.onThemeChanged,
  });

  @override
  State<OrgInfo> createState() => _OrgInfoState();
}

class _OrgInfoState extends State<OrgInfo> {
  // Organization data
  String orgName = 'Loading...';
  String abbreviation = 'Loading...';
  String description = 'Loading...';
  String? logoUrl;
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  bool isEditing = false;

  // Controllers for editing
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _abbreviationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.themeController.loadTheme().then((_) {
      setState(() {}); // rebuild to apply saved theme
    });
    _loadOrganizationData();
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _abbreviationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizationData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Parse orgID
      dynamic orgIDValue = widget.orgID;
      if (int.tryParse(widget.orgID) != null) {
        orgIDValue = int.parse(widget.orgID);
      }

      // Fetch organization details
      final orgResponse = await SupabaseConfig.client
          .from('organization')
          .select('orgName, abbreviation, description, logoUrl')
          .eq('orgID', orgIDValue)
          .single();

      // Fetch all members of this organization
      final membersResponse = await SupabaseConfig.client
          .from('user')
          .select('id, firstName, lastName, profileImageUrl, userAccess, role')
          .eq('orgID', orgIDValue);

      setState(() {
        orgName = orgResponse['orgName'] ?? 'Unknown Organization';
        abbreviation = orgResponse['abbreviation'] ?? 'N/A';
        description = orgResponse['description'] ?? 'No description available';
        logoUrl = orgResponse['logoUrl'];
        members = List<Map<String, dynamic>>.from(membersResponse);

        // Set controller values
        _orgNameController.text = orgName;
        _abbreviationController.text = abbreviation;
        _descriptionController.text = description;

        isLoading = false;
      });
    } catch (e) {
      print('Error loading organization data: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading organization data: $e')),
      );
    }
  }

  Future<void> _saveOrganizationChanges() async {
    try {
      // Parse orgID
      dynamic orgIDValue = widget.orgID;
      if (int.tryParse(widget.orgID) != null) {
        orgIDValue = int.parse(widget.orgID);
      }

      // Prepare updates
      final updates = {
        'orgName': _orgNameController.text.trim(),
        'abbreviation': _abbreviationController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      // Update organization in database
      await SupabaseConfig.client
          .from('organization')
          .update(updates)
          .eq('orgID', orgIDValue);

      // Reload data
      await _loadOrganizationData();

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization updated successfully')),
      );
    } catch (e) {
      print('Error saving organization changes: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
    }
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      // Reset controllers to original values
      _orgNameController.text = orgName;
      _abbreviationController.text = abbreviation;
      _descriptionController.text = description;
    });
  }

  Future<void> _handleLogoTap() async {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
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
              'Organization Logo',
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
                        logoUrl!,
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
        await _pickAndUploadLogo();
      }
    } else {
      // No existing logo, directly pick and upload
      await _pickAndUploadLogo();
    }
  }

  Future<void> _pickAndUploadLogo() async {
    // Parse orgID
    dynamic orgIDValue = widget.orgID;
    if (int.tryParse(widget.orgID) != null) {
      orgIDValue = int.parse(widget.orgID);
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileName = 'org_logo_$orgIDValue.jpg';

    try {
      // Store old logo URL to delete later
      String? oldLogoUrl = logoUrl;

      // Upload to Supabase Storage
      await SupabaseConfig.client.storage
          .from('logos')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final publicUrl = SupabaseConfig.client.storage
          .from('logos')
          .getPublicUrl(fileName);

      // Update organization table
      await SupabaseConfig.client
          .from('organization')
          .update({'logoUrl': publicUrl})
          .eq('orgID', orgIDValue);

      // Delete old logo from storage if it exists and is different
      if (oldLogoUrl != null &&
          oldLogoUrl.isNotEmpty &&
          oldLogoUrl != publicUrl) {
        try {
          // Extract filename from old URL
          final oldFileName = oldLogoUrl.split('/').last.split('?').first;
          await SupabaseConfig.client.storage.from('logos').remove([
            oldFileName,
          ]);
        } catch (e) {
          print('Error deleting old logo: $e');
          // Continue even if deletion fails
        }
      }

      setState(() {
        logoUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Logo upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
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
                  'Remove Member',
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
            'Are you sure you want to remove $memberName from $orgName? This action cannot be undone.',
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
                      'Yes, Remove',
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

    // If user confirmed, proceed with removal
    if (confirm == true) {
      try {
        // Update user's orgID, userAccess, and role to null
        await SupabaseConfig.client
            .from('user')
            .update({'orgID': null, 'userAccess': null, 'role': null})
            .eq('id', memberId);

        // Reload organization data to refresh the members list
        await _loadOrganizationData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$memberName has been removed from $orgName'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error removing member: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
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
          icon: Icon(
            Icons.arrow_back,
            color: widget.themeController.header2Color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Organization Information",
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.themeController.header2Color,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.userAccess == 'Admin' && !isEditing)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: widget.themeController.header2Color,
              ),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          if (isEditing)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: _cancelEditing,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organization Logo
                  Center(
                    child: GestureDetector(
                      onTap: (widget.userAccess == 'Admin' && isEditing)
                          ? _handleLogoTap
                          : null,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.themeController.boxColor,
                          border: Border.all(
                            color: widget.themeController.boxshadow,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.themeController.boxshadow,
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: logoUrl != null && logoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  logoUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      size: 60,
                                      color:
                                          widget.themeController.header2Color,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                isEditing && widget.userAccess == 'Admin'
                                    ? Icons.add_photo_alternate
                                    : Icons.business,
                                size: 60,
                                color: widget.themeController.header2Color,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Organization Details Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.themeController.boxColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: themeController.boxshadow.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Organization Name
                        _buildInfoField(
                          label: 'Organization Name',
                          value: orgName,
                          controller: _orgNameController,
                          icon: Icons.business,
                        ),
                        const SizedBox(height: 20),

                        // Abbreviation
                        _buildInfoField(
                          label: 'Abbreviation',
                          value: abbreviation,
                          controller: _abbreviationController,
                          icon: Icons.text_fields,
                        ),
                        const SizedBox(height: 20),

                        // Description
                        _buildInfoField(
                          label: 'Description',
                          value: description,
                          controller: _descriptionController,
                          icon: Icons.description,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.bold,
                          color: widget.themeController.headerColor,
                        ),
                      ),
                      if (widget.userAccess == 'Admin')
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) => AddMember(
                                      themeController: widget.themeController,
                                      orgID: widget.orgID,
                                      orgAbbreviation: abbreviation,
                                      userAccess: widget.userAccess ?? 'Member',
                                      onThemeChanged: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                )
                                .then((_) {
                                  // Reload data when returning from AddMember page
                                  _loadOrganizationData();
                                });
                          },
                          icon: const Icon(
                            Icons.person_add,
                            color: Color(0xFF64B5F6),
                            size: 20,
                          ),
                          label: const Text(
                            'Add Member',
                            style: TextStyle(
                              color: Color(0xFF64B5F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: widget.themeController.boxshadow),
                  const SizedBox(height: 10),

                  // Members List
                  if (members.isEmpty)
                    Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(
                          color: widget.themeController.textColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...members.map((member) {
                      String fullName =
                          '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                              .trim();
                      String role = member['role'] ?? 'Member';
                      String? profileImageUrl = member['profileImageUrl'];
                      String memberId = member['id'];
                      String currentUserId =
                          SupabaseConfig.client.auth.currentUser?.id ?? '';
                      bool isCurrentUser = memberId == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: OfficerProfileWithRemove(
                          name: fullName,
                          role: role,
                          profileImageUrl: profileImageUrl,
                          themeController: widget.themeController,
                          isAdmin: widget.userAccess == 'Admin',
                          memberId: memberId,
                          orgName: orgName,
                          isCurrentUser: isCurrentUser,
                          onRemove: () async {
                            await _removeMember(memberId, fullName);
                          },
                        ),
                      );
                    }).toList(),

                  // Save Button (only shown when editing)
                  if (isEditing) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveOrganizationChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B5F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: widget.themeController.header2Color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.bold,
                color: widget.themeController.header2Color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isEditing)
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Space Grotesk',
              color: widget.themeController.textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                color: widget.themeController.textColor.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.themeController.boxshadow,
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
              fillColor: widget.themeController.appColor,
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Space Grotesk',
              color: widget.themeController.textColor,
            ),
          ),
      ],
    );
  }
}

// OfficerProfile widget for displaying member information
class OfficerProfile extends StatelessWidget {
  final String name;
  final String role;
  final String? profileImageUrl;
  final dynamic themeController;
  final bool isCurrentUser;

  const OfficerProfile({
    super.key,
    required this.name,
    required this.role,
    this.profileImageUrl,
    required this.themeController,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeController.boxColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: themeController.boxshadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeController.appColor,
            ),
            child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profileImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 25,
                          color: themeController.headerColor,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 25,
                    color: themeController.headerColor,
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          color: themeController.headerColor,
                        ),
                      ),
                      if (isCurrentUser)
                        TextSpan(
                          text: ' (Me)',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w500,
                            color: themeController.textColor.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w500,
                    color: themeController.textColor,
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

// OfficerProfileWithRemove widget for displaying member information with remove option (OrgInfo page only)
class OfficerProfileWithRemove extends StatelessWidget {
  final String name;
  final String role;
  final String? profileImageUrl;
  final dynamic themeController;
  final bool isAdmin;
  final String memberId;
  final String orgName;
  final bool isCurrentUser;
  final VoidCallback onRemove;

  const OfficerProfileWithRemove({
    super.key,
    required this.name,
    required this.role,
    this.profileImageUrl,
    required this.themeController,
    required this.isAdmin,
    required this.memberId,
    required this.orgName,
    required this.isCurrentUser,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeController.boxColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: themeController.boxshadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeController.appColor,
            ),
            child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profileImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 25,
                          color: themeController.headerColor,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 25,
                    color: themeController.headerColor,
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          color: themeController.headerColor,
                        ),
                      ),
                      if (isCurrentUser)
                        TextSpan(
                          text: ' (Me)',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Space Grotesk',
                            fontWeight: FontWeight.w500,
                            color: themeController.textColor.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w500,
                    color: themeController.textColor,
                  ),
                ),
              ],
            ),
          ),
          // Show Remove button only if user is Admin and it's not the current user
          if (isAdmin && !isCurrentUser)
            GestureDetector(
              onTap: onRemove,
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
