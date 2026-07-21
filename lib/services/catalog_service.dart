// (empty)

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/theme.dart';
import '../models/stats.dart';
import '../models/question.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import '../db/local_db.dart';

class CatalogService {
    /// Report a question error (flag for verification)
    Future<void> reportQuestionError(int questionId) async {
      final url = '$baseUrl/questions/flag/';
        final requestUri = Uri.parse(url);
      final body = jsonEncode({'question_id': questionId});
        http.Response response;

        Future<http.Response> sendReportRequest(Map<String, String> headers) {
          return http.post(
            requestUri,
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: body,
          ).timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () => throw Exception('Connection timeout'),
          );
        }

        final headers = await authService.getAuthHeaders();
        response = await sendReportRequest(headers);

        if (response.statusCode == 401) {
          final refreshed = await authService.refreshAccessToken();
          if (refreshed) {
            final retryHeaders = await authService.getAuthHeaders();
            response = await sendReportRequest(retryHeaders);
          }
        }

      if (response.statusCode == 200) {
        return;
      }

      if (response.statusCode == 400 && _isAlreadyFlaggedResponse(response.body)) {
        // Keep the action idempotent from the user perspective.
        return;
      }

      final errorDetail = _extractApiErrorMessage(response.body);
      if (errorDetail != null) {
        throw Exception(
          'Failed to report question error: ${response.statusCode} ($errorDetail)',
        );
      }

