import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/theme.dart' as theme_model;
import '../models/stats.dart';
import '../models/question.dart';
import '../services/api_exception.dart';
import '../services/catalog_service.dart';
import '../services/auth_service.dart';

class CatalogProvider extends ChangeNotifier {
    Future<void> reportQuestionError(int questionId) async {
      await _catalogService.reportQuestionError(questionId);
    }
  final CatalogService _catalogService;
  final Map<int, List<Question>> _questionsByTheme = {};
  final Map<int, Future<List<Question>>> _questionRequests = {};

  List<Category> _categories = [];
  List<theme_model.Theme> _themes = [];
  Category? _selectedCategory;
  theme_model.Theme? _selectedTheme;
  bool _isLoading = false;
  bool _isStatsLoading = false;
  String? _error;
  int? _errorStatusCode;
  String? _statsError;
  CatalogStats? _stats;
  bool _isSyncingOffline = false;

  CatalogProvider({required AuthService authService})
    : _catalogService = CatalogService(authService: authService);

  // Getters
  List<Category> get categories => _categories;
  List<theme_model.Theme> get themes => _themes;
  Category? get selectedCategory => _selectedCategory;
  theme_model.Theme? get selectedTheme => _selectedTheme;
  bool get isLoading => _isLoading;
  bool get isStatsLoading => _isStatsLoading;
  String? get error => _error;
  int? get errorStatusCode => _errorStatusCode;
  bool get isRateLimited => _errorStatusCode == 429;
  String? get statsError => _statsError;
  CatalogStats? get stats => _stats;
  bool get isSyncingOffline => _isSyncingOffline;

  /// Load all categories
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    _errorStatusCode = null;
    notifyListeners();

