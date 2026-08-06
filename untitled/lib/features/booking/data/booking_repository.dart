import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/booking_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(DioClient.dio);
});

class BookingRepository {
  BookingRepository(this._dio);

  final Dio _dio;

  static const _cacheKeyBooking = 'booking_';
  static const _cacheKeyBookingsPrefix = 'bookings_';
  static const _cacheKeyTimeline = 'booking_timeline_';
  static const _cacheKeySitterBookings = 'sitter_bookings_';

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return (raw['data'] ?? raw) as Map<String, dynamic>;
    }
    return {};
  }

  Future<BookingModel> getBooking(String id) async {
    return BaseRepository.fetchModel(
      request: () async {
        final response = await _dio.get('/bookings/$id');
        final raw = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        return _extractData(raw);
      },
      cacheKey: '$_cacheKeyBooking$id',
      fromJson: BookingModel.fromJson,
    );
  }

  Future<PaginatedList<BookingModel>> getMyBookings({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    return getBookingsPaginated(page: page, perPage: perPage, status: status, role: 'customer');
  }

  Future<PaginatedList<BookingModel>> getSitterBookingsPaginated({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    return getBookingsPaginated(page: page, perPage: perPage, status: status, role: 'sitter');
  }

  Future<PaginatedList<BookingModel>> getBookingsPaginated({
    int page = 1,
    int perPage = 20,
    String? status,
    String? role,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (status != null) params['status'] = status;
      if (role != null) params['role'] = role;
      final response = await _dio.get('/bookings', queryParameters: params);
      final responseMap = response.data as Map<String, dynamic>? ?? {};
      final data = responseMap['data'];
      final items = data is List
          ? data.whereType<Map<String, dynamic>>().map(BookingModel.fromJson).toList()
          : <BookingModel>[];
      final pagination = PaginationInfo.fromLaravelMeta(
        responseMap['meta'] as Map<String, dynamic>? ?? {},
      );

      if (page == 1) {
        final cacheKey = '$_cacheKeyBookingsPrefix${status}_$role';
        await CacheService.set(cacheKey, {
          'items': items.map((e) => e.toJson()).toList(),
          'pagination': {
            'current_page': pagination.currentPage,
            'last_page': pagination.lastPage,
            'per_page': pagination.perPage,
            'total': pagination.total,
            'has_more': pagination.hasMore,
          },
        }, expiry: CacheService.defaultExpiry);
      }

      return PaginatedList(items: items, pagination: pagination);
    } catch (error) {
      if (page == 1) {
        final cacheKey = '$_cacheKeyBookingsPrefix${status}_$role';
        final cached = CacheService.get(cacheKey);
        if (cached is Map<String, dynamic>) {
          final items = (cached['items'] as List)
              .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
              .toList();
          final pag = cached['pagination'] as Map<String, dynamic>;
          return PaginatedList(
            items: items,
            pagination: PaginationInfo(
              currentPage: pag['current_page'] as int? ?? 1,
              lastPage: pag['last_page'] as int? ?? 1,
              perPage: pag['per_page'] as int? ?? 20,
              total: pag['total'] as int? ?? items.length,
              hasMore: pag['has_more'] as bool? ?? false,
            ),
          );
        }
      }
      throw ErrorHandler.handle(error);
    }
  }

  Future<List<BookingModel>> getSitterBookings(String sitterId, DateTime date,
      {DateTime? dateTo, bool forceRefresh = false}) async {
    if (forceRefresh) {
      final dateStr = _dateOnly(date);
      final params = <String, dynamic>{'date': dateStr};
      if (dateTo != null) {
        params['date_to'] = _dateOnly(dateTo);
      }
      final response = await _dio.get(
        '/sitters/$sitterId/bookings',
        queryParameters: params,
      );
      final data = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : response.data;
      if (data is! List) return [];
      return data.whereType<Map<String, dynamic>>().map(BookingModel.fromJson).toList();
    }
    return BaseRepository.fetchList(
      request: () async {
        final dateStr = _dateOnly(date);
        final params = <String, dynamic>{'date': dateStr};
        if (dateTo != null) {
          params['date_to'] = _dateOnly(dateTo);
        }
        final response = await _dio.get(
          '/sitters/$sitterId/bookings',
          queryParameters: params,
        );
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: '$_cacheKeySitterBookings${sitterId}_${_dateOnly(date)}',
      fromJson: BookingModel.fromJson,
      cacheDuration: CacheService.shortExpiry,
    );
  }

  Future<BookingModel> createBooking({
    required String sitterId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int duration,
    required int childrenCount,
    int specialNeedsCount = 0,
    List<String> childrenNames = const [],
    List<String> childrenAges = const [],
    String? notes,
    String? address,
    String? specialInstructions,
    List<Map<String, String>>? scheduleEvents,
  }) async {
    try {
      final response = await _dio.post('/bookings', data: {
        'sitter_id': sitterId,
        'date': _dateOnly(date),
        'start_time': startTime,
        'end_time': endTime,
        'duration': duration,
        'children_count': childrenCount,
        'special_needs_count': specialNeedsCount,
        if (childrenNames.isNotEmpty) 'children_names': childrenNames,
        if (childrenAges.isNotEmpty) 'children_ages': childrenAges,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (address != null && address.isNotEmpty) 'address': address,
        if (specialInstructions != null && specialInstructions.isNotEmpty)
          'special_instructions': specialInstructions,
        if (scheduleEvents != null && scheduleEvents.isNotEmpty)
          'schedule_events': scheduleEvents,
      });
      final data = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : response.data;
      return BookingModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<List<BookingModel>> createBookingGroup({
    required String sitterId,
    required List<String> dates,
    required String startTime,
    required String endTime,
    required int duration,
    required int childrenCount,
    int specialNeedsCount = 0,
    List<String> childrenNames = const [],
    List<String> childrenAges = const [],
    String? notes,
    String? address,
    String? specialInstructions,
    List<Map<String, String>>? scheduleEvents,
    Map<String, Map<String, String>>? perDateTimes,
  }) async {
    try {
      final response = await _dio.post('/bookings', data: {
        'sitter_id': sitterId,
        'dates': dates,
        'start_time': startTime,
        'end_time': endTime,
        'duration': duration,
        'children_count': childrenCount,
        'special_needs_count': specialNeedsCount,
        if (childrenNames.isNotEmpty) 'children_names': childrenNames,
        if (childrenAges.isNotEmpty) 'children_ages': childrenAges,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (address != null && address.isNotEmpty) 'address': address,
        if (specialInstructions != null && specialInstructions.isNotEmpty)
          'special_instructions': specialInstructions,
        if (scheduleEvents != null && scheduleEvents.isNotEmpty)
          'schedule_events': scheduleEvents,
        if (perDateTimes != null && perDateTimes.isNotEmpty)
          'per_date_times': perDateTimes,
      });
      final responseMap = response.data as Map<String, dynamic>? ?? {};
      final data = responseMap['data'];
      if (data is Map<String, dynamic>) {
        final bookings = data['bookings'];
        if (bookings is List) {
          return bookings
              .whereType<Map<String, dynamic>>()
              .map(BookingModel.fromJson)
              .toList();
        }
      }
      throw AppException(message: 'Unexpected response format for group booking.');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<Map<String, dynamic>> getBookingGroup(String bookingGroupId) async {
    try {
      final response = await _dio.get('/booking-groups/$bookingGroupId');
      final raw = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : <String, dynamic>{};
      return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<List<BookingModel>> cancelBookingGroup(
    String bookingGroupId, {
    List<int>? dateIds,
    String? reason,
  }) async {
    try {
      final data = <String, dynamic>{
        'booking_group_id': bookingGroupId,
      };
      if (dateIds != null && dateIds.isNotEmpty) {
        data['date_ids'] = dateIds;
      }
      if (reason != null && reason.isNotEmpty) {
        data['reason'] = reason;
      }
      final response = await _dio.post('/booking-groups/cancel', data: data);
      final responseMap = response.data as Map<String, dynamic>? ?? {};
      final rawData = responseMap['data'];
      if (rawData is List) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map(BookingModel.fromJson)
            .toList();
      }
      // Support single booking response wrapped in booking group
      if (rawData is Map<String, dynamic> && rawData.containsKey('bookings')) {
        final bookings = rawData['bookings'];
        if (bookings is List) {
          return bookings
              .whereType<Map<String, dynamic>>()
              .map(BookingModel.fromJson)
              .toList();
        }
      }
      throw AppException(message: 'Unexpected response format.');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> updateBooking(String bookingId, {DateTime? date, String? startTime, String? endTime, int? duration, int? childrenCount, int? specialNeedsCount, List<String>? childrenNames, List<String>? childrenAges, String? notes, String? address, String? specialInstructions, List<Map<String, String>>? scheduleEvents}) async {
    try {
      final data = <String, dynamic>{};
      if (date != null) data['date'] = _dateOnly(date);
      if (startTime != null) data['start_time'] = startTime;
      if (endTime != null) data['end_time'] = endTime;
      if (duration != null) data['duration'] = duration;
      if (childrenCount != null) data['children_count'] = childrenCount;
      if (specialNeedsCount != null) data['special_needs_count'] = specialNeedsCount;
      if (childrenNames != null) data['children_names'] = childrenNames;
      if (childrenAges != null) data['children_ages'] = childrenAges;
      if (notes != null) data['notes'] = notes;
      if (address != null) data['address'] = address;
      if (specialInstructions != null) data['special_instructions'] = specialInstructions;
      if (scheduleEvents != null) data['schedule_events'] = scheduleEvents;

      final response = await _dio.put('/bookings/$bookingId', data: data);
      final result = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : response.data;
      return BookingModel.fromJson(result as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final response = await _dio.put(
        '/bookings/$bookingId/cancel',
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = _extractData(raw);
      final booking = BookingModel.fromJson(data);
      await CacheService.set('$_cacheKeyBooking$bookingId', data);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> sitterCancelBooking(String bookingId, {required String reason}) async {
    try {
      final response = await _dio.put(
        '/bookings/$bookingId/sitter-cancel',
        data: {'reason': reason},
      );
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = _extractData(raw);
      final booking = BookingModel.fromJson(data);
      await CacheService.set('$_cacheKeyBooking$bookingId', data);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<List<TimelineEvent>> getTimeline(String bookingId) async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/bookings/$bookingId/timeline');
        final raw = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (raw is! List) return [];
        return raw.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: '$_cacheKeyTimeline$bookingId',
      fromJson: TimelineEvent.fromJson,
      cacheDuration: CacheService.shortExpiry,
    );
  }

  Future<BookingModel> startBooking(String bookingId) async {
    try {
      final response = await _dio.put('/bookings/$bookingId/start');
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = _extractData(raw);
      final booking = BookingModel.fromJson(data);
      await CacheService.set('$_cacheKeyBooking$bookingId', data);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> confirmBooking(String bookingId) async {
    try {
      final response = await _dio.put('/bookings/$bookingId/confirm');
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = _extractData(raw);
      final booking = BookingModel.fromJson(data);
      await CacheService.set('$_cacheKeyBooking$bookingId', data);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> rejectBooking(String bookingId, {String? reason}) async {
    try {
      final response = await _dio.put(
        '/bookings/$bookingId/reject',
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = _extractData(raw);
      final booking = BookingModel.fromJson(data);
      await CacheService.set('$_cacheKeyBooking$bookingId', data);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> completeBooking(String bookingId) async {
    try {
      final response = await _dio.put('/bookings/$bookingId/complete');
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = _extractData(raw);
      final booking = BookingModel.fromJson(data);
      await CacheService.set('$_cacheKeyBooking$bookingId', data);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> submitReview(String bookingId, {required double rating, String? review}) async {
    try {
      final response = await _dio.post('/bookings/$bookingId/review', data: {
        'rating': rating,
        if (review != null && review.isNotEmpty) 'review': review,
      });
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = _extractData(raw);
      final booking = BookingModel.fromJson(data);
      await CacheService.set('$_cacheKeyBooking$bookingId', data);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> submitGroupReview(String bookingGroupId, {required double rating, String? review}) async {
    try {
      await _dio.post('/booking-groups/$bookingGroupId/review', data: {
        'rating': rating,
        if (review != null && review.isNotEmpty) 'review': review,
      });
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<BookingModel> rebookBooking(String bookingId, {required DateTime date, required String startTime, required String endTime, required int duration, int? childrenCount, int? specialNeedsCount, List<String>? childrenNames, List<String>? childrenAges, String? notes, String? address, String? specialInstructions, List<Map<String, String>>? scheduleEvents}) async {
    try {
      final data = <String, dynamic>{
        'date': _dateOnly(date),
        'start_time': startTime,
        'end_time': endTime,
        'duration': duration,
      };
      if (childrenCount != null) data['children_count'] = childrenCount;
      if (specialNeedsCount != null) data['special_needs_count'] = specialNeedsCount;
      if (childrenNames != null && childrenNames.isNotEmpty) data['children_names'] = childrenNames;
      if (childrenAges != null && childrenAges.isNotEmpty) data['children_ages'] = childrenAges;
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;
      if (address != null && address.isNotEmpty) data['address'] = address;
      if (specialInstructions != null && specialInstructions.isNotEmpty) data['special_instructions'] = specialInstructions;
      if (scheduleEvents != null && scheduleEvents.isNotEmpty) data['schedule_events'] = scheduleEvents;
      final response = await _dio.post('/bookings/$bookingId/rebook', data: data);
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final extracted = _extractData(raw);
      final booking = BookingModel.fromJson(extracted);
      await CacheService.set('$_cacheKeyBooking$bookingId', extracted);
      return booking;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class PaginatedList<T> {
  final List<T> items;
  final PaginationInfo pagination;

  const PaginatedList({required this.items, required this.pagination});
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  const PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  factory PaginationInfo.fromLaravelMeta(Map<String, dynamic> meta) {
    return PaginationInfo(
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? 20,
      total: meta['total'] as int? ?? 0,
      hasMore: meta['has_more'] as bool? ?? (meta['current_page'] as int? ?? 1) < (meta['last_page'] as int? ?? 1),
    );
  }
}
