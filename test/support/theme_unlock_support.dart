import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:QuizzBuilder/models/theme.dart' as theme_model;
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/quizz_builder_provider.dart';

import 'app_test_support.dart';
import 'duel_test_support.dart';

/// The player's side of the credit store, as a fake the test steers: the
/// balance, the owned themes, the catalog, and what the unlock endpoint says.
class FakeCreditStore {
  int balance = 3;
  final Set<int> owned = {};

  /// The premium themes of the catalog (`id` → active?).
  final Map<int, bool> catalog = {7: true, 8: true};

  /// Thrown by the unlock when set (a refusal of the server).
  Object? unlockError;

  /// A refresh of the credits and entitlements that fails (no network).
  bool refreshFails = false;

  /// The `origin` each unlock was called with (null: none).
  final List<String?> origins = [];

  int unlockCalls = 0;

  /// When set, `GET themes/` answers like the server: pages of this many
  /// themes in a `{count, next, previous, results}` envelope (`?page=N`, the
  /// `next` link deliberately on another scheme, as behind a proxy).
  int? pageSize;

  /// Every `GET themes/` the fake received.
  final List<Uri> catalogRequests = [];

  /// Premium themes added to the catalog by id, on top of [catalog].
  void addPremiumThemes(int count, {int firstId = 100}) {
    for (var i = 0; i < count; i++) {
      catalog[firstId + i] = true;
    }
  }

  List<Map<String, Object?>> _rows() => [
    for (final e in catalog.entries)
      {
        'id': e.key,
        'category': '1',
        'name_en': 'Premium ${e.key}',
        'name_fr': 'Premium ${e.key} fr',
        'description_en': e.key == 7 ? 'About seven.' : null,
        'description_fr': e.key == 7 ? 'À propos de sept.' : null,
        'is_free': false,
        'is_active': e.value,
        'questions_count': 40 + e.key,
        'source_url': null,
      },
  ];

  /// Catalog answer (`GET themes/`).
  http.Response catalogResponse([Uri? uri]) {
    final size = pageSize;
    if (size == null) return _flatCatalogResponse();
    final rows = _rows();
    final page = int.tryParse(uri?.queryParameters['page'] ?? '') ?? 1;
    final from = (page - 1) * size;
    if (from >= rows.length && page > 1) return jsonResponse(404, {'detail': 'Invalid page.'});
    final to = (from + size).clamp(0, rows.length);
    final hasNext = to < rows.length;
    return jsonResponse(200, {
      'count': rows.length,
      'next': hasNext ? 'http://booksnotify.com/themes/?page=${page + 1}' : null,
      'previous': page > 1 ? 'http://booksnotify.com/themes/?page=${page - 1}' : null,
      'results': rows.sublist(from, to),
    });
  }

  http.Response _flatCatalogResponse() => jsonResponse(200, _rows());

  MockClient get client => MockClient((request) async {
    if (request.method == 'GET' && request.url.path.endsWith('/themes/')) {
      catalogRequests.add(request.url);
      return catalogResponse(request.url);
    }
    return jsonResponse(404, null);
  });
}

/// Builder provider with no storage: the credits and entitlements come from
/// [FakeCreditStore], the unlock is recorded (the HTTP body of the unlock is
/// proved at the service level).
class FakeCreditBuilder extends QuizzBuilderProvider {
  FakeCreditBuilder(this.store) : super(authService: FakeAuthService());

  final FakeCreditStore store;
  bool _refreshFailed = false;

  @override
  int get creditBalance => store.balance;

  @override
  String? get themeAccessError => _refreshFailed ? 'offline' : null;

  @override
  bool isThemeEntitled(theme_model.Theme theme) =>
      theme.isFree || store.owned.contains(theme.id);

  @override
  Future<void> refreshThemeAccess() async {
    // Like the network, never answers within the frame that asked (the screen
    // asks from `initState`, where a notification would be a build-phase one).
    await Future<void>.value();
    _refreshFailed = store.refreshFails;
    notifyListeners();
  }

  @override
  Future<int> unlockThemeWithCredit(
    theme_model.Theme theme, {
    String? origin,
  }) async {
    store.unlockCalls++;
    store.origins.add(origin);
    final error = store.unlockError;
    if (error != null) throw error;
    store.owned.add(theme.id);
    store.balance--;
    notifyListeners();
    return store.balance;
  }
}

class FakeCreditCatalog extends FakeCatalogProvider {
  final List<int> synced = [];

  @override
  Future<void> syncThemeQuestions(theme_model.Theme theme) async {
    synced.add(theme.id);
  }
}

/// Providers of the credit store above [child] (a `duelApp` or any app).
Widget creditStoreShell({
  required FakeCreditBuilder builder,
  required FakeCreditCatalog catalog,
  required Widget child,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<QuizzBuilderProvider>.value(value: builder),
    ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
  ],
  child: child,
);

/// Decodes a recorded request body.
Map<String, dynamic> bodyOf(RecordedRequest r) =>
    jsonDecode(r.body) as Map<String, dynamic>;
