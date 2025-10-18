import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/widgets/add_member.dart';
import 'package:fund_buddy/pages/widgets/org_info.dart';
import '../../supabase_config.dart';
import 'theme_toggle.dart';

class OrgBox extends StatefulWidget {
  final ThemeController themeController;
  final VoidCallback? onThemeChanged;
  final String orgID;
  final String? userAccess;

  const OrgBox({
    super.key,
    required this.themeController,
    required this.orgID,
    this.userAccess,
    this.onThemeChanged,
  });

  @override
  State<OrgBox> createState() => _OrgBox();
}

class _OrgBox extends State<OrgBox> {
  String? orgName;
  String? orgAbbreviation;
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.themeController.loadTheme().then((_) {
      setState(() {}); // rebuild to apply saved theme
    });
    _loadOrganizationData();
  }

  Future<void> _loadOrganizationData() async {
    print('_loadOrganizationData() called with orgID: ${widget.orgID}');
    print('orgID type: ${widget.orgID.runtimeType}');

    try {
      // Try parsing orgID as int if it's a string representation of a number
      dynamic orgIDValue = widget.orgID;
      if (int.tryParse(widget.orgID) != null) {
        orgIDValue = int.parse(widget.orgID);
        print('Converted orgID to int: $orgIDValue');
      }

      // Fetch organization details
      print('Fetching organization with orgID: $orgIDValue');
      final orgResponse = await SupabaseConfig.client
          .from('organization')
          .select('orgName, abbreviation')
          .eq('orgID', orgIDValue)
          .maybeSingle();

      print('Organization response: $orgResponse');
      print('Organization response type: ${orgResponse.runtimeType}');

      // Fetch all members of this organization
      print('Fetching members with orgID: $orgIDValue');
      final membersResponse = await SupabaseConfig.client
          .from('user')
          .select('id, firstName, lastName, profileImageUrl, userAccess, role')
          .eq('orgID', orgIDValue);

      print('Members response: $membersResponse');
      print('Members response type: ${membersResponse.runtimeType}');
      print('Members count: ${membersResponse.length}');

      setState(() {
        orgName = orgResponse?['orgName'] ?? 'Unknown Organization';
        orgAbbreviation = orgResponse?['abbreviation'] ?? orgName ?? 'ORG';
        members = List<Map<String, dynamic>>.from(membersResponse);
        isLoading = false;
        print('OrgBox loaded successfully!');
        print('   - orgName: $orgName');
        print('   - orgAbbreviation: $orgAbbreviation');
        print('   - members count: ${members.length}');
      });
    } catch (e, stackTrace) {
      print('Error loading organization data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = widget.themeController;

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsetsGeometry.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                orgName ?? 'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w700,
                  color: widget.themeController.headerColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrgInfo(
                        themeController: widget.themeController,
                        orgID: widget.orgID,
                        userAccess: widget.userAccess,
                        onThemeChanged: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.more_horiz,
                  color: widget.themeController.headerColor,
                ),
              ),
            ],
          ),
          Divider(color: themeController.navColor),

          // Display all members
          ...members.map((member) {
            String fullName =
                '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                    .trim();
            String role = member['role'] ?? 'Member';
            String? profileImageUrl = member['profileImageUrl'];
            String memberId = member['id'];
            String currentUserId = SupabaseConfig.client.auth.currentUser?.id ?? '';
            bool isCurrentUser = memberId == currentUserId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: OfficerProfile(
                name: fullName,
                role: role,
                profileImageUrl: profileImageUrl,
                themeController: themeController,
                isCurrentUser: isCurrentUser,
              ),
            );
          }).toList(),

          SizedBox(height: 3),

          // Only show Add Member button if user is Admin
          if (widget.userAccess == 'Admin')
            Row(
              children: [
                Icon(Icons.person_add, color: Color(0xFF64B5F6), size: 35),
                SizedBox(width: 6),
                _buildAddMemberButton(context),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAddMemberButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => AddMember(
                  themeController: widget.themeController,
                  orgID: widget.orgID,
                  orgAbbreviation: orgAbbreviation ?? 'ORG',
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
      label: const Text(
        'Add Member',
        style: TextStyle(
          color: Color(0xFF64B5F6),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );
  }
}

class OfficerProfile extends StatelessWidget {
  final String name;
  final String role;
  final String? profileImageUrl;
  final ThemeController themeController;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeController.appColor,
          ),
          child: profileImageUrl != null && profileImageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    profileImageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 20,
                        color: themeController.headerColor,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 20,
                  color: themeController.headerColor,
                ),
        ),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      color: themeController.headerColor,
                    ),
                  ),
                  if (isCurrentUser)
                    TextSpan(
                      text: ' (Me)',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w500,
                        color: themeController.headerColor.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              role,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w500,
                color: themeController.headerColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
