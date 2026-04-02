import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/credit_pack.dart';
import '../providers/auth_provider.dart';
import '../services/catalog_service.dart';
import '../services/credit_store_service.dart';
import 'premium_theme_unlock_screen.dart';

class CreditStoreScreen extends StatefulWidget {
  const CreditStoreScreen({super.key});

  @override
  State<CreditStoreScreen> createState() => _CreditStoreScreenState();
}

class _CreditStoreScreenState extends State<CreditStoreScreen> {
  static const Map<int, String> _fallbackPrices = {
    1: '0.99 EUR',
    5: '3.00 EUR',
    10: '5.00 EUR',
  };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  late final CreditStoreService _service;
  late final CatalogService _catalogService;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _loading = true;
  bool _storeAvailable = false;
  bool _purchaseInProgress = false;
  bool _isRestoring = false;

  int _creditBalance = 0;
  int _lockedPaidThemesCount = 0;
  String? _error;

  List<CreditPack> _packs = const [];
  List<ProductDetails> _products = const [];
  final Set<String> _processingPurchaseIds = <String>{};

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _service = CreditStoreService(authService: authProvider.authService);
    _catalogService = CatalogService(authService: authProvider.authService);
    _purchaseSub = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _purchaseInProgress = false;
          _error = _storeAvailable ? 'Purchase stream error: $error' : null;
        });
      },
    );
    _initializeStore();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final available = await _inAppPurchase.isAvailable();
      final results = await Future.wait<Object>([
        _service.getCreditPacks(),
        _service.getMyCredits(),
        _catalogService.getStatistics(),
        _catalogService.getAllThemes(),
      ]);

      final packs = results[0] as List<CreditPack>;
      final credits = results[1] as dynamic;
      final stats = results[2] as dynamic;
      final allThemes = results[3] as List<dynamic>;

      final filteredPacks =
          packs
              .where((pack) => const <int>{1, 5, 10}.contains(pack.credits))
              .toList(growable: false)
            ..sort((a, b) => a.credits.compareTo(b.credits));

      final totalPaidThemes = allThemes
          .where((theme) => theme.isActive && !theme.isFree)
          .length;
      final lockedPaidThemesCount =
          (totalPaidThemes - stats.totalThemesPurchased)
              .clamp(0, totalPaidThemes)
              .toInt();

      List<ProductDetails> products = const [];
      String? storeError;
      if (available && filteredPacks.isNotEmpty) {
        final ids = filteredPacks
            .map(_productIdForPack)
            .where((id) => id.isNotEmpty)
            .toSet();

        if (ids.isNotEmpty) {
          final response = await _inAppPurchase.queryProductDetails(ids);
          products = response.productDetails;
          if (response.error != null || response.notFoundIDs.isNotEmpty) {
            storeError = null;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _storeAvailable = available && products.isNotEmpty;
        _packs = filteredPacks;
        _products = products;
        _creditBalance = credits.balance;
        _lockedPaidThemesCount = lockedPaidThemesCount;
        _error = storeError;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _productIdForPack(CreditPack pack) {
    return Platform.isIOS ? pack.storeProductIdIos : pack.storeProductIdAndroid;
  }

  ProductDetails? _productForPack(CreditPack pack) {
    final productId = _productIdForPack(pack);
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  int get _remainingUnlockCapacity {
    return (_lockedPaidThemesCount - _creditBalance)
        .clamp(0, _lockedPaidThemesCount)
        .toInt();
  }

  Future<void> _openPremiumThemesToUnlock() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PremiumThemeUnlockScreen()));
    if (!mounted) return;
    await _initializeStore();
  }

  Future<void> _buyPack(CreditPack pack) async {
    if (_purchaseInProgress) return;

    final product = _productForPack(pack);
    if (product == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.storeProductUnavailable),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    setState(() {
      _purchaseInProgress = true;
      _error = null;
    });

    final started = await _inAppPurchase.buyConsumable(
      purchaseParam: purchaseParam,
    );
    if (!started && mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _purchaseInProgress = false;
        _error = l10n.storePurchaseFlowFailed;
      });
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _purchaseInProgress = true;
            });
          }
          break;
        case PurchaseStatus.error:
          if (mounted) {
            setState(() {
              _purchaseInProgress = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(purchase.error?.message ?? 'Purchase failed.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndGrantCredits(purchase);
          break;
        case PurchaseStatus.canceled:
          if (mounted) {
            setState(() {
              _purchaseInProgress = false;
            });
          }
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndGrantCredits(PurchaseDetails purchase) async {
    final purchaseKey = purchase.purchaseID ?? purchase.productID;
    if (_processingPurchaseIds.contains(purchaseKey)) return;
    _processingPurchaseIds.add(purchaseKey);

    final l10n = AppLocalizations.of(context)!;
    try {
      final matches = _packs
          .where((p) => _productIdForPack(p) == purchase.productID)
          .toList();
      if (matches.isEmpty) {
        throw Exception(l10n.storeUnknownProductId(purchase.productID));
      }
      final pack = matches.first;
      final packageInfo = await PackageInfo.fromPlatform();

      final storeType = Platform.isIOS ? 'apple' : 'google';
      final receipt = Platform.isIOS
          ? await _resolveAppleReceiptData(purchase)
          : jsonEncode(
              _buildGoogleReceiptPayload(
                purchase: purchase,
                packageName: packageInfo.packageName,
              ),
            );

      final result = await _service.verifyCreditPurchase(
        storeType: storeType,
        receipt: receipt,
        packId: pack.id,
      );

      if (!mounted) return;
      setState(() {
        _creditBalance =
            (result['new_balance'] as num?)?.toInt() ?? _creditBalance;
        _purchaseInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.storePurchaseSuccess(
              l10n.storeQuestionPackCount(
                (result['credits_granted'] as num?)?.toInt() ?? 0,
              ),
              l10n.storeQuestionPackCount(
                (result['new_balance'] as num?)?.toInt() ?? 0,
              ),
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchaseInProgress = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.storeVerificationFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _processingPurchaseIds.remove(purchaseKey);
    }
  }

  Future<String> _resolveAppleReceiptData(PurchaseDetails purchase) async {
    final fallbackReceipt = purchase.verificationData.serverVerificationData
        .trim();

    final addition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    final refreshed = await addition.refreshPurchaseVerificationData();
    final refreshedReceipt = refreshed?.serverVerificationData.trim() ?? '';

    // Some TestFlight flows can return a StoreKit2 token in purchase updates.
    // Backend verifyReceipt expects the app receipt, so prefer refreshed receipt data.
    if (refreshedReceipt.isNotEmpty) {
      return refreshedReceipt;
    }
    return fallbackReceipt;
  }

  Map<String, dynamic> _buildGoogleReceiptPayload({
    required PurchaseDetails purchase,
    required String packageName,
  }) {
    final localVerificationData = purchase.verificationData.localVerificationData;
    final serverVerificationData = purchase.verificationData.serverVerificationData;
    final localMap = _tryDecodeJsonMap(localVerificationData);

    // Android requires the purchase token for backend verification.
    final purchaseToken = _extractGooglePurchaseToken(
      localVerificationData: localVerificationData,
      serverVerificationData: serverVerificationData,
      localMap: localMap,
    );

    return {
      'packageName': packageName,
      'productId': purchase.productID,
      'purchaseToken': purchaseToken,
      if (purchase.purchaseID != null && purchase.purchaseID!.isNotEmpty)
        'orderId': purchase.purchaseID,
      if (localMap['purchaseTime'] != null) 'purchaseTime': localMap['purchaseTime'],
      if (localMap['purchaseState'] != null)
        'purchaseState': localMap['purchaseState'],
    };
  }

  String _extractGooglePurchaseToken({
    required String localVerificationData,
    required String serverVerificationData,
    required Map<String, dynamic> localMap,
  }) {
    final tokenFromLocal = _tokenFromMap(localMap);
    if (tokenFromLocal != null && tokenFromLocal.isNotEmpty) {
      return tokenFromLocal;
    }

    final serverMap = _tryDecodeJsonMap(serverVerificationData);
    final tokenFromServerMap = _tokenFromMap(serverMap);
    if (tokenFromServerMap != null && tokenFromServerMap.isNotEmpty) {
      return tokenFromServerMap;
    }

    // Fallback keeps compatibility with older plugin behavior.
    return serverVerificationData;
  }

  String? _tokenFromMap(Map<String, dynamic> data) {
    final token = data['purchaseToken'] ?? data['token'] ?? data['purchase_token'];
    if (token is String) {
      final trimmed = token.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  Map<String, dynamic> _tryDecodeJsonMap(String raw) {
    if (raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore invalid JSON and return empty map.
    }

    return <String, dynamic>{};
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;

    setState(() {
      _isRestoring = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context)!;
    try {
      await _inAppPurchase.restorePurchases();

      await Future<void>.delayed(const Duration(seconds: 2));
      final credits = await _service.getMyCredits();

      if (!mounted) return;
      setState(() {
        _creditBalance = credits.balance;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.storeRestoreSuccess(
              l10n.storeQuestionPackCount(credits.balance),
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.storeRestoreFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storePacksTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : _initializeStore,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.storeCurrentBalance(
                              l10n.storeQuestionPackCount(_creditBalance),
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _openPremiumThemesToUnlock,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.storeUnlockExplanation,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.storeLockedPaidThemesCount(
                                    _lockedPaidThemesCount,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (_isRestoring || _loading)
                            ? null
                            : _restorePurchases,
                        icon: _isRestoring
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.restore),
                        label: Text(
                          _isRestoring
                              ? l10n.storeRestoring
                              : l10n.storeRestorePurchases,
                        ),
                      ),
                    ),
                  ),
                  if (!_storeAvailable)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD59E)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.info_outline,
                              color: Color(0xFF9A5B00),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.storeUnavailableOnDevice,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF7A4B00),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null && _storeAvailable)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _packs.length,
                      itemBuilder: (context, index) {
                        final pack = _packs[index];
                        final product = _productForPack(pack);
                        final isPackTooLarge =
                            pack.credits > _remainingUnlockCapacity;
                        final canBuyThisPack =
                            !_purchaseInProgress &&
                            _storeAvailable &&
                            !isPackTooLarge;
                        final displayPrice =
                            product?.price ??
                            _fallbackPrices[pack.credits] ??
                            '${pack.price} ${pack.currency}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons.auto_awesome,
                                              color: colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              l10n.storeCreditCount(
                                                pack.credits,
                                              ),
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Chip(
                                      label: Text(displayPrice),
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      side: BorderSide(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.storeCreditPackDescription(pack.credits),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: canBuyThisPack
                                        ? () => _buyPack(pack)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: _purchaseInProgress
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.shopping_cart_checkout,
                                          ),
                                    label: Text(
                                      _purchaseInProgress
                                          ? l10n.storeProcessing
                                          : l10n.storeBuy,
                                    ),
                                  ),
                                ),
                                if (isPackTooLarge)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      l10n.storePackTooLargeForRemaining(
                                        l10n.storeQuestionPackCount(
                                          _remainingUnlockCapacity,
                                        ),
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