    try {
      _categories = await _catalogService.getCategories();
      _error = null;
      _errorStatusCode = null;
    } catch (e) {
      _error = e.toString();
      _errorStatusCode = e is ApiException ? e.statusCode : null;
      _categories = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load themes for selected category
  Future<void> loadThemesByCategory(int categoryId) async {
    _isLoading = true;
    _error = null;
    _errorStatusCode = null;
    notifyListeners();

    try {
      final allThemes = await _catalogService.getThemesByCategory(categoryId);
      _themes = allThemes.where((t) => t.isActive).toList();
      _error = null;
      _errorStatusCode = null;
    } catch (e) {
      _error = e.toString();
      _errorStatusCode = e is ApiException ? e.statusCode : null;
      _themes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load themes for multiple categories in a single batched request.
  ///
  /// Network-first, falling back to the local cache for every requested
  /// category if the request fails — e.g. offline and never synced — so a
  /// connectivity blip doesn't discard themes already available locally.
  Future<void> loadThemesByCategories(List<int> categoryIds) async {
    _isLoading = true;
    _error = null;
    _errorStatusCode = null;
    notifyListeners();

    try {
      final items = await _catalogService.getThemesByCategories(categoryIds);
      _themes = items.where((t) => t.isActive).toList();
      _error = null;
      _errorStatusCode = null;
    } catch (e) {
      _error = e.toString();
      _errorStatusCode = e is ApiException ? e.statusCode : null;
      _themes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Select a category
  void selectCategory(Category category) {
    _selectedCategory = category;
    _selectedTheme = null;
    notifyListeners();
  }

  /// Select a theme
  void selectTheme(theme_model.Theme theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedCategory = null;
    _selectedTheme = null;
    notifyListeners();
  }

  void clearQuestionCache([Iterable<int>? themeIds]) {
    if (themeIds == null) {
      _questionsByTheme.clear();
      _questionRequests.clear();
      return;
    }

    for (final themeId in themeIds) {
      _questionsByTheme.remove(themeId);
      _questionRequests.remove(themeId);
    }
  }

  /// Load catalog statistics
  Future<void> loadStatistics() async {
    _isStatsLoading = true;
    _statsError = null;
    notifyListeners();

    try {
      final stats = await _catalogService.getStatistics();
      CatalogStats resolvedStats = stats;

      try {
        final allThemes = await _catalogService.getAllThemes();
        final totalThemesAll = allThemes.length;
        final totalQuestionsAll = allThemes.fold<int>(
          0,
          (sum, theme) => sum + theme.questionsCount,
        );
        final totalCategoriesAll = allThemes
            .map((theme) => theme.category)
            .whereType<String>()
            .toSet()
            .length;

        resolvedStats = CatalogStats(
          totalQuestions: stats.totalQuestions,
          totalThemes: stats.totalThemes,
          totalCategories: stats.totalCategories,
          totalQuestionsAll: totalQuestionsAll,
          totalThemesAll: totalThemesAll,
          totalCategoriesAll: totalCategoriesAll,
          totalQuestionsPurchased: stats.totalQuestionsPurchased,
          totalThemesPurchased: stats.totalThemesPurchased,
          totalCategoriesPurchased: stats.totalCategoriesPurchased,
        );
      } catch (_) {
        resolvedStats = stats;
      }

      _stats = resolvedStats;
      _statsError = null;
    } catch (e) {
      _statsError = e.toString();
      _stats = null;
    }

    _isStatsLoading = false;
    notifyListeners();
  }

  /// Load questions for a specific theme
  Future<List<Question>> loadQuestionsByTheme(int themeId) async {
    final cached = _questionsByTheme[themeId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final inFlight = _questionRequests[themeId];
    if (inFlight != null) {
      return inFlight;
    }

    final request = _catalogService
        .getQuestionsByTheme(themeId)
        .then((questions) {
          _questionsByTheme[themeId] = questions;
          _questionRequests.remove(themeId);
          return questions;
        })
        .catchError((error) {
          _questionRequests.remove(themeId);
          throw error;
        });

    _questionRequests[themeId] = request;

    try {
      final questions = await request;
      return questions;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw Exception('Failed to load questions: $e');
    }
  }

  /// Load questions for multiple themes in a single batched request,
  /// reusing already-cached/in-flight results per theme. Used when
  /// launching a quiz across several themes, so selecting many themes
  /// fires one request instead of one per theme.
  ///
  /// A theme the backend excludes from the batch (e.g. no longer
  /// entitled) simply contributes no questions rather than failing the
  /// whole load.
  Future<List<Question>> loadQuestionsByThemes(List<int> themeIds) async {
    final uniqueIds = <int>{...themeIds}.toList();
    final result = <Question>[];
    final pending = <Future<void>>[];
    final missingIds = <int>[];

    for (final id in uniqueIds) {
      final cached = _questionsByTheme[id];
      if (cached != null && cached.isNotEmpty) {
        result.addAll(cached);
        continue;
      }
      final inFlight = _questionRequests[id];
      if (inFlight != null) {
        pending.add(inFlight.then(result.addAll));
        continue;
      }
      missingIds.add(id);
    }

    if (missingIds.isNotEmpty) {
      final request = _catalogService
          .getQuestionsByThemes(missingIds)
          .then((questions) {
            final byTheme = <int, List<Question>>{};
            for (final q in questions) {
              byTheme.putIfAbsent(q.theme, () => []).add(q);
            }
            for (final id in missingIds) {
              _questionsByTheme[id] = byTheme[id] ?? [];
              _questionRequests.remove(id);
            }
            return questions;
          })
          .catchError((error) {
            for (final id in missingIds) {
              _questionRequests.remove(id);
            }
            throw error;
          });

      for (final id in missingIds) {
        _questionRequests[id] = request.then((_) => _questionsByTheme[id] ?? <Question>[]);
      }
      pending.add(request.then(result.addAll));
    }

    try {
      await Future.wait(pending);
      return result;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw Exception('Failed to load questions: $e');
    }
  }

  DateTime? _lastOfflineSyncAt;
  // The backend throttles catalog endpoints to 30 requests/minute per user
  // in production (shared across categories/themes/questions, and with
  // whatever else the user is doing in the app at the same time). Keep
  // comfortably under that so a background sync never starves the user's
  // own foreground requests into a 429.
  static const Duration _offlineSyncMinInterval = Duration(minutes: 15);
  static const Duration _offlineSyncRequestSpacing = Duration(
    milliseconds: 2200,
  );

  /// Proactively downloads everything the player can access so it stays
  /// playable offline: full catalog metadata (categories + themes, incl.
  /// per-difficulty question counts, even for locked themes so offline
  /// browsing/filtering doesn't show stale/zeroed counts) and, for every
  /// theme [isEntitled] returns true for, its actual questions.
  ///
  /// Locked (non-entitled) paid themes only get their metadata cached —
  /// their questions are never downloaded, so they correctly stay
  /// unplayable offline.
  ///
  /// Best-effort and silent: meant to run in the background (app startup,
  /// reconnect). Requests are paced to stay under the backend's rate limit,
  /// and the whole sync backs off immediately if it hits a 429 rather than
  /// hammering the API with requests that will also fail. A cooldown
  /// prevents re-running this on every trigger (e.g. frequent reconnects).
  Future<void> syncOfflineContent({
    required bool Function(theme_model.Theme theme) isEntitled,
  }) async {
    if (_isSyncingOffline) return;
    final now = DateTime.now();
    if (_lastOfflineSyncAt != null &&
        now.difference(_lastOfflineSyncAt!) < _offlineSyncMinInterval) {
      return;
    }

    _isSyncingOffline = true;
    _lastOfflineSyncAt = now;

    try {
      final categories = await _catalogService.getCategories();
      for (final category in categories) {
        List<theme_model.Theme> themes;
        try {
          await Future.delayed(_offlineSyncRequestSpacing);
          themes = await _catalogService.getThemesByCategory(category.id);
        } on ApiException catch (e) {
          if (e.isRateLimited) return;
          continue;
        } catch (_) {
          continue;
        }

        for (final theme in themes.where((t) => t.isActive)) {
          if (!isEntitled(theme)) continue;
          try {
            await Future.delayed(_offlineSyncRequestSpacing);
            await _catalogService.syncQuestionsIfNeeded(
              theme.id,
              theme.questionsCount,
            );
          } on ApiException catch (e) {
            if (e.isRateLimited) return;
          } catch (_) {
            // Best-effort: skip this theme, keep syncing the rest.
          }
        }
      }
    } catch (_) {
      // No connectivity or catalog unreachable: nothing to do, cached
      // content (if any) remains available offline as-is.
    } finally {
      _isSyncingOffline = false;
    }
  }

  /// Downloads a single theme's questions right away (e.g. immediately
  /// after the player unlocks it), without waiting for the next full
  /// background sync or its cooldown/pacing.
  Future<void> syncThemeQuestions(theme_model.Theme theme) async {
    try {
      await _catalogService.syncQuestionsIfNeeded(
        theme.id,
        theme.questionsCount,
      );
    } catch (_) {
      // Best-effort; the theme will be picked up by the next full sync.
    }
  }
}
