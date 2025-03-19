
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myfinance/finance_model.dart';
import 'package:uuid/uuid.dart';
import 'category_model.dart';
import 'finance_model.dart' as finance;
import 'isar_service.dart';

class FinanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSyncing = false;
  bool _isOnline = true;

  final IsarService _isarService = IsarService();
  List<Category> _categories = [];

  bool get isOnline => _isOnline;
  List<Category> get categories => _categories;

  List<finance.Transaction> _transactions = [];

  List<finance.Transaction> get transactions => _transactions; // Temporary empty list, will implement Firestore stream later
  bool get isSyncing => _isSyncing;

  double getMoney()  {
    // final transactions = await _isarService.isar.transactions.where().findAll();
    return transactions.fold<double>(0, (e, v) => e + v.amount);
  }

  Future<void> initialize() async {
    await _isarService.initialize();
    // initializeDefaultCategories();
    
    var _result = await _isarService.getTransections();
    _transactions = _result;
    
    // for(var item in _cat){
    //   var hasData = _categories.indexWhere((c) => c.name == item.name);
    //   if (hasData!= -1) continue;
    //   _categories.add(Category(
    //     id: item.id,
    //     name: item.name,
    //     userId: item.userId,
    //   ));
    // }
    
    notifyListeners();
    Future.delayed(Duration(milliseconds: 400),()async{
      var _cat = await _isarService.getCategories();
    _categories = _cat;
    });

    // await _loadLocalCategories();
    _checkConnectivity();
    await syncLocalWithCloud();
    _syncCloudWithLocal();
    _loadLocalCategories();
  }

  Future<void> _loadLocalCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
          .get();
        
        for(var item in snapshot.docs){
          var hasData = _categories.indexWhere((c) => c.name == item.data()['name']);
          if(hasData != -1) continue;
          var cat = Category(
            id: item.id,
            name: item.data()['name'],
            userId: item.data()['userId'],
          );
          _categories.add(cat);
          _isarService.saveCategoryIfNotExists(cat);
        }

      // _categories = snapshot.docs
      //     .map((doc) => Category(
      //           id: doc.id,
      //           name: doc['name'],
                
      //           userId: doc['userId'],
      //         ))
      //     .toList();
    }
    notifyListeners();
  }

  Future<void> _checkConnectivity() async {
    Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) _syncCloudWithLocal();
    });
  }

  Future<void> addTransaction(finance.Transaction transaction) async {
    _transactions.add(transaction);
    notifyListeners();
    await _isarService.addTransaction(transaction);
    if (_isOnline) {
      final doc = _firestore.collection('transactions').doc(transaction.id);
      transaction.firestoreId = doc.id;
      await doc.set(transaction.toMap());
     
    }

    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _isarService.addCategory(category);
    _categories.add(category);
    notifyListeners();
    final doc = _firestore.collection('categories').doc(category.id);
    await doc.set({
      'name': category.name,
      'userId': category.userId,
    });
    
    
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
    await _isarService.updateCategory(category);
    
    await _firestore.collection('categories').doc(category.id).update({
      'name': category.name,
    });
    
  }

  Future<void> syncLocalWithCloud() async {
    if (!_isOnline) return;
    _isSyncing = true;
    notifyListeners();
    await _isarService.syncWithFirestore();

    // for (var transaction in localTransactions) {
    //   if (transaction.firestoreId == null) {
    //     final doc = _firestore.collection('transactions').doc();
    //     batch.set(doc, {
    //       'amount': transaction.amount,
    //       'title': transaction.title,
    //       'date': transaction.date,
    //       'type': transaction.type,
    //     });
    //     transaction.firestoreId = doc.id;
    //   }
    // }
    // await batch.commit();
    
    _isSyncing = false;
    notifyListeners();
  }


  Future<void> clearAllData() async {
    _transactions.clear();
    _categories.clear();
    notifyListeners();
    await _isarService.clearAllData();
  }

  Future<void> _syncCloudWithLocal() async {
    final snapshot = await _firestore.collection('transactions').orderBy("date", descending: true).get();
    final remoteTransactions = snapshot.docs.map((doc) {
      return finance.Transaction(
        id: doc['id'],
        amount: doc['amount'],
        title: doc['title'],
        date: DateTime.parse(doc['date']),
        type: doc['type'],
        firestoreId: doc.id,
        category: doc['category'],
        isRecurring: doc['isRecurring'] ?? false,
        isid: doc['isid'],
        notificationTime: doc['notificationTime'],
        recurrenceFrequency: doc['recurrenceFrequency'],  
      );
    }).toList();
    if(remoteTransactions.isEmpty) return;
    for(var item in remoteTransactions){
      var hasData = _transactions.indexWhere((c) => c.id == item.id);
      if(hasData != -1) continue;
      _transactions.add(item);
      _isarService.saveIfNotExists(item);
    }

    // await _transactionsBox.clear();
    // for (var transaction in remoteTransactions) {
    //   await _transactionsBox.put(transaction.firestoreId, transaction);
    // }

    var cat = await _firestore.collection('categories').get();
    for(var item in cat.docs){
      var hasData = _categories.indexWhere((c) => c.name == item.data()['name']);
      if(hasData != -1) continue;
      var cat = Category(
        id: item.id,
        name: item.data()['name'],
        userId: item.data()['userId'],
      );
      _categories.add(cat);
      _isarService.saveCategoryIfNotExists(cat);
    }
    notifyListeners();
  }

  Future<void> initializeDefaultCategories() async {
    final defaultCategories = [
        {'name': 'Food'},
        {'name': 'Transport'},
        {'name': 'Salary', },
        {'name': 'Rent',},
      ];

      var user = FirebaseAuth.instance.currentUser;

       for (var item in defaultCategories){
        var hasData = _categories.indexWhere((c) => c.name == item['name']);
        if (hasData != -1) continue;
        var cat= Category(
          id: Uuid().v4(),
          name: item['name']!,
          userId: user!.uid

        );
        _categories.add(cat);



        await _isarService.addCategory(cat);
      }




    // final categoriesRef = _firestore.collection('categories');
    // final snapshot = await categoriesRef.where('userId', isEqualTo: userId).get();

    // if (snapshot.docs.isEmpty) {
    //   final batch = _firestore.batch();
      
      

    //   for (var category in defaultCategories) {
    //     final doc = categoriesRef.doc();
    //     batch.set(doc, {
    //       'name': category['name'],
         
    //       'userId': userId,
    //     });
    //   }
    //   await batch.commit();
    //   await _loadLocalCategories();
    // }
  }
  

  Future<void> deleteCategory(Category category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _categories.removeWhere((categor) => categor.id == category.id);
      notifyListeners();
      await _isarService.removeCategory(category.id);
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(category.id)
          .delete();
      
      
    } catch (e) {
      print('Error deleting category: $e');
    }
  }
}