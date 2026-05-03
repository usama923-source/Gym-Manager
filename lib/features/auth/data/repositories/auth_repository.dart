import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/domain/models/gym_model.dart';
import 'package:gym/features/auth/domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: \$e');
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = await getUserData(cred.user!.uid);
      if (user == null) throw Exception('User data not found in database');
      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({required String uid, required String name}) async {
    try {
      await _firestore.collection('users').doc(uid).update({'name': name});
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateEmail({required String uid, required String newEmail}) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);
        await _firestore.collection('users').doc(uid).update({'email': newEmail});
      } else {
        throw Exception('User not logged in');
      }
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
      } else {
        throw Exception('User not logged in');
      }
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Register a Gym Owner. This creates the auth account, the gym record, and the user record.
  Future<UserModel> registerGymOwner({
    required String ownerName,
    required String email,
    required String password,
    required String gymName,
  }) async {
    try {
      // 1. Create Auth User
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // 2. Create Gym Record
      final gymRef = _firestore.collection('gyms').doc();
      final gym = GymModel(
        id: gymRef.id,
        gymName: gymName,
        ownerId: uid,
        subscriptionStart: DateTime.now(),
        subscriptionEnd: DateTime.now().add(const Duration(days: 30)), // 30 day trial
        subscriptionPlan: 'Basic',
        subscriptionPrice: 0.0,
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      // 3. Create User Record
      final user = UserModel(
        id: uid,
        name: ownerName,
        email: email,
        role: UserRole.gymOwner,
        gymId: gymRef.id,
        createdAt: DateTime.now(),
      );

      // Run as batch to ensure both write or fail
      final batch = _firestore.batch();
      batch.set(gymRef, gym.toMap());
      batch.set(_firestore.collection('users').doc(uid), user.toMap());
      await batch.commit();

      return user;
    } catch (e) {
      throw Exception('Failed to register Gym Owner: \$e');
    }
  }
  // Register a Super Admin (for seeding)
  Future<UserModel> registerSuperAdmin() async {
    try {
      // 1. Create Auth User
      final cred = await _auth.createUserWithEmailAndPassword(
        email: 'admin@gym.com',
        password: 'admin123',
      );
      final uid = cred.user!.uid;

      // 2. Create User Record
      final user = UserModel(
        id: uid,
        name: 'Super Admin',
        email: 'admin@gym.com',
        role: UserRole.superAdmin,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());

      return user;
    } catch (e) {
      throw Exception('Failed to register Super Admin: $e');
    }
  }}
