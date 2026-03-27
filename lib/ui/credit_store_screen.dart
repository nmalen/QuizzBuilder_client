import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/credit_pack.dart';
import '../providers/auth_provider.dart';
import '../services/credit_store_service.dart';

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
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _loading = true;
  bool _storeAvailable = false;
  bool _purchaseInProgress = false;
  bool _isRestoring = false;

  int _creditBalance = 0;
  String? _error;

  List<CreditPack> _packs = const [];
  List<ProductDetails> _products = const [];
  final Set<String> _processingPurchaseIds = <String>{};

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _service = CreditStoreService(authService: authProvider.authService);
    _purchaseSub = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _purchaseInProgress = false;
          _error = 'Purchase stream error: $error';
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
      final packs = await _service.getCreditPacks();
      final credits = await _service.getMyCredits();

      final filteredPacks = packs
          .where((pack) => const <int>{1, 5, 10}.contains(pack.credits))
          .toList(growable: false)
        ..sort((a, b) => a.credits.compareTo(b.credits));

      List<ProductDetails> products = const [];
      if (available && filteredPacks.isNotEmpty) {
        final ids = filteredPacks
            .map(_productIdForPack)
            .where((id) => id.isNotEmpty)
            .toSet();

        if (ids.isNotEmpty) {
          final response = await _inAppPurchase.queryProductDetails(ids);
          products = response.productDetails;
          if (response.error != null) {
            _error = response.error!.message;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _storeAvailable = available;
        _packs = filteredPacks;
        _products = products;
        _creditBalance = credits.balance;
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

    final started = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
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
      final matches = _packs.where((p) => _productIdForPack(p) == purchase.productID).toList();
      if (matches.isEmpty) {
        throw Exception(l10n.storeUnknownProductId(purchase.productID));
      }
      final pack = matches.first;
      final packageInfo = await PackageInfo.fromPlatform();

      final storeType = Platform.isIOS ? 'apple' : 'google';
      final receipt = Platform.isIOS
          ? purchase.verificationData.serverVerificationData
          : jsonEncode({
              'packageName': packageInfo.packageName,
              'productId': purchase.productID,
              'purchaseToken': purchase.verificationData.serverVerificationData,
            });

      final result = await _service.verifyCreditPurchase(
        storeType: storeType,
        receipt: receipt,
        packId: pack.id,
      );

      if (!mounted) return;
      setState(() {
        _creditBalance = (result['new_balance'] as num?)?.toInt() ?? _creditBalance;
        _purchaseInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.storePurchaseSuccess(
              l10n.storeQuestionPackCount((result['credits_granted'] as num?)?.toInt() ?? 0),
              l10n.storeQuestionPackCount((result['new_balance'] as num?)?.toInt() ?? 0),
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
          content: Text(l10n.storeRestoreSuccess(l10n.storeQuestionPackCount(credits.balance))),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        l10n.storeCurrentBalance(l10n.storeQuestionPackCount(_creditBalance)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_isRestoring || _loading) ? null : _restorePurchases,
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore),
                      label: Text(_isRestoring ? l10n.storeRestoring : l10n.storeRestorePurchases),
                    ),
                  ),
                ),
                if (!_storeAvailable)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      l10n.storeUnavailableOnDevice,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      final displayPrice = product?.price ?? _fallbackPrices[pack.credits] ?? '${pack.price} ${pack.currency}';
                      final productId = _productIdForPack(pack);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.storeQuestionPackCount(pack.credits),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Chip(label: Text(displayPrice)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Product ID: $productId',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: (_purchaseInProgress || !_storeAvailable)
                                      ? null
                                      : () => _buyPack(pack),
                                  icon: _purchaseInProgress
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.shopping_cart_checkout),
                                  label: Text(_purchaseInProgress ? l10n.storeProcessing : l10n.storeBuy),
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
    );
  }
}
