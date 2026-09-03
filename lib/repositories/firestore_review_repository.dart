import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class FirestoreReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  Future<void> create(Review review) {
    return _reviews.add(review.toMap());
  }

  // All reviews received by a user
  Stream<List<Review>> watchForUser(String targetUserId) {
    return _reviews
        .where('targetUserId', isEqualTo: targetUserId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Review.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> delete(String id) {
    return _reviews.doc(id).delete();
  }
}