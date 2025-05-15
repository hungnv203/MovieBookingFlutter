import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập bằng email và mật khẩu
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        debugPrint("Không tìm thấy thông tin người dùng trong Firestore.");
        return null;
      }

      return {
        'user': userCredential.user,
        'role': userDoc['role'], // Lấy vai trò từ Firestore (admin hoặc customer)
      };
    } on FirebaseAuthException catch (e) {
      debugPrint("Lỗi Firebase khi đăng nhập: ${e.message}");
      return null;
    }
  }

  // Đăng nhập bằng Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint("Người dùng đã hủy đăng nhập Google.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'role': 'customer', // Mặc định Google user là customer
          'createdAt': DateTime.now(),
        });
      }

      return {
        'user': userCredential.user,
        'role': userDoc.exists ? userDoc['role'] : 'customer',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint("Lỗi Firebase khi đăng nhập Google: ${e.message}");
      return null;
    }
  }

  // Đăng ký người dùng mới với email và mật khẩu
  Future<Map<String, dynamic>?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kiểm tra nếu email là của admin thì đặt role là admin
      String role = email == 'admin123@gmail.com' ? 'admin' : 'customer';

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'password': password,
        'createdAt': DateTime.now(),
      });

      return {
        'user': userCredential.user,
        'role': role,
      };
    } on FirebaseAuthException catch (e) {
      debugPrint("Lỗi Firebase khi đăng ký: ${e.message}");
      return null;
    }
  }

  // Lấy vai trò của người dùng từ Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.data()?['role'];
    } catch (e) {
      debugPrint("Lỗi khi lấy vai trò người dùng: $e");
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut(); // Đăng xuất Google nếu có
  }
}