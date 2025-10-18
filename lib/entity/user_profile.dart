import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fund_buddy/supabase_config.dart';

class UserProfile {
  String id;
  String? username;
  String? email;
  int? orgID;
  String? firstName;
  String? lastName;
  String? profileImageUrl;

  UserProfile({
    required this.id
  });

  // Fetch current user details from Supabase
  static Future<UserProfile?> getCurrentUser(id) async {
    try {
      final userData = await SupabaseConfig.client
          .from('user')
          .select()
          .eq('id', id)
          .single();
      
      return UserProfile(id: userData['id'])
        ..username = userData['username']
        ..email = userData['email']
        ..orgID = userData['orgID']
        ..firstName = userData['firstName']
        ..lastName = userData['lastName']
        ..profileImageUrl = userData['profileImageUrl'];
      } catch (e) {
        print('Error fetching user: $e');
        return null;
    }
  }
}