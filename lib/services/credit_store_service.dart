import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/credit_pack.dart';
import '../models/user_credits.dart';
import 'auth_service.dart';

class CreditStoreService {
  final AuthService authService;
  final String baseUrl = ApiConfig.baseUrl;

  CreditStoreService({required this.authService});

  Future<http.Response> _authorizedGet(String url) async {
    final headers = await authService.getAuthHeaders();
    http.Response response = await http.get(Uri.parse(url), headers: headers).timeout(
      ApiConfig.connectionTimeout,
      onTimeout: () => throw Exception('Connection timeout'),
    );

    if (response.statusCode == 401) {
      final refreshed = await authService.refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await authService.getAuthHeaders();
        response = await http.get(Uri.parse(url), headers: retryHeaders).timeout(
          ApiConfig.connectionTimeout,
          onTimeout: () => throw Exception('Connection timeout'),
        );
      }
    }

    return response;
  }

  Future<http.Response> _authorizedPost(String url, Map<String, dynamic> body) async {
    final headers = await authService.getAuthHeaders();
    http.Response response = await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(
          ApiConfig.connectionTimeout,
          onTimeout: () => throw Exception('Connection timeout'),
        );

    if (response.statusCode == 401) {
      final refreshed = await authService.refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await authService.getAuthHeaders();
        response = await http
            .post(Uri.parse(url), headers: retryHeaders, body: jsonEncode(body))
            .timeout(
              ApiConfig.connectionTimeout,
              onTimeout: () => throw Exception('Connection timeout'),
            );
      }
    }

    return response;
  }

  Future<List<CreditPack>> getCreditPacks() async {
    final response = await _authorizedGet('$baseUrl${ApiConfig.creditPacksEndpoint}');
    if (response.statusCode != 200) {
      throw Exception('Failed to load credit packs: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => CreditPack.fromJson(item as Map<String, dynamic>))
        .where((pack) => pack.isActive)
        .toList(growable: false);
  }

  Future<UserCredits> getMyCredits() async {
    final response = await _authorizedGet('$baseUrl${ApiConfig.userCreditsMeEndpoint}');
    if (response.statusCode != 200) {
      throw Exception('Failed to load user credits: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserCredits.fromJson(data);
  }

  Future<Map<String, dynamic>> verifyCreditPurchase({
    required String storeType,
    required String receipt,
    required int packId,
  }) async {
    final response = await _authorizedPost(
      '$baseUrl${ApiConfig.creditPurchasesVerifyEndpoint}',
      {
        'store_type': storeType,
        'receipt': receipt,
        'pack_id': packId,
      },
    );

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error']?.toString() ?? 'Purchase verification failed';
    throw Exception(error);
  }

  Future<Map<String, dynamic>> restoreCreditPurchases({
    required String storeType,
    String? receiptData,
    List<Map<String, dynamic>>? purchasesData,
  }) async {
    final payload = <String, dynamic>{'store_type': storeType};
    if (receiptData != null && receiptData.isNotEmpty) {
      payload['receipt_data'] = receiptData;
    }
    if (purchasesData != null && purchasesData.isNotEmpty) {
      payload['purchases_data'] = purchasesData;
    }

    final response = await _authorizedPost(
      '$baseUrl${ApiConfig.creditPurchasesRestoreEndpoint}',
      payload,
    );

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error']?.toString() ?? 'Restore failed';
    throw Exception(error);
  }
}
