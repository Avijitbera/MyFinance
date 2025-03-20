import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfinance/home_screen.dart';
import 'package:provider/provider.dart';

import 'finance_provider.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> updateUserFcmToken() async {
    try {
      final userId = _auth.currentUser?.uid;
      final token = await _messaging.getToken();
      print("--------------------------------");
      print(token);
      print("--------------------------------");
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  

  Future<void> signInWithEmail(String email, String password, {
    required BuildContext context
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'userId': userCredential.user!.uid,
          });
        } else {
          // Update last login time
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }

        // Update FCM token
        await updateUserFcmToken();
      }

      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) {
          return HomeScreen();
        }), (v) => false);
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
      
      if (userCredential.user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'userId': userCredential.user!.uid,
        });

        // Update FCM token
        await updateUserFcmToken();
      }

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