
import 'package:isar/isar.dart';

part 'finance_model.g.dart';

@Collection()
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
  Id isid = Isar.autoIncrement;

  Transaction({
    required this.id,
    required this.amount,
    required this.title,
    required this.date,
    required this.type,
    this.firestoreId,
    this.isid = Isar.autoIncrement,
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
      'category':category,
      'isid': isid,
      'id':id
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
      category: json['category'],
      isid: json['isid'],
    );
  }
}

