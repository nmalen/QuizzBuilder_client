import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/models/category.dart';
import 'package:QuizzBuilder/models/theme.dart' as theme_model;
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/quizz_builder_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/ui/selected_themes_screen.dart';

Category _category(int id, String name) => Category(
  id: id,
  nameEn: name,
  nameFr: name,
  isActive: true,
  themesCount: 0,
);

class _FakeCatalog extends CatalogProvider {
  _FakeCatalog(this.categoryList) : super(authService: AuthService());

  final List<Category> categoryList;

  @override
  List<Category> get categories => categoryList;

  @override
  List<theme_model.Theme> get themes => const [];

  @override
  Future<void> loadThemesByCategories(List<int> categoryIds) async {}

  @override
  Future<void> loadCategories() async {}
}

class _FakeBuilder extends QuizzBuilderProvider {
  _FakeBuilder() : super(authService: AuthService());

  @override
  Future<void> refreshThemeAccess() async {}

  @override
  void syncThemesWithSelectedCategories(List<theme_model.Theme> allThemes) {}
}

class _FakeConnectivity extends ChangeNotifier implements ConnectivityProvider {
  @override
  bool get isOnline => true;
}

void main() {
  testWidgets('selected category chip draws no checkmark and keeps its icon', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final selected = _category(1, 'Alpha');
    final other = _category(2, 'Beta');
    final builder = _FakeBuilder()..toggleCategory(selected);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CatalogProvider>.value(
            value: _FakeCatalog([selected, other]),
          ),
          ChangeNotifierProvider<QuizzBuilderProvider>.value(value: builder),
          ChangeNotifierProvider<ConnectivityProvider>.value(
            value: _FakeConnectivity(),
          ),
          ChangeNotifierProvider<AuthProvider>.value(
            value: AuthProvider(authService: AuthService()),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SelectedThemesScreen(gameMode: 'solo'),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
    expect(chips, hasLength(2));
    final selectedChip = chips[0];
    final otherChip = chips[1];
    expect(selectedChip.selected, isTrue);
    expect(otherChip.selected, isFalse);

    // No checkmark on the selected chip.
    expect(selectedChip.showCheckmark, isFalse);

    // The category icon is present and is the same glyph and size on both.
    final selectedIcon = selectedChip.avatar as Icon;
    final otherIcon = otherChip.avatar as Icon;
    expect(selectedIcon.icon, Icons.category);
    expect(otherIcon.icon, selectedIcon.icon);
    expect(otherIcon.size, selectedIcon.size);
    expect(
      find.descendant(
        of: find.byWidget(selectedChip),
        matching: find.byIcon(Icons.category),
      ),
      findsOneWidget,
    );

    // Selection stays signalled by tint, border and bold label.
    expect(selectedChip.selectedColor, isNotNull);
    expect(selectedChip.side, isNotNull);
    expect(otherChip.side, isNull);
    final selectedLabel = selectedChip.label as Text;
    expect(selectedLabel.style?.fontWeight, FontWeight.bold);
    expect((otherChip.label as Text).style, isNull);
  });
}
