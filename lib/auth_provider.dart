import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myfinance/home_screen.dart';
import 'package:provider/provider.dart';

import 'finance_provider.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> signInWithEmail(String email, String password,{
    required BuildContext context
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushAndRemoveUntil(context,
                 MaterialPageRoute(builder: (context) {
                   return HomeScreen();
                 },),  (v) =>false);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
// await financeProvider.initializeDefaultCategories(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}