      throw Exception('Failed to report question error: ${response.statusCode}');
    }

  bool _isAlreadyFlaggedResponse(String responseBody) {
    final message = _extractApiErrorMessage(responseBody)?.toLowerCase();
    if (message == null) {
      return false;
    }

    return message.contains('already flagged') ||
        message.contains('already reported');
  }

  String? _extractApiErrorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }

        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Ignore parsing errors and fallback to generic error handling.
    }

    return null;
  }
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService authService;

  CatalogService({required this.authService});

  /// Support both legacy list responses and DRF paginated responses.
  List<dynamic> _decodeListPayload(String responseBody) {
    final decoded = jsonDecode(responseBody);

    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];
      if (results is List) {
        return results;
      }
    }

    throw const FormatException('Unexpected API payload format');
  }

  /// Return all items from a paginated or non-paginated endpoint.
  Future<List<dynamic>> _fetchAllPages(String initialUrl) async {
    final items = <dynamic>[];
    String? nextUrl = initialUrl;

    while (nextUrl != null && nextUrl.isNotEmpty) {
      final response = await _authorizedGet(nextUrl);

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to load paginated data: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        items.addAll(decoded);
        break;
      }

      if (decoded is Map<String, dynamic>) {
        final results = decoded['results'];
        if (results is List) {
          items.addAll(results);
        }

        final next = decoded['next'];
        if (next is String && next.trim().isNotEmpty) {
          final parsed = Uri.parse(next);
          nextUrl = parsed.hasScheme ? next : Uri.parse(baseUrl).resolve(next).toString();
        } else {
          nextUrl = null;
        }
        continue;
      }

      throw const FormatException('Unexpected paginated payload format');
    }

    return items;
  }

  /// Helper to perform authorized GET with one retry after token refresh on 401
  Future<http.Response> _authorizedGet(String url) async {
    final headers = await authService.getAuthHeaders();
    http.Response response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(
          ApiConfig.connectionTimeout,
          onTimeout: () => throw Exception('Connection timeout'),
        );

    if (response.statusCode == 401) {
      final refreshed = await authService.refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await authService.getAuthHeaders();
        response = await http
            .get(Uri.parse(url), headers: retryHeaders)
            .timeout(
              ApiConfig.connectionTimeout,
              onTimeout: () => throw Exception('Connection timeout'),
            );
      }
    }

    return response;
  }


  /// Fetch all categories with local caching
  Future<List<Category>> getCategories() async {
    try {
      final response = await _authorizedGet('$baseUrl${ApiConfig.categoriesEndpoint}');
      if (response.statusCode == 200) {
        final List<dynamic> data = _decodeListPayload(response.body);
        final categories = data.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
        // Cache to local DB
        await LocalDb.insertCategories(categories);
        return categories;
      }
      throw ApiException(
        'Failed to load categories: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      // On error, try local cache
      final cached = await LocalDb.getCategories();
      if (cached.isNotEmpty) return cached;
      if (e is ApiException) rethrow;
      throw ApiException('Error: ${e.toString()}');
    }
  }


  /// Fetch themes for a specific category with local caching
  Future<List<Theme>> getThemesByCategory(int categoryId) async {
    try {
      final response = await _authorizedGet('$baseUrl${ApiConfig.themesEndpoint}?category=$categoryId');
      if (response.statusCode == 200) {
        final List<dynamic> data = _decodeListPayload(response.body);
        final themes = data.map((item) => Theme.fromJson(item as Map<String, dynamic>)).toList();
        // Cache to local DB
        await LocalDb.insertThemes(themes);
        return themes;
      }
      throw ApiException(
        'Failed to load themes: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      // On error, try local cache
      final cached = await LocalDb.getThemesByCategory(categoryId);
      if (cached.isNotEmpty) return cached;
      if (e is ApiException) rethrow;
      throw ApiException('Error: ${e.toString()}');
    }
  }

  /// Fetch themes for several categories in a single request (backend
  /// `category__in` filter) instead of one request per category. Used by
  /// the filtering screens, so selecting many categories doesn't fire a
  /// burst of sequential requests into the rate limiter.
  Future<List<Theme>> getThemesByCategories(List<int> categoryIds) async {
    if (categoryIds.isEmpty) return [];
    try {
      final data = await _fetchAllPages(
        '$baseUrl${ApiConfig.themesEndpoint}?category__in=${categoryIds.join(',')}',
      );
      final themes = data.map((item) => Theme.fromJson(item as Map<String, dynamic>)).toList();
      await LocalDb.insertThemes(themes);
      return themes;
    } catch (e) {
      // On error, try local cache for every requested category
      final cached = <Theme>[];
      for (final categoryId in categoryIds) {
        cached.addAll(await LocalDb.getThemesByCategory(categoryId));
      }
      if (cached.isNotEmpty) return cached;
      if (e is ApiException) rethrow;
      throw ApiException('Error: ${e.toString()}');
    }
  }

  /// Fetch questions for a theme with local caching
  Future<List<Question>> getQuestionsByTheme(int themeId) async {
    try {
      final data = await _fetchAllPages(
        '$baseUrl${ApiConfig.questionsEndpoint}?theme=$themeId',
      );
      final questions = data
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList();
      // Cache to local DB
      await LocalDb.insertQuestions(questions);
      return questions;
    } catch (e) {
      // On error, try local cache
      final cached = await LocalDb.getQuestionsByTheme(themeId);
      if (cached.isNotEmpty) return cached;
      if (e is ApiException) rethrow;
      throw ApiException('Error: ${e.toString()}');
    }
  }

  /// Fetch questions for several themes in a single request (backend
  /// `theme__in` filter) instead of one request per theme. Used when
  /// launching a quiz across multiple themes, so selecting many themes
  /// doesn't fire a burst of sequential requests into the rate limiter.
  Future<List<Question>> getQuestionsByThemes(List<int> themeIds) async {
    if (themeIds.isEmpty) return [];
    try {
      final data = await _fetchAllPages(
        '$baseUrl${ApiConfig.questionsEndpoint}?theme__in=${themeIds.join(',')}',
      );
      final questions = data
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList();
      await LocalDb.insertQuestions(questions);
      return questions;
    } catch (e) {
      // On error, try local cache for every requested theme
      final cached = <Question>[];
      for (final themeId in themeIds) {
        cached.addAll(await LocalDb.getQuestionsByTheme(themeId));
      }
      if (cached.isNotEmpty) return cached;
      if (e is ApiException) rethrow;
      throw ApiException('Error: ${e.toString()}');
    }
  }

  /// Download and cache a theme's questions only if the local cache doesn't
  /// already hold the expected number of questions. Used by the proactive
  /// offline sync so re-running it doesn't re-download already-cached themes.
  Future<void> syncQuestionsIfNeeded(int themeId, int expectedCount) async {
    if (expectedCount <= 0) return;
    final cachedCount = await LocalDb.getQuestionCountForTheme(themeId);
    if (cachedCount >= expectedCount) return;
    await getQuestionsByTheme(themeId);
  }

  /// Fetch all themes (with optional free/paid filter)
  Future<List<Theme>> getAllThemes({bool? isFree}) async {
    try {
      String url = '$baseUrl${ApiConfig.themesEndpoint}';
      if (isFree != null) {
        url += '?is_free=$isFree';
      }

      final response = await _authorizedGet(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = _decodeListPayload(response.body);
        return data.map((item) => Theme.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load themes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Fetch catalog statistics (totals)
  Future<CatalogStats> getStatistics() async {
    try {
      final response = await _authorizedGet('$baseUrl${ApiConfig.statisticsEndpoint}')
          .timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () => throw Exception('Connection timeout'),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return CatalogStats.fromJson(data);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }
}
