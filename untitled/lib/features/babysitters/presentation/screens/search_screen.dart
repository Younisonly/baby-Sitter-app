import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/features/babysitters/data/sitter_search_provider.dart';
import 'package:babysitter/features/babysitters/presentation/widgets/sitter_card.dart';
import 'package:babysitter/features/home/data/home_repository.dart';
import 'package:babysitter/shared/models/city_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.initialCategory,
  });

  final String? initialCategory;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  final _scrollController = ScrollController();

  Set<String> _selectedCategories = {};
  double _minPrice = 0;
  double _maxPrice = 200;
  double _minRating = 0;
  String _sortBy = 'top_rated';
  bool _emergencyOnly = false;
  bool _overnightOnly = false;
  Set<String> _selectedSkills = {};
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.initialCategory != null) {
      _selectedCategories = {widget.initialCategory!};
    }
    _scrollController.addListener(_onScroll);
    ref.read(serviceCategoriesProvider);
    ref.read(citiesProvider);
    ref.read(specialSkillsProvider);
    Future.microtask(_submit);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(sitterSearchProvider.notifier).loadMore();
    }
  }

  void _submit() {
    ref.read(sitterSearchProvider.notifier).setFilters(
          category:
              _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
          search: _searchController.text.trim(),
          sort: _sortBy,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          minRating: _minRating,
          city: _selectedCity,
          emergency: _emergencyOnly ? true : null,
          overnight: _overnightOnly ? true : null,
          skills: _selectedSkills.isNotEmpty ? _selectedSkills : null,
        );
    ref.read(sitterSearchProvider.notifier).search();
  }

  bool _hasActiveFilters() {
    return _selectedCategories.isNotEmpty ||
        _minPrice > 0 ||
        _maxPrice < 200 ||
        _minRating > 0 ||
        _sortBy != 'top_rated' ||
        _emergencyOnly ||
        _overnightOnly ||
        _selectedSkills.isNotEmpty ||
        _selectedCity != null;
  }

  Future<void> _showFilterSheet() async {
    var localCategories = Set<String>.from(_selectedCategories);
    var localMinPrice = _minPrice;
    var localMaxPrice = _maxPrice;
    var localMinRating = _minRating;
    var localSortBy = _sortBy;
    var localEmergency = _emergencyOnly;
    var localOvernight = _overnightOnly;
    var localSkills = Set<String>.from(_selectedSkills);
    var localCity = _selectedCity;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final strings = AppLocalization.get(ref.watch(languageProvider).code);
            final categoriesAsync = ref.watch(serviceCategoriesProvider);
            final citiesAsync = ref.watch(citiesProvider);
            final skillsAsync = ref.watch(specialSkillsProvider);

            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: const PopupMenuThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(AppRadius.sm)),
                      ),
                    ),
                  ),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.85,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  strings[AppLocalization.filters_title] ?? 'Filters',
                                  style: AppTextStyles.titleLarge(
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              children: [
                                _sectionLabel(context, strings[AppLocalization.select_city] ?? 'City'),
                                const SizedBox(height: AppSpacing.xs),
                                citiesAsync.when(
                                  data: (cities) => _buildCityDropdown(
                                    context,
                                    cities,
                                    localCity,
                                    (v) => setSheetState(() => localCity = v),
                                    strings,
                                  ),
                                  loading: () => SizedBox(
                                    height: 100,
                                    child: const Center(
                                      child: AppLoader(size: 40),
                                    ),
                                  ),
                                  error: (_, __) => TextButton(
                                    onPressed: () => ref.invalidate(citiesProvider),
                                    child: Text(
                                      strings[AppLocalization.failed_load_cities] ?? 'Failed to load cities. Retry',
                                      style: AppTextStyles.caption(
                                        color: AppColors.error,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _sectionLabel(context, strings[AppLocalization.price_range] ?? 'Price range'),
                                const SizedBox(height: AppSpacing.xs),
                                RangeSlider(
                                  values:
                                      RangeValues(localMinPrice, localMaxPrice),
                                  min: 0,
                                  max: 500,
                                  divisions: 50,
                                  labels: RangeLabels(
                                    '﷼${localMinPrice.toStringAsFixed(0)}',
                                    '﷼${localMaxPrice.toStringAsFixed(0)}',
                                  ),
                                  onChanged: (values) {
                                    setSheetState(() {
                                      localMinPrice = values.start;
                                      localMaxPrice = values.end;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                  _sectionLabel(context, strings[AppLocalization.minimum_rating] ?? 'Minimum rating'),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: localMinRating,
                                        min: 0,
                                        max: 5,
                                        divisions: 10,
                                        label:
                                            localMinRating.toStringAsFixed(1),
                                        onChanged: (v) => setSheetState(
                                            () => localMinRating = v),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                    child: Text(
                                      localMinRating.toStringAsFixed(1),
                                      style: AppTextStyles.bodySmall(
                                        weight: FontWeight.w600,
                                        color: context.primaryColor,
                                      ),
                                    ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                  _sectionLabel(context, strings[AppLocalization.sort_by] ?? 'Sort by'),
                                const SizedBox(height: AppSpacing.xs),
                                _SortDropdown(
                                  value: localSortBy,
                                  onChanged: (v) =>
                                      setSheetState(() => localSortBy = v),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _sectionLabel(context, strings[AppLocalization.care_categories] ?? 'Care categories'),
                                const SizedBox(height: AppSpacing.xs),
                                categoriesAsync.when(
                                  data: (categories) => _FilterChips(
                                    items: categories
                                        .map((c) => (c.key, c.label))
                                        .toList(),
                                    selected: localCategories,
                                    onToggle: (key) {
                                      setSheetState(() {
                                        if (localCategories.contains(key)) {
                                          localCategories.remove(key);
                                        } else {
                                          localCategories.add(key);
                                        }
                                      });
                                    },
                                  ),
                                  loading: () => SizedBox(
                                    height: 100,
                                    child: const Center(
                                      child: AppLoader(size: 40),
                                    ),
                                  ),
                                  error: (_, __) => TextButton(
                                    onPressed: () => ref.invalidate(serviceCategoriesProvider),
                                    child: Text(
                                      strings[AppLocalization.failed_load_categories] ?? 'Failed to load categories. Retry',
                                      style: AppTextStyles.caption(
                                        color: AppColors.error,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _sectionLabel(context, strings[AppLocalization.special_skills] ?? 'Special skills'),
                                const SizedBox(height: AppSpacing.xs),
                                skillsAsync.when(
                                  data: (skills) => _FilterChips(
                                    items: skills
                                        .map((s) => (s.key, s.label))
                                        .toList(),
                                    selected: localSkills,
                                    onToggle: (key) {
                                      setSheetState(() {
                                        if (localSkills.contains(key)) {
                                          localSkills.remove(key);
                                        } else {
                                          localSkills.add(key);
                                        }
                                      });
                                    },
                                  ),
                                  loading: () => SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: AppLoader(size: 40),
                                    ),
                                  ),
                                  error: (_, __) => TextButton(
                                    onPressed: () => ref.invalidate(specialSkillsProvider),
                                    child: Text(
                                      strings[AppLocalization.failed_load_skills] ?? 'Failed to load skills. Retry',
                                      style: AppTextStyles.caption(
                                        color: AppColors.error,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _sectionLabel(context, strings[AppLocalization.availability] ?? 'Availability'),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                        child: AppToggleChip(
                                          label: strings[AppLocalization.emergency] ?? 'Emergency',
                                          icon: Icons.health_and_safety_outlined,
                                          isSelected: localEmergency,
                                          onTap: () => setSheetState(() =>
                                              localEmergency = !localEmergency),
                                        ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: AppToggleChip(
                                        label: strings[AppLocalization.overnight] ?? 'Overnight',
                                        icon: Icons.nightlight_round,
                                        isSelected: localOvernight,
                                        onTap: () => setSheetState(() =>
                                            localOvernight = !localOvernight),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setSheetState(() {
                                          localCategories = {};
                                          localMinPrice = 0;
                                          localMaxPrice = 200;
                                          localMinRating = 0;
                                          localSortBy = 'top_rated';
                                          localEmergency = false;
                                          localOvernight = false;
                                          localSkills = {};
                                          localCity = null;
                                        });
                                      },
                                      child: Text(
                                        strings[AppLocalization.reset] ?? 'Reset',
                                        style: AppTextStyles.bodySmall(),
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: AppButton(
                                        text: strings[AppLocalization.apply_filters] ?? 'Apply Filters',
                                        onPressed: () => Navigator.pop(context, true),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).padding.bottom +
                                          AppSpacing.md,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (applied == true) {
      setState(() {
        _selectedCategories = localCategories;
        _minPrice = localMinPrice;
        _maxPrice = localMaxPrice;
        _minRating = localMinRating;
        _sortBy = localSortBy;
        _emergencyOnly = localEmergency;
        _overnightOnly = localOvernight;
        _selectedSkills = localSkills;
        _selectedCity = localCity;
      });
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(appStateProvider).favoriteIds;
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    return Scaffold(
      appBar: AppAppBar(
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings[AppLocalization.search] ?? 'Search',
              style: AppTextStyles.titleMedium(
                color: context.textPrimaryColor,
              ),
            ),
            Text(
              strings[AppLocalization.search_hint] ?? 'Search for babysitters...',
              style: AppTextStyles.labelSmall(
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _hasActiveFilters()
                  ? context.primaryColor
                  : context.textSecondaryColor,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: strings[AppLocalization.search_by_name] ?? 'Search by name',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _submit();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        onPressed: _submit,
                      ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final cat in _selectedCategories)
                      AppFilterChip(
                        label: _labelFromKey(cat, strings),
                        isSelected: true,
                        showDismiss: true,
                        onDismiss: () {
                          setState(() => _selectedCategories.remove(cat));
                          _submit();
                        },
                      ),
                    if (_minPrice > 0 || _maxPrice < 200)
                      AppFilterChip(
                        label:
                            '﷼${_minPrice.toStringAsFixed(0)}-﷼${_maxPrice.toStringAsFixed(0)}',
                        isSelected: true,
                        showDismiss: true,
                        onDismiss: () {
                          setState(() {
                            _minPrice = 0;
                            _maxPrice = 200;
                          });
                          _submit();
                        },
                      ),
                    if (_minRating > 0)
                      AppFilterChip(
                        label: '${_minRating.toStringAsFixed(1)}+ ${strings[AppLocalization.stars] ?? 'نجوم'}',
                        isSelected: true,
                        showDismiss: true,
                        onDismiss: () {
                          setState(() => _minRating = 0);
                          _submit();
                        },
                      ),
                    if (_selectedCity != null)
                      AppFilterChip(
                        label: _selectedCity!,
                        isSelected: true,
                        showDismiss: true,
                        onDismiss: () {
                          setState(() => _selectedCity = null);
                          _submit();
                        },
                      ),
                    if (_emergencyOnly)
                      AppFilterChip(
                        label: strings[AppLocalization.emergency] ?? 'Emergency',
                        isSelected: true,
                        showDismiss: true,
                        onDismiss: () {
                          setState(() => _emergencyOnly = false);
                          _submit();
                        },
                      ),
                    if (_overnightOnly)
                      AppFilterChip(
                        label: strings[AppLocalization.overnight] ?? 'Overnight',
                        isSelected: true,
                        showDismiss: true,
                        onDismiss: () {
                          setState(() => _overnightOnly = false);
                          _submit();
                        },
                      ),
                    if (_selectedSkills.isNotEmpty)
                      ..._selectedSkills.map((s) => AppFilterChip(
                            label: _labelFromKey(s, strings),
                            isSelected: true,
                            showDismiss: true,
                            onDismiss: () {
                              setState(() => _selectedSkills.remove(s));
                              _submit();
                            },
                          )),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(sitterSearchProvider);

                if (state.isInitial || state.isLoading) {
                  return const ListShimmer(itemCount: 5, itemHeight: 120);
                }

                if (state.error != null && state.sitters.isEmpty) {
                  return ErrorState(
                    message: state.error ?? strings[AppLocalization.load_error_message] ?? 'Please check your connection and try again',
                    onRetry: _submit,
                  );
                }

                if (state.sitters.isEmpty) {
                  return SingleChildScrollView(
                    child: EmptyState(
                      title: strings[AppLocalization.no_matching_sitters] ?? 'No matching sitters',
                      subtitle: strings[AppLocalization.no_matching_sitters_subtitle] ?? 'Try another search or category.',
                      icon: const Icon(Icons.search_off, size: 80),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(appStateProvider.notifier)
                      .syncFavoritesFromModels(state.sitters);
                });

                return RefreshIndicator(
                  onRefresh: () async => _submit(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    itemCount: state.sitters.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.sitters.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final sitter = state.sitters[index];
                      final profile = sitter.babysitterProfile;
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SitterCard(
                          id: sitter.id,
                          name: sitter.name,
                          rating: profile?.rating ?? 0,
                          reviews: profile?.reviewCount ?? 0,
                          hourlyRate: profile?.hourlyRate ?? 0,
                          experience: profile?.yearsExperience ?? 0,
                          distance: sitter.location ?? 'Nearby',
                          imageUrl: sitter.avatar,
                          categories: profile?.categories ?? const [],
                          isFavorite: favoriteIds.contains(sitter.id),
                          isCompact: true,
                          onTap: () => context.pushNamed(
                            AppRoutes.sitterDetails,
                            pathParameters: {'id': sitter.id},
                          ),
                          onBookTap: () {
                            if (ref.read(authProvider).isAuthenticated) {
                              context.pushNamed(
                                AppRoutes.bookingFlow,
                                queryParameters: {'sitterId': sitter.id},
                              );
                            } else {
                              showLoginSheet(context, message: AppLocalization.get(ref.read(languageProvider).code)[AppLocalization.login_to_book] ?? 'Login to book a babysitter');
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown(
    BuildContext context,
    List<CityModel> cities,
    String? selectedCity,
    ValueChanged<String?> onChanged,
    Map<String, String> strings,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: const PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: context.dividerColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCity,
            hint: Text(
              strings[AppLocalization.select_city] ?? 'Select city',
              style: AppTextStyles.bodySmall(color: context.textMutedColor),
            ),
            isExpanded: true,
            isDense: true,
            menuMaxHeight: 250,
            icon: const Icon(Icons.location_on_outlined, size: 18),
            items: cities.map((city) {
              return DropdownMenuItem(
                value: city.name,
                child: Text(
                  city.name,
                  style: AppTextStyles.bodySmall(
                    color: selectedCity == city.name
                        ? context.primaryColor
                        : context.textPrimaryColor,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: AppTextStyles.bodySmall(
        weight: FontWeight.w500,
        color: context.textPrimaryColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

String _labelFromKey(String key, Map<String, String> strings) {
  if (key.isEmpty) return key;
  if (strings.containsKey(key)) return strings[key]!;
  return key
      .split('_')
      .map((word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _SortDropdown extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SortDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final items = [
      ('top_rated', strings[AppLocalization.top_rated] ?? 'Top Rated', Icons.star_rounded),
      ('price_low', strings[AppLocalization.price_low] ?? 'Price: Low to High', Icons.trending_up_rounded),
      ('price_high', strings[AppLocalization.price_high] ?? 'Price: High to Low', Icons.trending_down_rounded),
      ('newest', strings[AppLocalization.newest] ?? 'Newest', Icons.fiber_new_rounded),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: const PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: context.dividerColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            selectedItemBuilder: (context) {
              return items.map((item) {
                final selected = item.$1 == value;
                return Row(
                  children: [
                    Icon(
                      item.$3,
                      size: 18,
                      color: selected
                          ? context.primaryColor
                          : context.textSecondaryColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      item.$2,
                      style: AppTextStyles.bodySmall(
                        weight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? context.primaryColor
                            : context.textPrimaryColor,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            items: items.map((item) {
              return DropdownMenuItem(
                value: item.$1,
                child: Row(
                  children: [
                    Icon(
                      item.$3,
                      size: 18,
                      color: item.$1 == value
                          ? context.primaryColor
                          : context.textMutedColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      item.$2,
                      style: AppTextStyles.bodySmall(
                        color: item.$1 == value
                            ? context.primaryColor
                            : context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<(String, String)> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _FilterChips({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: items.map((item) {
        final (key, label) = item;
        final isSelected = selected.contains(key);
        return FilterChip(
          label: Text(
            label,
            style: AppTextStyles.labelSmall(
              color: isSelected ? AppColors.white : context.textPrimaryColor,
              weight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onToggle(key),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          selectedColor: AppColors.primary,
          checkmarkColor: AppColors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : context.dividerColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }).toList(),
    );
  }
}
