import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fund_buddy/entity/organization.dart';

class OrganizationDatabase {
  // Database to organizations
  final database = Supabase.instance.client.from('organizations');

  // Create
  Future createOrganization(Organization newOrganization) async {
    final response = await database
        .insert(newOrganization.toMap(includeId: false)) // no organizationID here
        .select()
        .single();

    return response; // you get the auto-generated ID back
  }

  // Read
  final stream = Supabase.instance.client
      .from('organizations')
      .stream(primaryKey: ['organizationID']).map((data) => data.map((orgMap) => Organization.fromMap(orgMap)).toList());

  // Update
  Future updateOrganization(int organizationID, Map<String, dynamic> newOrganization) async {
    await database
        .update(newOrganization)
        .eq('organizationID', organizationID);
  }

  // Delete
  Future deleteOrganization(int organizationID) async {
    await database.delete().eq('organizationID', organizationID);
  }
}