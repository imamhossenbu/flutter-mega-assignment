import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/firebase_service.dart';

class ReviewProvider extends ChangeNotifier {
  final Map<String, List<ReviewModel>> _reviewsCache = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  List<ReviewModel> getReviews(String productId) => _reviewsCache[productId] ?? [];

  void listenToReviews(String productId) {
    if (_subscriptions.containsKey(productId)) return;
    _subscriptions[productId] = FirebaseService.instance.streamReviews(productId).listen(
      (reviews) {
        _reviewsCache[productId] = reviews;
        notifyListeners();
      },
      onError: (e) => debugPrint('Review stream error: $e'),
    );
  }

  void stopListening(String productId) {
    _subscriptions[productId]?.cancel();
    _subscriptions.remove(productId);
  }

  Future<bool> submitReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final existing = await FirebaseService.instance.hasUserReviewed(productId, userId);
      if (existing) {
        _isSubmitting = false;
        notifyListeners();
        return false; // Already reviewed
      }

      final review = ReviewModel(
        id: 'review_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      );

      await FirebaseService.instance.addReview(productId, review);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
