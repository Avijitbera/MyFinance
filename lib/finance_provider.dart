
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myfinance/finance_model.dart';
import 'package:uuid/uuid.dart';
import 'finance_model.dart' as finance;

class FinanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSyncing = false;
  bool _isOnline = true;

  List<finance.Transaction> _transections = [];
  List<Category> _categories = [];

  bool get isOnline => _isOnline;
  List<Category> get categories => _categories;

  List<finance.Transaction> get transactions =>_transections; // Temporary empty list, will implement Firestore stream later
  bool get isSyncing => _isSyncing;

  double getMoney(){
    var ammount = _transections.fold<double>(0, (e, v) => e + v.amount);
    return ammount;
  }

  Future<void> initialize() async {
    await _loadLocalCategories();
    _checkConnectivity();
    await syncLocalWithCloud();
  }

  Future<void> _loadLocalCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
          .get();

      _categories = snapshot.docs
          .map((doc) => Category(
                id: doc.id,
                name: doc['name'],
                
                userId: doc['userId'],
              ))
          .toList();
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
    _transections.add(transaction);
    notifyListeners();
    if (_isOnline) {
      final doc = _firestore.collection('transactions').doc();
      await doc.set({
        'amount': transaction.amount,
        'title': transaction.title,
        'date': transaction.date,
        'type': transaction.type,
      });
      transaction.firestoreId = doc.id;
    }

    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    _categories.add(category.copyWith(id: Uuid().v4()));
     notifyListeners();
    final doc = _firestore.collection('categories').doc();
    await doc.set({
      'name': category.name,
      
      'userId': category.userId,
    });
    
   
  }

  Future<void> updateCategory(Category category) async {
    await _firestore.collection('categories').doc(category.id).update({
      'name': category.name,
      
    });
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> syncLocalWithCloud() async {
    if (!_isOnline) return;
    return;
    _isSyncing = true;
    notifyListeners();

    final snapshot = await _firestore.collection('transactions').get();
    final localTransactions = snapshot.docs.map((doc) => finance.Transaction(
      id: doc['id'],
      amount: doc['amount'],
      title: doc['title'],
      date: (doc['date'] as Timestamp).toDate(),
      type: doc['type'],
      firestoreId: doc.id,
      category: doc['category']
    )).toList();
    final batch = _firestore.batch();

    for (var transaction in localTransactions) {
      if (transaction.firestoreId == null) {
        final doc = _firestore.collection('transactions').doc();
        batch.set(doc, {
          'amount': transaction.amount,
          'title': transaction.title,
          'date': transaction.date,
          'type': transaction.type,
        });
        transaction.firestoreId = doc.id;
      }
    }
    await batch.commit();
    
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _syncCloudWithLocal() async {
    final snapshot = await _firestore.collection('transactions').get();
    final remoteTransactions = snapshot.docs.map((doc) {
      return finance.Transaction(
        id: doc['id'],
        amount: doc['amount'],
        title: doc['title'],
        date: (doc['date'] as Timestamp).toDate(),
        type: doc['type'],
        firestoreId: doc.id,
        category: doc['category']
      );
    }).toList();

    // await _transactionsBox.clear();
    // for (var transaction in remoteTransactions) {
    //   await _transactionsBox.put(transaction.firestoreId, transaction);
    // }
    notifyListeners();
  }

  Future<void> initializeDefaultCategories(String userId) async {
    final defaultCategories = [
        {'name': 'Food'},
        {'name': 'Transport'},
        {'name': 'Salary', },
        {'name': 'Rent',},
      ];

      for(var item in defaultCategories){
        _categories.add(Category(
          id: Uuid().v4(),
          name: item['name']!,
          userId: userId

        ));
      }




    final categoriesRef = _firestore.collection('categories');
    final snapshot = await categoriesRef.where('userId', isEqualTo: userId).get();

    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      
      

      for (var category in defaultCategories) {
        final doc = categoriesRef.doc();
        batch.set(doc, {
          'name': category['name'],
         
          'userId': userId,
        });
      }
      await batch.commit();
      await _loadLocalCategories();
    }
  }
  

  Future<void> deleteCategory(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(id)
          .delete();
      
      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
    }
  }
}