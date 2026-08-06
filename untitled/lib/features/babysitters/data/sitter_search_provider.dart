import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/babysitters/data/babysitter_repository.dart';
import 'package:babysitter/shared/models/user_model.dart';

class SitterSearchState {
  final List<UserModel> sitters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final bool isInitial;

  const SitterSearchState({
    this.sitters = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.isInitial = true,
  });

  SitterSearchState copyWith({
    List<UserModel>? sitters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool? isInitial,
  }) {
    return SitterSearchState(
      sitters: sitters ?? this.sitters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      isInitial: isInitial ?? this.isInitial,
    );
  }
}

class SitterSearchNotifier extends StateNotifier<SitterSearchState> {
  final BabysitterRepository _repository;

  SitterSearchNotifier(this._repository) : super(const SitterSearchState());

  String? _sort;
  String? _category;
  String? _search;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String? _city;
  bool? _emergency;
  bool? _overnight;
  Set<String>? _skills;

  void setFilters({
    String? sort,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    bool? emergency,
    bool? overnight,
    Set<String>? skills,
  }) {
    _sort = sort;
    _category = category;
    _search = search;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    _city = city;
    _emergency = emergency;
    _overnight = overnight;
    _skills = skills;
  }

  Future<void> search() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      isInitial: false,
      currentPage: 1,
      hasMore: true,
      sitters: [],
    );

    try {
      final result = await _repository.getSittersPaginated(
        sort: _sort,
        category: _category,
        search: _search,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        city: _city,
        emergency: _emergency,
        overnight: _overnight,
        skills: _skills,
        page: 1,
        perPage: 20,
      );
      state = state.copyWith(
        sitters: result.items,
        isLoading: false,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final result = await _repository.getSittersPaginated(
        sort: _sort,
        category: _category,
        search: _search,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        city: _city,
        emergency: _emergency,
        overnight: _overnight,
        skills: _skills,
        page: nextPage,
        perPage: 20,
      );
      state = state.copyWith(
        sitters: [...state.sitters, ...result.items],
        isLoadingMore: false,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  void clear() {
    state = const SitterSearchState();
    _sort = null;
    _category = null;
    _search = null;
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _city = null;
    _emergency = null;
    _overnight = null;
    _skills = null;
  }
}

final sitterSearchProvider =
    StateNotifierProvider<SitterSearchNotifier, SitterSearchState>((ref) {
  return SitterSearchNotifier(ref.read(babysitterRepositoryProvider));
});
