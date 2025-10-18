class Transaction {
  int? transactionID;
  String? userID;
  String? sellerName;
  String? receiptControlNum;
  String? typeOfActivity;
  DateTime? date;
  double? amount;
  String? description;
  String? noteTitle;
  String? disclosure;
  final String? createdBy;
  String? updatedBy;
  String? imageUrl;
  final DateTime? createdAt;
  DateTime? updatedAt;
  bool? isUpdated = false;
  int? orgID;

  Transaction({
    required this.userID,
    this.sellerName,
    this.receiptControlNum,
    required this.typeOfActivity,
    required this.date,
    required this.amount,
    required this.description,
    required this.noteTitle,
    required this.disclosure,
    required this.createdBy,
    required this.updatedBy,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.orgID,
    this.isUpdated = false,
    this.transactionID
  });
  
  // Convert a Map object into a Transaction object
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      userID: map['userID'],
      sellerName: map['sellerName'],
      receiptControlNum: map['receiptControlNum'],
      typeOfActivity: map['typeOfActivity'],
      date: map['date'] != null ? _parseDateOnly(map['date']) : null,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      description: map['description'],
      noteTitle: map['noteTitle'],
      disclosure: map['disclosure'],
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isUpdated: map['isUpdated'] ?? false,
      transactionID: map['transactionID'],
      orgID: map['orgID'],
    );
  }

  // Convert a Transaction object into a Map object
  Map<String, dynamic> toMap({bool includeId = true}) {
  final map = {
    'userID': userID,
    'sellerName': sellerName,
    'receiptControlNum': receiptControlNum,
    'typeOfActivity': typeOfActivity,
    'date': date?.toIso8601String().substring(0, 10), // 'YYYY-MM-DD'
    'amount': amount,
    'description': description,
    'noteTitle': noteTitle,
    'disclosure': disclosure,
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'imageUrl': imageUrl,
    'createdAt': createdAt?.toIso8601String(), 
    'updatedAt': updatedAt?.toIso8601String(),
    'isUpdated': isUpdated ?? false, // Include isUpdated field
    'orgID': orgID,
  };

  if (includeId && transactionID != null) {
    map['transactionID'] = transactionID;
  }

  return map;
}

  // Helper method to parse date and return only date part (year, month, day)
  static DateTime? _parseDateOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      final DateTime parsedDate = DateTime.parse(dateString);
      // Return only year, month, day (set time to 00:00:00)
      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    } catch (e) {
      return null;
    }
  }

  // Helper method to format date for display (YYYY-MM-DD format)
  String get formattedDate {
    if (date == null) return 'No date';
    return date!.toIso8601String().substring(0, 10);
  }

  // Helper method to format createdAt for display
  String get formattedCreatedAt {
    if (createdAt == null) return '';
    return createdAt!.toIso8601String().substring(0, 10);
  }

  // Helper method to format updatedAt for display
  String get formattedUpdatedAt {
    if (updatedAt == null) return '';
    return updatedAt!.toIso8601String().substring(0, 10);
  }
}