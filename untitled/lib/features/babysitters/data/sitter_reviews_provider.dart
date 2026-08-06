import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/features/babysitters/data/babysitter_repository.dart';
import 'package:babysitter/shared/models/review_model.dart';

final sitterReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((ref, sitterId) async {
  final repo = ref.read(babysitterRepositoryProvider);
  return repo.getSitterReviews(sitterId);
});
