import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/event_filters.dart';
import '../models/events_page_model.dart';

abstract class EventsRemoteDataSource {
  Future<EventsPageModel> fetchEvents({
    required double latitude,
    required double longitude,
    required EventFilters filters,
    required int page,
    required int pageSize,
  });
}

class EventsRemoteDataSourceImpl implements EventsRemoteDataSource {
  EventsRemoteDataSourceImpl({required this.dio, required this.apiKey});

  final Dio dio;
  final String apiKey;

  @override
  Future<EventsPageModel> fetchEvents({
    required double latitude,
    required double longitude,
    required EventFilters filters,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        'events.json',
        queryParameters: {
          'apikey': apiKey,
          'latlong': '$latitude,$longitude',
          'radius': filters.radiusKm.round().toString(),
          'unit': 'km',
          'size': pageSize.toString(),
          'page': page.toString(),
          'sort': 'date,asc',
          if (filters.category != null)
            'classificationName': filters.category!.ticketmasterName,
          if (filters.keyword != null && filters.keyword!.trim().isNotEmpty)
            'keyword': filters.keyword!.trim(),
          if (filters.startDate != null) 'startDateTime': _toApiDateTime(filters.startDate!),
          if (filters.endDate != null) 'endDateTime': _toApiDateTime(filters.endDate!),
        },
      );

      final data = response.data;
      if (data == null) {
        throw ServerException('Пустой ответ от Ticketmaster API');
      }
      return EventsPageModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return NetworkException();
      default:
        final status = e.response?.statusCode;
        final statusSuffix = status != null ? ' ($status)' : '';
        return ServerException(
          _extractApiMessage(e.response?.data) ??
              'Ticketmaster API вернул ошибку$statusSuffix',
        );
    }
  }

  /// Ticketmaster wraps errors as `{"fault": {"faultstring": "..."}}`.
  String? _extractApiMessage(Object? data) {
    if (data is! Map) return null;
    final fault = data['fault'];
    if (fault is! Map) return null;
    return fault['faultstring']?.toString();
  }

  /// Ticketmaster expects `yyyy-MM-ddTHH:mm:ssZ` (no fractional seconds).
  String _toApiDateTime(DateTime dateTime) {
    return '${dateTime.toUtc().toIso8601String().split('.').first}Z';
  }
}
