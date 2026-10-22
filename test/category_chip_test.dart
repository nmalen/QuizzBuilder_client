import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Colour actually rendered inside [chipRect], in its right padding where
/// neither the icon nor the label is drawn.
Future<Color> _renderedPixel(WidgetTester tester, Rect chipRect) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('screen')),
  );
  late Color result;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final x = (chipRect.right - 4).round();
    final y = chipRect.center.dy.round();
    final offset = (y * image.width + x) * 4;
    result = Color.fromARGB(
      255,
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  });
  return result;
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
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: const ValueKey('screen'),
            child: const SelectedThemesScreen(gameMode: 'solo'),
          ),
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

    // Selected: a green icon with at least 3:1 contrast on the chip fill.
    // Not selected: the neutral default colour, as before.
    final iconColor = selectedIcon.color!;
    expect(iconColor.g, greaterThan(iconColor.r));
    expect(iconColor.g, greaterThan(iconColor.b));
    expect(otherIcon.color, isNull);
    final chipFill = await _renderedPixel(
      tester,
      tester.getRect(find.byWidget(selectedChip)),
    );
    expect(_contrast(iconColor, chipFill), greaterThanOrEqualTo(3.0));

    // Selected chip is entirely green: a pastel green fill lighter than the
    // unselected grey fill, with a dark green bold label and border.
    final otherFill = await _renderedPixel(
      tester,
      tester.getRect(find.byWidget(otherChip)),
    );
    expect(chipFill.g, greaterThan(chipFill.r));
    expect(chipFill.g, greaterThan(chipFill.b));
    expect(chipFill.computeLuminance(), greaterThan(0.5));
    expect(chipFill.computeLuminance(), isNot(closeTo(otherFill.computeLuminance(), 0.01)));
    expect(otherFill.r, closeTo(otherFill.g, 0.01));
    expect(otherFill.g, closeTo(otherFill.b, 0.01));
    final labelColor = ((selectedChip.label as Text).style!).color!;
    expect(labelColor.g, greaterThan(labelColor.r));
    expect(labelColor.g, greaterThan(labelColor.b));
    expect(_contrast(labelColor, chipFill), greaterThanOrEqualTo(4.5));
    final borderColor = selectedChip.side!.color;
    expect(borderColor.g, greaterThan(borderColor.r));
    expect(borderColor.g, greaterThan(borderColor.b));

    // Chip widths do not depend on selection colours.
    expect(tester.getSize(find.byWidget(selectedChip)).width, closeTo(125.25, 0.1));
    expect(tester.getSize(find.byWidget(otherChip)).width, closeTo(110.4, 0.1));
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
