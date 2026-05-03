import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/domain/models/gym_model.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepository(FirebaseFirestore.instance);
});

class SuperAdminRepository {
  final FirebaseFirestore _firestore;

  SuperAdminRepository(this._firestore);

  // 1. Get all gyms stream
  Stream<List<GymModel>> getAllGyms() {
    return _firestore.collection('gyms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => GymModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // 2. Activate/Deactivate Gym
  Future<void> updateGymStatus(String gymId, bool isActive) async {
    await _firestore.collection('gyms').doc(gymId).update({'isActive': isActive});
  }

  // 3. Extend Subscription
  Future<void> extendSubscription(String gymId, int daysToAdd) async {
    final docRef = _firestore.collection('gyms').doc(gymId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) throw Exception('Gym not found');
      
      final gym = GymModel.fromMap(doc.data()!, doc.id);
      
      // If already expired, start from today. Else append to existing end date.
      final baseDate = gym.subscriptionEnd.isBefore(DateTime.now()) 
          ? DateTime.now() 
          : gym.subscriptionEnd;
          
      final newEndDate = baseDate.add(Duration(days: daysToAdd));

      transaction.update(docRef, {
        'subscriptionEnd': Timestamp.fromDate(newEndDate),
        'isActive': true, 
      });
    });
  }

  // 4. Delete Gym and associated Owner User (Soft delete pattern or raw delete)
  Future<void> deleteGym(String gymId, String ownerId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('gyms').doc(gymId));
    batch.delete(_firestore.collection('users').doc(ownerId));
    
    // In a real app we'd also delete members/workouts via Cloud Functions or recursive delete
    await batch.commit();
  }
}
