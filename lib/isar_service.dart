import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import 'package:myfinance/category_model.dart';
import 'package:myfinance/finance_model.dart' as finance;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfinance/finance_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  late Isar isar;

  factory IsarService() => _instance;

  IsarService._internal();

  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.transactions.clear();
      await isar.categorys.clear();
    });
    await isar.close();
  }

  Future<void> initialize() async {
    var path = await getApplicationDocumentsDirectory();
    // if(isar == null && isar.isOpen == false){

    // isar = await Isar.open(
    //   directory: path.path,
    //   [TransactionSchema, CategorySchema],
    //   inspector: true,
    // );
    // }
    // if(isar.isOpen) return;
    isar = await Isar.open(
      directory: path.path,
      [TransactionSchema, CategorySchema],
      inspector: true,
    );
    saveDefaultCategory();
  }

  void saveDefaultCategory()async{
    final defaultCategories = [
        {'name': 'Food'},
        {'name': 'Transport'},
        {'name': 'Salary', },
        {'name': 'Rent',},
      ];
      var user = FirebaseAuth.instance.currentUser;

      for(var item in defaultCategories){
        var hasData = await isar.categorys.filter().nameEqualTo(item['name']!).findFirst();
        if(hasData == null){
          await addCategory(Category(name: item['name']!,
          id: Uuid().v4(),
          userId: user!.uid,
          ));
        }

      }

  }

  void saveIfNotExists(finance.Transaction transaction)async{
    var hasData = await isar.transactions.filter().idEqualTo(transaction.id).findFirst();
    if(hasData == null){
      await isar.writeTxn(() async {
        await isar.transactions.put(transaction);
      });
    }
  }
  
  

  Future<List<finance.Transaction>> getTransections() async {
    return await isar.transactions.where().findAll();
  }

  Future<List<Category>> getCategories() async {
    return await isar.categorys.where().findAll();
  }

  Future<void> addCategory(Category category) async {
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
  }



void saveCategoryIfNotExists(Category category)async{
    var hasData = await isar.categorys.filter().nameEqualTo(category.name).findFirst();
    if(hasData == null){
      await isar.writeTxn(() async {
        await isar.categorys.put(category);
      });
  }
}


  Future<void> removeCategory(String id) async {
    await isar.writeTxn(() async {
      await isar.categorys.filter().idEqualTo(id).deleteFirst();
     
    });
  }

  Future<void> updateCategory(Category category) async {
    await isar.writeTxn(() async {
      var r = await isar.categorys.put(category);
      print(r);
    });
  }

  Future<void> addTransaction(finance.Transaction transaction) async {
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
    });
  }

  Future<void> updateTransaction(finance.Transaction transaction) async {
    await isar.writeTxn(() async {
      var tr = await isar.transactions.filter().idEqualTo(transaction.id).findFirst();
      if(tr != null){
        await isar.transactions.filter().idEqualTo(transaction.id).deleteFirst();
        tr = tr.copyWith(amount: transaction.amount, 
        title: transaction.title, 
        date: transaction.date, 
        type: transaction.type,
        );
        var r = await isar.transactions.put(tr);
        print(r);
      }
    });
  }

  Future<void> deleteTransaction(finance.Transaction transaction) async {
    await isar.writeTxn(() async {
      await isar.transactions.filter().idEqualTo(transaction.id).deleteAll();
    });
  }

  Future<void> syncWithFirestore() async {
    final unsyncedTransactions = await isar.transactions
        .where()
        
        .findAll();

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('transactions');

    for (final transaction in unsyncedTransactions) {
      var result = await collection.where("id", isEqualTo: transaction.id).get();
      if(result.docs.isEmpty){
final doc = collection.doc(transaction.id);
      batch.set(doc, transaction.toMap());
      transaction.firestoreId = doc.id;
      }
      
    }

    await batch.commit();

    await isar.writeTxn(() async {
      await isar.transactions.putAll(unsyncedTransactions);
    });


  }




}