import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around [Dio] so the base URL / timeouts / interceptors are
/// configured in exactly one place.
///
/// Ticketmaster's Discovery API is the base URL here. If EventSpot grows a
/// second remote source (e.g. its own backend for auth/favorites), give
/// that source its own [ApiClient] instance rather than overloading this one.
class ApiClient {
  ApiClient() : dio = Dio(
          BaseOptions(
            baseUrl: 'https://app.ticketmaster.com/discovery/v2/',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, error: true),
      );
    }
  }

  final Dio dio;
}
