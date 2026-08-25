import 'dart:async';
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../repositories/firestore_review_repository.dart';

class ReviewProvider with ChangeNotifier {
  final FirestoreReviewRepository _repository;

  ReviewProvider(this._repository);

  List<Review> _reviews = [];
  StreamSubscription? _subscription;

  List<Review> get reviews => _reviews;

  // Les avis reçus par un utilisateur
  void listenToUserReviews(String targetUserId) {
    _subscription?.cancel();
    _subscription =
        _repository.watchForUser(targetUserId).listen((reviews) {
      _reviews = reviews;
      notifyListeners();
    });
  }

  Future<void> addReview(Review review) => _repository.create(review);

  Future<void> deleteReview(String id) => _repository.delete(id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}