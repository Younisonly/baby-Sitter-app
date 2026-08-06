import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/sitter_registration/data/sitter_registration_repository.dart';
import 'package:babysitter/shared/models/user_model.dart';

class SitterRegistrationState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final int currentStep;
  final List<int> completedSteps;
  final RegistrationStatus registrationStatus;
  final UserModel? user;

  final int? age;
  final String? gender;
  final List<String>? languages;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int yearsExperience;
  final List<String> categories;

  final List<dynamic> certificates;
  final String? description;

  final double hourlyRate;
  final int includedChildren;
  final double extraChildFee;
  final int? absoluteMaxChildren;
  final double specialNeedsRate;

  final List<AvailabilitySlot> availability;

  final Map<String, dynamic>? bankAccount;

  final bool isDraftInitialized;
  final String? submitError;

  const SitterRegistrationState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.currentStep = 1,
    this.completedSteps = const [],
    this.registrationStatus = RegistrationStatus.none,
    this.user,
    this.age,
    this.gender,
    this.languages,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
    this.yearsExperience = 0,
    this.categories = const [],
    this.certificates = const [],
    this.description,
    this.hourlyRate = 0.0,
    this.includedChildren = 1,
    this.extraChildFee = 0.0,
    this.absoluteMaxChildren,
    this.specialNeedsRate = 0.0,
    this.availability = const [],
    this.bankAccount,
    this.isDraftInitialized = false,
    this.submitError,
  });

  SitterRegistrationState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    int? currentStep,
    List<int>? completedSteps,
    RegistrationStatus? registrationStatus,
    UserModel? user,
    int? age,
    String? gender,
    List<String>? languages,
    String? bio,
    String? location,
    double? latitude,
    double? longitude,
    int? yearsExperience,
    List<String>? categories,
    List<dynamic>? certificates,
    String? description,
    double? hourlyRate,
    int? includedChildren,
    double? extraChildFee,
    int? absoluteMaxChildren,
    double? specialNeedsRate,
    List<AvailabilitySlot>? availability,
    Map<String, dynamic>? bankAccount,
    bool? isDraftInitialized,
    String? submitError,
    bool clearError = false,
    bool clearSubmitError = false,
    bool clearAge = false,
    bool clearGender = false,
    bool clearLanguages = false,
    bool clearBio = false,
    bool clearLocation = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
    bool clearDescription = false,
    bool clearAbsoluteMaxChildren = false,
    bool clearBankAccount = false,
  }) {
    return SitterRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      user: user ?? this.user,
      age: clearAge ? null : (age ?? this.age),
      gender: clearGender ? null : (gender ?? this.gender),
      languages: clearLanguages ? null : (languages ?? this.languages),
      bio: clearBio ? null : (bio ?? this.bio),
      location: clearLocation ? null : (location ?? this.location),
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      yearsExperience: yearsExperience ?? this.yearsExperience,
      categories: categories ?? this.categories,
      certificates: certificates ?? this.certificates,
      description: clearDescription ? null : (description ?? this.description),
      hourlyRate: hourlyRate ?? this.hourlyRate,
      includedChildren: includedChildren ?? this.includedChildren,
      extraChildFee: extraChildFee ?? this.extraChildFee,
      absoluteMaxChildren: clearAbsoluteMaxChildren ? null : (absoluteMaxChildren ?? this.absoluteMaxChildren),
      specialNeedsRate: specialNeedsRate ?? this.specialNeedsRate,
      availability: availability ?? this.availability,
      bankAccount: clearBankAccount ? null : (bankAccount ?? this.bankAccount),
      isDraftInitialized: isDraftInitialized ?? this.isDraftInitialized,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

final sitterRegistrationProvider =
    StateNotifierProvider<SitterRegistrationNotifier, SitterRegistrationState>((ref) {
  return SitterRegistrationNotifier(ref);
});

class SitterRegistrationNotifier extends StateNotifier<SitterRegistrationState> {
  SitterRegistrationNotifier(this._ref)
      : super(const SitterRegistrationState());

  final Ref _ref;
  late final SitterRegistrationRepository _repo =
      _ref.read(sitterRegistrationRepositoryProvider);

  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      final result = await _repo.getStatus();
      final data = result['data'] as Map<String, dynamic>;
      final statusStr = data['registrationStatus'] as String? ?? 'none';
      final status = RegistrationStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => RegistrationStatus.none,
      );

      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      final completed = (data['completedSteps'] as List?)?.cast<int>() ?? [];
      final isDraft = status == RegistrationStatus.draft;

      final newState = state.copyWith(
        isLoading: false,
        registrationStatus: status,
        user: user,
        completedSteps: completed,
        currentStep: 1,
        isDraftInitialized: isDraft,
      );
      _populateFromUser(user, newState);
      state = newState;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<bool> startDraft() async {
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      final result = await _repo.startDraft();
      final data = result['data'] as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      final newState = state.copyWith(
        isLoading: false,
        isDraftInitialized: true,
        registrationStatus: RegistrationStatus.draft,
        user: user,
        currentStep: 1,
        completedSteps: [],
      );
      _populateFromUser(user, newState);
      state = newState;
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
      return false;
    }
  }

  Future<bool> discardDraft() async {
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      await _repo.discardDraft();
      state = const SitterRegistrationState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
      return false;
    }
  }

  Future<bool> saveCurrentStep() async {
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      final data = _buildStepData(state.currentStep);
      final result = await _repo.saveStep(state.currentStep, data);
      final responseData = result['data'] as Map<String, dynamic>;
      final completed = (responseData['completedSteps'] as List?)?.cast<int>() ?? [];
      final nextStep = responseData['currentStep'] as int? ?? state.currentStep + 1;

      final userData = responseData['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      final newState = state.copyWith(
        isLoading: false,
        user: user,
        completedSteps: completed,
        currentStep: nextStep,
      );
      _populateFromUser(user, newState);
      state = newState;
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
      return false;
    }
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, submitError: null, clearSubmitError: true);
    try {
      await _repo.submit();
      state = state.copyWith(
        isSubmitting: false,
        registrationStatus: RegistrationStatus.submitted,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: ErrorHandler.handle(e).message,
      );
      return false;
    }
  }

  void setStep(int step) {
    if (step >= 1 && step <= 5) {
      state = state.copyWith(currentStep: step, error: null, clearError: true);
    }
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1, error: null, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1, error: null, clearError: true);
    }
  }

  void _populateFromUser(UserModel user, SitterRegistrationState currentState) {
    final profile = user.babysitterProfile;
    final rawCerts = profile?.certificates ?? [];
    final parsedCerts = rawCerts.map((e) {
      if (e is Map) return e;
      return {'name': e.toString(), 'notes': ''};
    }).toList();

    final rawBank = profile?.bankAccount;
    Map<String, dynamic>? parsedBank;
    if (rawBank != null && rawBank.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBank);
        if (decoded is Map) {
          parsedBank = decoded.cast<String, dynamic>();
        } else {
          parsedBank = {'iban': rawBank};
        }
      } catch (_) {
        parsedBank = {'iban': rawBank};
      }
    }

    final rawAvail = profile?.availability ?? [];
    final parsedAvail = rawAvail.isNotEmpty
        ? rawAvail
        : _availabilityFromOldFormat(state.availability);

    state = currentState.copyWith(
      age: user.age,
      gender: user.gender,
      languages: user.languages,
      bio: user.bio,
      location: user.location,
      latitude: user.latitude,
      longitude: user.longitude,
      yearsExperience: profile?.yearsExperience ?? 0,
      categories: profile?.categories ?? [],
      certificates: parsedCerts,
      description: profile?.description,
      hourlyRate: profile?.hourlyRate ?? 0,
      includedChildren: profile?.includedChildren ?? 1,
      extraChildFee: profile?.extraChildFee ?? 0,
      absoluteMaxChildren: profile?.absoluteMaxChildren,
      specialNeedsRate: profile?.specialNeedsRate ?? 0,
      availability: parsedAvail,
      bankAccount: parsedBank,
    );
  }

  List<AvailabilitySlot> _availabilityFromOldFormat(List<AvailabilitySlot> current) {
    return current;
  }

  Map<String, dynamic> _buildStepData(int step) {
    switch (step) {
      case 1:
        return {
          'age': state.age,
          'gender': state.gender,
          'languages': state.languages,
          'bio': state.bio,
          'location': state.location,
          'latitude': state.latitude,
          'longitude': state.longitude,
          'years_experience': state.yearsExperience,
          'categories': state.categories,
        };
      case 2:
        final certs = state.certificates.map((c) {
          if (c is Map) {
            return {
              'name': (c['name'] as String? ?? '').toString(),
              'notes': (c['notes'] as String? ?? '').toString(),
            };
          }
          return {'name': c.toString(), 'notes': ''};
        }).toList();
        return {
          'certificates': certs.where((c) => (c['name'] as String).isNotEmpty).toList(),
          'description': state.description,
        };
      case 3:
        return {
          'hourly_rate': state.hourlyRate,
          'included_children': state.includedChildren,
          'extra_child_fee': state.extraChildFee,
          'absolute_max_children': state.absoluteMaxChildren,
          'special_needs_rate': state.specialNeedsRate,
        };
      case 4:
        return {
          'availability': state.availability
              .map((s) => {
                    'day_of_week': s.dayOfWeek,
                    'day': _dayName(s.dayOfWeek),
                    'start_time': s.startTime,
                    'end_time': s.endTime,
                  })
              .toList(),
        };
      case 5:
        return {
          'bank_account': state.bankAccount,
        };
      default:
        return {};
    }
  }

  String _dayName(int dayOfWeek) {
    const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    if (dayOfWeek >= 0 && dayOfWeek < 7) return names[dayOfWeek];
    return 'Monday';
  }

  int _dayIndex(String dayName) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final lower = dayName.toLowerCase();
    for (int i = 0; i < names.length; i++) {
      if (names[i].toLowerCase() == lower) return i;
    }
    return 0;
  }

  void updateStepFromData(int step, Map<String, dynamic> data) {
    switch (step) {
      case 1:
        state = state.copyWith(
          age: data['age'] as int?,
          gender: data['gender'] as String?,
          languages: data['languages'] as List<String>?,
          bio: data['bio'] as String?,
          location: data['location'] as String?,
          yearsExperience: data['years_experience'] as int? ?? state.yearsExperience,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
        );
        break;
      case 2:
        state = state.copyWith(
          certificates: data['certificates'] as List<dynamic>? ?? [],
          description: data['description'] as String?,
        );
        break;
      case 3:
        state = state.copyWith(
          hourlyRate: (data['hourly_rate'] as num?)?.toDouble() ?? state.hourlyRate,
          includedChildren: data['included_children'] as int? ?? state.includedChildren,
          extraChildFee: (data['extra_child_fee'] as num?)?.toDouble() ?? state.extraChildFee,
          specialNeedsRate: (data['special_needs_rate'] as num?)?.toDouble() ?? state.specialNeedsRate,
          absoluteMaxChildren: data['absolute_max_children'] as int?,
          clearAbsoluteMaxChildren: data['absolute_max_children'] == null,
        );
        break;
      case 4: {
        final raw = data['availability'] as List? ?? [];
        final slots = raw.map((d) {
          if (d is AvailabilitySlot) return d;
          final map = d as Map<String, dynamic>;
          final dayStr = map['day'] as String?;
          final dayOfWeek = map['day_of_week'] as int? ?? (dayStr != null ? _dayIndex(dayStr) : 0);
          return AvailabilitySlot(
            dayOfWeek: dayOfWeek,
            startTime: map['start_time'] as String? ?? '09:00',
            endTime: map['end_time'] as String? ?? '17:00',
          );
        }).toList();
        state = state.copyWith(availability: slots);
        break;
      }
      case 5: {
        final bank = data['bank_account'];
        state = state.copyWith(
          bankAccount: bank is Map<String, dynamic> ? bank : null,
          clearBankAccount: bank == null,
        );
        break;
      }
    }
  }

  bool isStepComplete(int step) {
    return state.completedSteps.contains(step);
  }
}
