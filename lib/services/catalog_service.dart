// (empty)

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/theme.dart';
import '../models/stats.dart';
import '../models/question.dart';
import 'auth_service.dart';
import '../db/local_db.dart';

class CatalogService {
    /// Report a question error (flag for verification)
    Future<void> reportQuestionError(int questionId) async {
      final url = '$baseUrl/questions/flag/';
      final headers = await authService.getAuthHeaders();
      final body = jsonEncode({'question_id': questionId});
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to report question error: ${response.statusCode}');
      }
    }
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService authService;

  CatalogService({required this.authService});

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
        final List<dynamic> data = jsonDecode(response.body);
        final categories = data.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
        // Cache to local DB
        await LocalDb.insertCategories(categories);
        return categories;
      } else {
        // On error, try local cache
        final cached = await LocalDb.getCategories();
        if (cached.isNotEmpty) return cached;
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      // On error, try local cache
      final cached = await LocalDb.getCategories();
      if (cached.isNotEmpty) return cached;
      throw Exception('Error: ${e.toString()}');
    }
  }


  /// Fetch themes for a specific category with local caching
  Future<List<Theme>> getThemesByCategory(int categoryId) async {
    try {
      final response = await _authorizedGet('$baseUrl${ApiConfig.themesEndpoint}?category=$categoryId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final themes = data.map((item) => Theme.fromJson(item as Map<String, dynamic>)).toList();
        // Cache to local DB
        await LocalDb.insertThemes(themes);
        return themes;
      } else {
        // On error, try local cache
        final cached = await LocalDb.getThemesByCategory(categoryId);
        if (cached.isNotEmpty) return cached;
        throw Exception('Failed to load themes: ${response.statusCode}');
      }
    } catch (e) {
      // On error, try local cache
      final cached = await LocalDb.getThemesByCategory(categoryId);
      if (cached.isNotEmpty) return cached;
      throw Exception('Error: ${e.toString()}');
    }
  }
  /// Fetch questions for a theme with local caching
  Future<List<Question>> getQuestionsByTheme(int themeId) async {
    try {
      final response = await _authorizedGet('$baseUrl${ApiConfig.questionsEndpoint}?theme=$themeId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final questions = data.map((item) => Question.fromJson(item as Map<String, dynamic>)).toList();
        // Cache to local DB
        await LocalDb.insertQuestions(questions);
        return questions;
      } else {
        // On error, try local cache
        final cached = await LocalDb.getQuestionsByTheme(themeId);
        if (cached.isNotEmpty) return cached;
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      // On error, try local cache
      final cached = await LocalDb.getQuestionsByTheme(themeId);
      if (cached.isNotEmpty) return cached;
      throw Exception('Error: ${e.toString()}');
    }
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
        final List<dynamic> data = jsonDecode(response.body);
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
      final response = await http
          .get(Uri.parse('$baseUrl${ApiConfig.statisticsEndpoint}'), headers: ApiConfig.defaultHeaders)
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
