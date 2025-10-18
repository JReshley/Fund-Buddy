class Organization {
  final String? orgID;
  final String orgName;
  final String description;
  final String logoUrl;
  final String abbreviation;

  Organization({
    required this.orgName,
    required this.description,
    required this.logoUrl,
    required this.abbreviation,
    this.orgID,
  });

  // Convert a Map object into an Organization object
  factory Organization.fromMap(Map<String, dynamic> json) {
    return Organization(
      orgName: json['orgName'] as String,
      description: json['description'] as String,
      logoUrl: json['logoUrl'] as String,
      abbreviation: json['abbreviation'] as String,
    );
  }

  // Convert an Organization object into a Map object
  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = {
      'orgID': orgID,
      'orgName': orgName,
      'description': description,
      'logoUrl': logoUrl,
      'abbreviation': abbreviation,
    };

    if (includeId && orgID != null) {
    map['orgID'] = orgID;
    } 
    return map;
  }
}