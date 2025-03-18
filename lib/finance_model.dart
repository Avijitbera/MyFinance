class Transaction {
  final String id;
  final double amount;
  final String title;
  final DateTime date;
  final String type;
  String? firestoreId;
  final bool isRecurring;
  final String? recurrenceFrequency;
  final String? notificationTime;
  final String category;

  Transaction({
    required this.id,
    required this.amount,
    required this.title,
    required this.date,
    required this.type,
    this.firestoreId,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.notificationTime,
    required this.category
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'title': title,
      'date': date.toIso8601String(),
      'type': type,
      'firestoreId': firestoreId,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
      'notificationTime': notificationTime,
      'category':category
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      firestoreId: json['firestoreId'],
      isRecurring: json['isRecurring'] ?? false,
      recurrenceFrequency: json['recurrenceFrequency'],
      notificationTime: json['notificationTime'],
      category: json['category']
    );
  }
}

class Category {
  final String id;
  final String name;

  final String userId;

  Category({
    required this.id,
    required this.name,
  
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      
      'userId': userId,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? userId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      
      userId: userId ?? this.userId,
    );
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'],
     
      userId: map['userId'],
    );
  }
}